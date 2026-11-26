#!/usr/bin/env python3
"""Build, validate, and time the LLVM 23.1.6 M3c AArch64 comparison."""

from __future__ import annotations

import csv
import datetime as dt
import hashlib
import json
import math
import os
import pathlib
import platform
import random
import re
import statistics
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[3]
EXPERIMENT = pathlib.Path(__file__).resolve().parent
LLVM_PREFIX = pathlib.Path(os.environ.get("LLVM_PREFIX", "/opt/homebrew/opt/llvm")).resolve()
TARGET = "arm64-apple-darwin25.6.0"
CPU = "apple-m1"
EXPECTED_LLVM = "23.1.6"
PAIRS_PER_SESSION = 20
PROCESS_SESSIONS = 2
BOOTSTRAP_REPLICATES = 10000
BOOTSTRAP_SEED = 20261126
OUTPUT = ROOT / "artifacts/m3c/llvm-23.1.6-apple-m1"
TARGET_FLAGS = [
    "-target",
    TARGET,
    "-mcpu=apple-m1",
    "-fno-fast-math",
]
TOOLS = {
    name: LLVM_PREFIX / "bin" / name
    for name in (
        "llvm-config",
        "clang",
        "clang++",
        "opt",
        "llvm-as",
        "llvm-objdump",
        "llvm-nm",
    )
}


def capture(command: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode:
        raise RuntimeError(
            f"command failed ({result.returncode}): {' '.join(command)}\n"
            f"{result.stdout}{result.stderr}"
        )
    return result


def tool_version(path: pathlib.Path) -> str:
    result = capture([str(path), "--version"])
    output = result.stdout + result.stderr
    if not re.search(rf"(?<![0-9.]){re.escape(EXPECTED_LLVM)}(?![0-9.])", output):
        raise RuntimeError(f"{path} is not LLVM {EXPECTED_LLVM}:\n{output}")
    first_line = output.splitlines()[0]
    version_line = next(
        line.strip()
        for line in output.splitlines()
        if re.search(rf"(?<![0-9.]){re.escape(EXPECTED_LLVM)}(?![0-9.])", line)
    )
    return first_line if EXPECTED_LLVM in first_line else f"{first_line} ({version_line})"


def run_recorded(
    command: list[str],
    commands: dict[str, list[list[str]]],
    label: str,
    *,
    stdout_path: pathlib.Path | None = None,
    stderr_path: pathlib.Path | None = None,
) -> subprocess.CompletedProcess[str]:
    commands.setdefault(label, []).append(command)
    result = capture(command)
    if stdout_path is not None:
        stdout_path.write_text(result.stdout)
    if stderr_path is not None:
        stderr_path.write_text(result.stderr)
    return result


def quantile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    if not ordered:
        raise ValueError("quantile requires at least one value")
    position = (len(ordered) - 1) * fraction
    low = math.floor(position)
    high = math.ceil(position)
    if low == high:
        return ordered[low]
    weight = position - low
    return ordered[low] * (1.0 - weight) + ordered[high] * weight


def distribution(values: list[float]) -> dict[str, float]:
    middle = statistics.median(values)
    q1 = quantile(values, 0.25)
    q3 = quantile(values, 0.75)
    deviations = [abs(value - middle) for value in values]
    return {
        "median": middle,
        "q1": q1,
        "q3": q3,
        "iqr": q3 - q1,
        "mad": statistics.median(deviations),
    }


def bootstrap_block_ci(
    rows_by_session: dict[int, list[dict[str, str]]],
) -> list[float]:
    rng = random.Random(BOOTSTRAP_SEED)
    session_rows = [
        sorted(rows_by_session[key], key=lambda row: int(row["pair"]))
        for key in sorted(rows_by_session)
    ]
    if len(session_rows) < 2 or any(len(rows) < 10 for rows in session_rows):
        return []

    bootstrap_medians: list[float] = []
    block_length = 2
    for _ in range(BOOTSTRAP_REPLICATES):
        replicate: list[float] = []
        for rows in session_rows:
            selected: list[dict[str, str]] = []
            while len(selected) < len(rows):
                start = rng.randrange(len(rows))
                for offset in range(block_length):
                    selected.append(rows[(start + offset) % len(rows)])
                    if len(selected) == len(rows):
                        break
            replicate.extend(
                float(row["manual_ns_per_call"])
                / float(row["intrinsic_ns_per_call"])
                for row in selected
            )
        bootstrap_medians.append(statistics.median(replicate))

    return [quantile(bootstrap_medians, 0.025), quantile(bootstrap_medians, 0.975)]


def loop_instruction_summary(assembly: str) -> list[dict[str, object]]:
    lines = assembly.splitlines()
    summaries: list[dict[str, object]] = []
    marker = re.compile(r"Inner Loop Header: Depth=1")
    label_pattern = re.compile(r"^\s*([.$A-Za-z_][.$A-Za-z_0-9]*):")
    branch_names = {"b", "cbz", "cbnz", "tbz", "tbnz"}

    for header_index, line in enumerate(lines):
        if not marker.search(line):
            continue
        label_index = header_index
        label_match = label_pattern.match(lines[label_index])
        while label_match is None and label_index > 0:
            label_index -= 1
            label_match = label_pattern.match(lines[label_index])
        if label_match is None:
            continue

        label = label_match.group(1)
        mnemonics: list[str] = []
        output_bytes = 0
        backedge = None
        for body_line in lines[header_index + 1 :]:
            code = body_line.split(";", 1)[0].strip()
            if not code or code.startswith(".") or code.endswith(":"):
                continue
            fields = code.replace(",", " ").split()
            mnemonic = fields[0]
            mnemonics.append(mnemonic)

            vector_regs = re.findall(r"\bq\d+\b", code)
            if mnemonic == "str" and vector_regs:
                output_bytes += 16
            elif mnemonic == "stp" and vector_regs:
                output_bytes += 16 * min(2, len(vector_regs))

            is_branch = mnemonic in branch_names or mnemonic.startswith("b.")
            if is_branch and fields[-1] == label:
                backedge = code
                break

        if backedge is not None:
            summaries.append(
                {
                    "label": label,
                    "static_instructions_including_backedge": len(mnemonics),
                    "vector_output_bytes_per_iteration": output_bytes,
                    "backedge": backedge,
                }
            )
    return summaries


def source_machine_metadata() -> dict[str, object]:
    result = capture(["system_profiler", "SPHardwareDataType"], check=False)
    details: dict[str, str] = {}
    for line in result.stdout.splitlines():
        match = re.match(
            r"\s*(Model Name|Model Identifier|Chip|Total Number of Cores|Memory):\s*(.*)",
            line,
        )
        if match:
            details[match.group(1)] = match.group(2).strip()
    return {
        "details": details,
        "system_profiler_exit_code": result.returncode,
        "source": "system_profiler SPHardwareDataType; only non-serial fields retained",
    }


def runtime_environment() -> dict[str, object]:
    power = capture(["pmset", "-g", "batt"], check=False)
    power_source = next(
        (line.strip() for line in power.stdout.splitlines() if "Now drawing from" in line),
        "unavailable",
    )
    thermal = capture(["pmset", "-g", "therm"], check=False)
    thermal_output = thermal.stdout + thermal.stderr
    thermal_available = thermal.returncode == 0 and "Error:" not in thermal_output
    return {
        "power_source": power_source,
        "thermal_telemetry_available": thermal_available,
        "thermal_telemetry_note": (
            "available" if thermal_available else "pmset -g therm did not expose thermal status"
        ),
    }


def inspect_ir(path: pathlib.Path) -> dict[str, int]:
    ir_text = path.read_text()
    return {
        "llvm_fptosi_sat_call_count": len(
            re.findall(r"\bcall\b[^\n]*@llvm\.fptosi\.sat", ir_text)
        ),
        "ordinary_fptosi_opcode_count": len(
            re.findall(r"(?m)^\s*%[-a-zA-Z$._0-9]+\s*=\s*fptosi\b", ir_text)
        ),
        "fcmp_instruction_count": len(re.findall(r"\bfcmp\b", ir_text)),
        "select_instruction_count": len(re.findall(r"\bselect\b", ir_text)),
    }


def main() -> None:
    for name, path in TOOLS.items():
        if not path.is_file():
            raise RuntimeError(f"required LLVM tool is missing: {path} ({name})")
    versions = {name: tool_version(path) for name, path in TOOLS.items()}
    if platform.system() != "Darwin" or platform.machine() != "arm64":
        raise RuntimeError("M3c timing must run on the recorded Apple Silicon host")
    environment_before = runtime_environment()

    output_dirs = {
        name: OUTPUT / name
        for name in (
            "ir",
            "assembly",
            "remarks",
            "linked",
            "correctness",
            "timings",
            "traces",
        )
    }
    for directory in output_dirs.values():
        directory.mkdir(parents=True, exist_ok=True)

    commands: dict[str, list[list[str]]] = {}
    static_loops: dict[str, list[dict[str, object]]] = {}
    ir_evidence: dict[str, dict[str, object]] = {}
    linked_evidence: dict[str, dict[str, object]] = {}
    raw_rows: list[dict[str, str]] = []
    correctness_results: dict[str, str] = {}

    manual_source = EXPERIMENT / "manual_kernel.cpp"
    intrinsic_source = EXPERIMENT / "intrinsic_kernel.ll"
    benchmark_source = EXPERIMENT / "benchmark.cpp"
    source_variants = {
        "manual": (manual_source, "clang++"),
        "intrinsic": (intrinsic_source, "clang"),
    }

    with tempfile.TemporaryDirectory(prefix="kernelforge-m3c-") as temp:
        temp_dir = pathlib.Path(temp)
        bitcode = temp_dir / "intrinsic.bc"
        run_recorded(
            [str(TOOLS["llvm-as"]), str(intrinsic_source), "-o", str(bitcode)],
            commands,
            "verify_intrinsic_input_llvm_as",
        )
        run_recorded(
            [str(TOOLS["opt"]), "-passes=verify", "-disable-output", str(intrinsic_source)],
            commands,
            "verify_intrinsic_input_opt",
        )

        frontend_ir = output_dirs["ir"] / "manual.frontend.ll"
        frontend_command = [
            str(TOOLS["clang++"]),
            *TARGET_FLAGS,
            "-std=c++17",
            "-O0",
            "-Xclang",
            "-disable-O0-optnone",
            "-S",
            "-emit-llvm",
            str(manual_source),
            "-o",
            str(frontend_ir),
        ]
        run_recorded(frontend_command, commands, "manual_frontend_ir")
        aggressive_ir = output_dirs["ir"] / "manual.aggressive-instcombine.ll"
        aggressive_command = [
            str(TOOLS["opt"]),
            "-passes=mem2reg,aggressive-instcombine",
            "-S",
            str(frontend_ir),
            "-o",
            str(aggressive_ir),
        ]
        run_recorded(aggressive_command, commands, "manual_aggressive_instcombine")
        run_recorded(
            [str(TOOLS["opt"]), "-passes=verify", "-disable-output", str(aggressive_ir)],
            commands,
            "verify_manual_aggressive_instcombine",
        )
        ir_evidence["manual.frontend"] = inspect_ir(frontend_ir)
        ir_evidence["manual.aggressive-instcombine"] = inspect_ir(aggressive_ir)

        for level in ("O2", "O3"):
            for variant, (source, compiler_name) in source_variants.items():
                stem = f"{variant}.{level}"
                compiler = TOOLS[compiler_name]
                optimized_ir = output_dirs["ir"] / f"{stem}.ll"
                remarks = output_dirs["remarks"] / f"{stem}.txt"
                ir_command = [
                    str(compiler),
                    *TARGET_FLAGS,
                    *(["-std=c++17"] if variant == "manual" else []),
                    f"-{level}",
                    "-Rpass=loop-vectorize",
                    "-S",
                    "-emit-llvm",
                    str(source),
                    "-o",
                    str(optimized_ir),
                ]
                result = run_recorded(ir_command, commands, f"{stem}_optimized_ir")
                remarks.write_text(result.stderr)
                run_recorded(
                    [str(TOOLS["opt"]), "-passes=verify", "-disable-output", str(optimized_ir)],
                    commands,
                    f"{stem}_verify_ir",
                )

                assembly = output_dirs["assembly"] / f"{stem}.s"
                assembly_command = [
                    str(compiler),
                    *TARGET_FLAGS,
                    *(["-std=c++17"] if variant == "manual" else []),
                    f"-{level}",
                    "-S",
                    str(source),
                    "-o",
                    str(assembly),
                ]
                run_recorded(assembly_command, commands, f"{stem}_assembly")
                static_loops[stem] = loop_instruction_summary(assembly.read_text())

                ir_evidence[stem] = inspect_ir(optimized_ir)

        executables: dict[str, pathlib.Path] = {}
        for level in ("O2", "O3"):
            trace_ir = output_dirs["ir"] / f"manual.default-{level}.ll"
            trace = output_dirs["traces"] / f"manual.default-{level}.txt"
            trace_command = [
                str(TOOLS["opt"]),
                f"-passes=default<{level}>",
                "-debug-pass-manager",
                "-S",
                str(frontend_ir),
                "-o",
                str(trace_ir),
            ]
            trace_result = run_recorded(
                trace_command,
                commands,
                f"manual_default_{level}_pass_trace",
            )
            trace.write_text(trace_result.stderr)
            run_recorded(
                [str(TOOLS["opt"]), "-passes=verify", "-disable-output", str(trace_ir)],
                commands,
                f"manual_default_{level}_verify",
            )
            ir_evidence[f"manual.default-{level}"] = inspect_ir(trace_ir)

        for level in ("O2", "O3"):
            object_paths: dict[str, pathlib.Path] = {}
            for variant, (source, compiler_name) in source_variants.items():
                compiler = TOOLS[compiler_name]
                obj = temp_dir / f"{variant}.{level}.o"
                command = [
                    str(compiler),
                    *TARGET_FLAGS,
                *(["-std=c++17"] if variant == "manual" else []),
                    f"-{level}",
                    "-c",
                    str(source),
                    "-o",
                    str(obj),
                ]
                run_recorded(command, commands, f"{variant}.{level}_object")
                object_paths[variant] = obj

            driver_object = temp_dir / f"benchmark.{level}.o"
            driver_compile = [
                str(TOOLS["clang++"]),
                *TARGET_FLAGS,
                "-std=c++17",
                f"-{level}",
                "-c",
                str(benchmark_source),
                "-o",
                str(driver_object),
            ]
            run_recorded(driver_compile, commands, f"benchmark_driver.{level}_object")

            executable = temp_dir / f"benchmark.{level}"
            executables[level] = executable
            link_command = [
                str(TOOLS["clang++"]),
                *TARGET_FLAGS,
                f"-{level}",
                str(driver_object),
                str(object_paths["manual"]),
                str(object_paths["intrinsic"]),
                "-o",
                str(executable),
            ]
            run_recorded(link_command, commands, f"benchmark.{level}_link_no_lto")

            symbols = run_recorded(
                [str(TOOLS["llvm-nm"]), "-g", str(executable)],
                commands,
                f"benchmark.{level}_linked_symbols",
            )
            required_symbols = (
                "_kernelforge_sat_i8_manual",
                "_kernelforge_sat_i8_intrinsic",
            )
            missing = [symbol for symbol in required_symbols if symbol not in symbols.stdout]
            if missing:
                raise RuntimeError(f"linked benchmark is missing kernel symbols: {missing}")

            disassembly_texts: dict[str, str] = {}
            for symbol in required_symbols:
                disassembly = output_dirs["linked"] / f"{level}.{symbol[1:]}.txt"
                disassembly_result = run_recorded(
                    [
                        str(TOOLS["llvm-objdump"]),
                        "--macho",
                        "--disassemble",
                        "--dis-symname",
                        symbol,
                        str(executable),
                    ],
                    commands,
                    f"benchmark.{level}.disassemble.{symbol}",
                    stdout_path=disassembly,
                )
                if symbol not in disassembly_result.stdout or "\n" not in disassembly_result.stdout:
                    raise RuntimeError(f"linked kernel disassembly is empty: {symbol}")
                disassembly_texts[symbol] = disassembly_result.stdout

            if disassembly_texts[required_symbols[0]] == disassembly_texts[required_symbols[1]]:
                raise RuntimeError("linked manual and intrinsic kernel disassemblies are identical")
            linked_evidence[level] = {
                "symbols_present": list(required_symbols),
                "manual_disassembly_sha256": hashlib.sha256(
                    disassembly_texts[required_symbols[0]].encode()
                ).hexdigest(),
                "intrinsic_disassembly_sha256": hashlib.sha256(
                    disassembly_texts[required_symbols[1]].encode()
                ).hexdigest(),
                "distinct_disassembly_text": True,
                "lto_enabled": False,
            }

        for level in ("O2", "O3"):
            executable = executables[level]
            correctness_command = [str(executable), "--correctness-only"]
            correctness_result = capture(correctness_command)
            commands[f"benchmark.{level}_correctness"] = [correctness_command]
            correctness_results[level] = correctness_result.stdout + correctness_result.stderr
            (output_dirs["correctness"] / f"{level}.txt").write_text(
                correctness_results[level]
            )

        for session in range(PROCESS_SESSIONS):
            level_order = ("O2", "O3") if session == 0 else ("O3", "O2")
            for level in level_order:
                executable = executables[level]
                session_command = [
                    str(executable),
                    "--benchmark",
                    str(PAIRS_PER_SESSION),
                    str(session),
                ]
                session_result = capture(session_command)
                commands.setdefault(f"benchmark.{level}.timing_session", []).append(
                    session_command
                )
                (output_dirs["timings"] / f"{level}.session-{session}.stderr.txt").write_text(
                    session_result.stderr
                )
                reader = csv.DictReader(session_result.stdout.splitlines())
                if not reader.fieldnames or "manual_ns_per_call" not in reader.fieldnames:
                    raise RuntimeError(f"benchmark emitted invalid CSV for {level}, session {session}")
                for raw in reader:
                    raw["optimization"] = level
                    raw["process_session"] = str(session)
                    raw_rows.append(raw)

        raw_path = output_dirs["timings"] / "raw.csv"
        raw_fields = [
            "optimization",
            "process_session",
            "size",
            "repetitions",
            "pair",
            "first_variant",
            "manual_total_ns",
            "intrinsic_total_ns",
            "manual_ns_per_call",
            "intrinsic_ns_per_call",
        ]
        with raw_path.open("w", newline="") as raw_file:
            writer = csv.DictWriter(raw_file, fieldnames=raw_fields)
            writer.writeheader()
            writer.writerows({key: row[key] for key in raw_fields} for row in raw_rows)

    summary: dict[str, object] = {
        "speedup_definition": "manual ns/call divided by intrinsic ns/call; >1 favors intrinsic",
        "paired_samples_per_optimization_and_size": PAIRS_PER_SESSION * PROCESS_SESSIONS,
        "confidence_interval": {
            "method": "stratified percentile block bootstrap of paired ratios",
            "block_length_pairs": 2,
            "process_sessions": PROCESS_SESSIONS,
            "replicates": BOOTSTRAP_REPLICATES,
            "seed": BOOTSTRAP_SEED,
            "level": 0.95,
        },
        "results": {},
    }
    result_groups: dict[str, object] = summary["results"]  # type: ignore[assignment]
    for level in ("O2", "O3"):
        result_groups[level] = {}
        level_summary: dict[str, object] = result_groups[level]  # type: ignore[assignment]
        for n in (4096, 8388608):
            rows = [
                row
                for row in raw_rows
                if row["optimization"] == level and int(row["size"]) == n
            ]
            manual_times = [float(row["manual_ns_per_call"]) for row in rows]
            intrinsic_times = [float(row["intrinsic_ns_per_call"]) for row in rows]
            paired = [manual / intrinsic for manual, intrinsic in zip(manual_times, intrinsic_times)]
            by_session: dict[int, list[dict[str, str]]] = {}
            for row in rows:
                by_session.setdefault(int(row["process_session"]), []).append(row)
            if len(rows) != PAIRS_PER_SESSION * PROCESS_SESSIONS:
                raise RuntimeError(f"expected 40 paired samples for {level}, n={n}; got {len(rows)}")
            level_summary[str(n)] = {
                "input_bytes": n * 4,
                "two_output_arrays_bytes": n * 2,
                "total_working_set_bytes": n * 6,
                "manual_ns_per_call": distribution(manual_times),
                "intrinsic_ns_per_call": distribution(intrinsic_times),
                "paired_intrinsic_speedup": {
                    **distribution(paired),
                    "bootstrap_95_percent_ci": bootstrap_block_ci(by_session),
                },
                "samples": len(rows),
                "excluded_samples": 0,
            }

    (output_dirs["timings"] / "summary.json").write_text(
        json.dumps(summary, indent=2) + "\n"
    )

    metadata = {
        "project": "KernelForge M3c controlled AArch64 conversion comparison",
        "recorded_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "harness_commit": capture(["git", "rev-parse", "HEAD"]).stdout.strip(),
        "llvm_version_required": EXPECTED_LLVM,
        "llvm_prefix": str(LLVM_PREFIX),
        "llvm_tools": versions,
        "target": TARGET,
        "cpu_tuning": CPU,
        "flags": TARGET_FLAGS,
        "optimization_levels": ["O2", "O3"],
        "fast_math": False,
        "lto": False,
        "noinline_kernels": True,
        "machine": source_machine_metadata(),
        "platform": {
            "platform": platform.platform(),
            "machine": platform.machine(),
            "macos_version": platform.mac_ver()[0],
            "uname": capture(["uname", "-a"]).stdout.strip(),
        },
        "runtime_environment": {
            "before_measurement": environment_before,
            "after_measurement": runtime_environment(),
        },
        "m2_recorded_machine": json.loads(
            (ROOT / "artifacts/m2/llvm-23.1.6-apple-m1/metadata.json").read_text()
        )["machine"],
        "kernel_sources": {
            "manual": str(manual_source.relative_to(ROOT)),
            "explicit_sat_ir": str(intrinsic_source.relative_to(ROOT)),
            "shared_harness": str(benchmark_source.relative_to(ROOT)),
            "reference": "double-precision std::trunc with cast only after int8 range check",
        },
        "correctness": {
            "results": correctness_results,
            "edge_values": 39,
            "sizes": [0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256, 257, 4095, 4096, 4097, 8388608],
        },
        "benchmark_method": {
            "sizes": [4096, 8388608],
            "elements": {
                "4096": "small repeated-array case; 16 KiB input + 8 KiB for both outputs = 24 KiB",
                "8388608": "large case above M3a's 4097 maximum; 32 MiB input + 16 MiB for both outputs = 48 MiB",
            },
            "input": "deterministic thousandth-step values over [-160,160] with one edge-corpus value every 257 elements",
            "warmup_pairs_per_process_and_size": 6,
            "calibration_pairs_per_process_and_size": 5,
            "target_sample_duration_ns": 20000000,
            "repetitions": "ceil(target duration / slower median calibrated single-call time); same count for both variants",
            "paired_samples_per_optimization_and_size": PAIRS_PER_SESSION * PROCESS_SESSIONS,
            "order": "manual-first/intrinsic-first alternate within each process; second process starts with reversed order",
            "timed_region": "kernel calls only; input generation, allocation, checks, clock-independent setup, checksums, and formatting are outside timing",
            "clock": "std::chrono::steady_clock; elapsed batch nanoseconds divided by repetitions",
            "output_consumption": "compare final output arrays and print FNV-1a checksums after timed loops",
            "process_affinity": "not pinned; managed by macOS scheduler",
            "sample_exclusions": "none",
            "ci_note": "bootstrap CI is descriptive and may understate uncertainty from serial thermal or scheduler correlation",
        },
        "llvm_ir_evidence": ir_evidence,
        "static_loop_instruction_counts": static_loops,
        "linked_kernel_validation": linked_evidence,
        "summary": summary,
        "commands": commands,
    }
    (OUTPUT / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"M3c build, correctness, and timing results written to {OUTPUT.relative_to(ROOT)}")
    print(f"Raw paired observations: {len(raw_rows)}")
    for level, results in result_groups.items():
        for n, details in results.items():
            speed = details["paired_intrinsic_speedup"]  # type: ignore[index]
            print(
                f"{level} n={n}: intrinsic median paired speedup="
                f"{speed['median']:.4f}, 95% CI={speed['bootstrap_95_percent_ci']}"
            )


if __name__ == "__main__":
    main()
