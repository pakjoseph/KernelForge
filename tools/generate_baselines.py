#!/usr/bin/env python3
"""Generate reproducible LLVM 23.1.6 report IR, remarks, IR, and AArch64 asm."""

import argparse
import json
import pathlib
import platform
import re
import subprocess
import sys


LLVM_VERSION = "23.1.6"
KERNELS = ("saxpy", "dot", "stencil")


def workload_sizes(root):
    sizes = []
    for line in (root / "tests" / "workload_sizes.inc").read_text().splitlines():
        line = line.strip()
        if line.startswith("KERNELFORGE_TEST_SIZE(") and line.endswith(")"):
            sizes.append(int(line[len("KERNELFORGE_TEST_SIZE(") : -1]))
    if not sizes:
        raise RuntimeError("no correctness workload sizes found")
    return sizes


def run(command, *, cwd=None):
    result = subprocess.run(
        [str(part) for part in command],
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        rendered = " ".join(str(part) for part in command)
        raise RuntimeError(
            f"command failed ({result.returncode}): {rendered}\n"
            f"{result.stdout}{result.stderr}"
        )
    return result


def check_llvm_version(text, tool):
    if not re.search(r"(?<![0-9.])23\.1\.6(?![0-9.])", text):
        raise RuntimeError(f"{tool} is not LLVM {LLVM_VERSION}:\n{text}")


def machine_details():
    details = {
        "platform": platform.platform(),
        "machine": platform.machine(),
        "macos_version": platform.mac_ver()[0] or None,
    }
    if sys.platform == "darwin":
        result = subprocess.run(
            ["system_profiler", "SPHardwareDataType"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=30,
            check=False,
        )
        if result.returncode == 0:
            wanted = ("Model Name", "Model Identifier", "Chip")
            for line in result.stdout.splitlines():
                for key in wanted:
                    if line.strip().startswith(key + ":"):
                        details[key.lower().replace(" ", "_")] = line.split(":", 1)[1].strip()
    return details


def verify_nonempty(path):
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError(f"expected non-empty generated artifact: {path}")


def normalize_module_id(path, module_id):
    lines = path.read_text().splitlines(keepends=True)
    if lines and lines[0].startswith("; ModuleID = "):
        lines[0] = f"; ModuleID = '{module_id}'\n"
        path.write_text("".join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--clang", required=True, type=pathlib.Path)
    parser.add_argument("--opt", required=True, type=pathlib.Path)
    parser.add_argument("--plugin", required=True, type=pathlib.Path)
    parser.add_argument("--cpu", default="apple-m1")
    parser.add_argument("--target", help="defaults to clang's target triple")
    parser.add_argument("--output-dir", required=True, type=pathlib.Path)
    args = parser.parse_args()

    clang = args.clang.resolve()
    opt = args.opt.resolve()
    plugin = args.plugin.resolve()
    output_dir = args.output_dir.resolve()
    if not clang.is_file() or not opt.is_file() or not plugin.is_file():
        raise RuntimeError("clang, opt, and the KernelForge plugin must exist")

    clang_version = run([clang, "--version"])
    opt_version = run([opt, "--version"])
    check_llvm_version(clang_version.stdout, "clang++")
    check_llvm_version(opt_version.stdout, "opt")

    target = args.target or run([clang, "--print-target-triple"]).stdout.strip()
    if not target.startswith(("arm64", "aarch64")):
        raise RuntimeError(f"baseline assembly must target AArch64; got {target}")

    source_root = pathlib.Path(__file__).resolve().parents[1]
    sizes = workload_sizes(source_root)
    kernel_dir = source_root / "kernels"
    ir_dir = output_dir / "ir"
    report_dir = output_dir / "reports"
    remarks_dir = output_dir / "remarks"
    assembly_dir = output_dir / "assembly"
    for directory in (ir_dir, report_dir, remarks_dir, assembly_dir):
        directory.mkdir(parents=True, exist_ok=True)

    common_flags = [
        "-std=c++17",
        "-target",
        target,
        "-mcpu=" + args.cpu,
        "-fno-fast-math",
        "-I",
        "kernels",
    ]
    command_log = {}
    generated = []

    for kernel in KERNELS:
        source = kernel_dir / f"{kernel}.cpp"
        source_argument = pathlib.Path("kernels") / f"{kernel}.cpp"
        raw_ir = ir_dir / f"{kernel}.frontend.ll"
        report_input = ir_dir / f"{kernel}.report-input.ll"
        prepared = [
            opt,
            "-passes=mem2reg,loop-simplify",
            "-verify-each",
            "-S",
            str(raw_ir),
            "-o",
            str(report_input),
        ]
        frontend_ir = [
            clang,
            *common_flags,
            "-O0",
            "-Xclang",
            "-disable-O0-optnone",
            "-S",
            "-emit-llvm",
            str(source_argument),
            "-o",
            str(raw_ir),
        ]
        run(frontend_ir, cwd=source_root)
        run(prepared, cwd=source_root)
        normalize_module_id(report_input, f"kernelforge-{kernel}.report-input.ll")
        verify_nonempty(raw_ir)
        verify_nonempty(report_input)

        report_command = [
            opt,
            "-load-pass-plugin",
            plugin,
            "-passes=kernel-access-report",
            "-pass-remarks-analysis=kernel-access-report",
            "-verify-each",
            "-disable-output",
            str(report_input),
        ]
        report_result = run(report_command, cwd=source_root)
        report_text = report_result.stderr
        if f"function=kernelforge_{kernel}" not in report_text:
            raise RuntimeError(
                f"kernel-access-report emitted no report for {kernel}:\n{report_text}"
            )
        if " access#0 " not in report_text or "unsupported reason=" in report_text:
            raise RuntimeError(
                f"kernel-access-report did not analyze the expected accesses in {kernel}:\n"
                f"{report_text}"
            )
        report_path = report_dir / f"{kernel}.txt"
        report_path.write_text(report_text)
        verify_nonempty(report_path)

        command_log[kernel] = {
            "report_ir_frontend": [str(part) for part in frontend_ir],
            "prepare_report_ir": [str(part) for part in prepared],
            "kernel_access_report": [str(part) for part in report_command],
            "optimization_levels": {},
        }
        generated.extend(
            str(path.relative_to(output_dir))
            for path in (raw_ir, report_input, report_path)
        )

        for level in ("O2", "O3"):
            optimized_ir = ir_dir / f"{kernel}.{level}.ll"
            assembly = assembly_dir / f"{kernel}.{level}.s"
            remarks_path = remarks_dir / f"{kernel}.{level}.txt"
            optimization_flag = "-" + level
            optimized_ir_command = [
                clang,
                *common_flags,
                optimization_flag,
                "-S",
                "-emit-llvm",
                str(source_argument),
                "-o",
                str(optimized_ir),
            ]
            verify_ir_command = [
                opt,
                "-passes=verify",
                "-disable-output",
                str(optimized_ir),
            ]
            assembly_command = [
                clang,
                *common_flags,
                optimization_flag,
                "-Rpass=loop-vectorize",
                "-Rpass-missed=loop-vectorize",
                "-Rpass-analysis=loop-vectorize",
                "-S",
                str(source_argument),
                "-o",
                str(assembly),
            ]
            assembly_result = run(assembly_command, cwd=source_root)
            remarks_path.write_text(assembly_result.stderr)
            remark_tags = ("[-Rpass=", "[-Rpass-missed=", "[-Rpass-analysis=")
            if not any(tag in assembly_result.stderr for tag in remark_tags):
                raise RuntimeError(
                    f"no loop-vectorization remark was emitted for {kernel} {level}"
                )
            run(optimized_ir_command, cwd=source_root)
            normalize_module_id(optimized_ir, f"kernelforge-{kernel}.{level}.ll")
            run(verify_ir_command, cwd=source_root)
            for artifact in (optimized_ir, assembly, remarks_path):
                verify_nonempty(artifact)
                generated.append(str(artifact.relative_to(output_dir)))
            command_log[kernel]["optimization_levels"][level] = {
                "optimized_ir": [str(part) for part in optimized_ir_command],
                "verify_ir": [str(part) for part in verify_ir_command],
                "assembly_and_vectorization_remarks": [
                    str(part) for part in assembly_command
                ],
            }

    generated = sorted(set(generated))
    metadata = {
        "project": "KernelForge M2 baseline",
        "llvm_version_required": LLVM_VERSION,
        "tools": {
            "clang": str(clang),
            "clang_version": clang_version.stdout.splitlines()[0],
            "opt": str(opt),
            "opt_version": opt_version.stdout.splitlines()[0],
            "plugin": str(plugin),
        },
        "target": target,
        "cpu_tuning": args.cpu,
        "working_directory": str(source_root),
        "machine": machine_details(),
        "flags": {
            "common": common_flags,
            "report_ir_frontend": [
                "-O0",
                "-Xclang",
                "-disable-O0-optnone",
                "-S",
                "-emit-llvm",
            ],
            "report_ir_preparation": ["-passes=mem2reg,loop-simplify", "-verify-each"],
            "optimized_ir_and_assembly": ["-O2", "-O3", "-fno-fast-math"],
            "vectorization_remarks": [
                "-Rpass=loop-vectorize",
                "-Rpass-missed=loop-vectorize",
                "-Rpass-analysis=loop-vectorize",
            ],
            "fast_math": False,
        },
        "correctness_build_flags": {
            "kernels": ["-O2", "-O3", "-fno-fast-math", "-mcpu=apple-m1"],
            "scalar_reference": [
                "-O1",
                "-fno-vectorize",
                "-fno-slp-vectorize",
                "-ffp-contract=off",
                "-fno-fast-math",
                "-mcpu=apple-m1",
            ],
        },
        "correctness_workload_sizes": sizes,
        "deterministic_inputs": {
            "formula": "(int((uint32(i) * 37 + salt * 19) % 127) - 63) / 79.0f",
            "salts": {"saxpy_x": 3, "saxpy_y": 11, "stencil_input": 29},
            "saxpy_alpha": 0.73,
        },
        "correctness_tolerance": {
            "absolute": 1.0e-4,
            "relative": 2.0e-5,
            "formula": "abs(actual - expected) <= absolute + relative * abs(expected)",
        },
        "kernels": {
            "saxpy": "out[i] = alpha * x[i] + y[i]",
            "dot": "sequential floating-point sum of x[i] * y[i]",
            "stencil": "copy endpoints; interior is (in[i-1] + in[i] + in[i+1]) / 3",
        },
        "commands": command_log,
        "generated_files": generated,
        "performance_measurements": "none; M2 generator and CTest do not time kernels",
    }
    (output_dir / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    (output_dir / "README.md").write_text(
        "# KernelForge M2 compiler-output baseline\n\n"
        "This directory separates report input IR, optimized IR, optimization remarks, "
        "access reports, and AArch64 assembly. `metadata.json` records the selected "
        "tool versions, host/target, flags, workloads, tolerances, and commands.\n\n"
        "- `ir/*.report-input.ll` is Clang `-O0` frontend IR prepared with `mem2reg` "
        "and `loop-simplify` for `kernel-access-report`; `ir/*.frontend.ll` is the "
        "unprepared Clang frontend output. Nonsemantic IR ModuleID comments are "
        "normalized to keep artifacts independent of the output directory.\n"
        "- `reports/*.txt` contains M1 optimization-analysis remarks.\n"
        "- `ir/*.O2.ll` and `ir/*.O3.ll` are standard Clang optimized IR outputs.\n"
        "- `remarks/*.txt` contains vectorizer analysis, passed, and missed remarks "
        "for the matching optimization level.\n"
        "- `assembly/*.s` contains matching AArch64 assembly.\n\n"
        "These are compiler outputs, not correctness logs or performance results. "
        "No timing is collected here or in CTest. Reproduce from the project root "
        "with `cmake --build build --target m2-baselines`.\n"
    )
    print(f"Generated and verified {len(generated)} compiler artifacts in {output_dir}")
    print("No kernel timing was collected.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"baseline generation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
