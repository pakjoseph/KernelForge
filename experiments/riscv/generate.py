#!/usr/bin/env python3
"""Generate LLVM 23.1.6 RV64V conversion IR, remarks, assembly, and checks."""

from __future__ import annotations

import json
import os
import pathlib
import platform
import re
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[2]
LLVM_PREFIX = pathlib.Path(
    os.environ.get("LLVM_PREFIX", "/opt/homebrew/opt/llvm")
).resolve()
TARGET = "riscv64-unknown-elf"
MARCH = "rv64gcv"
MABI = "lp64d"
EXPECTED_LLVM = "23.1.6"
OUTPUT = ROOT / "artifacts/m3b/llvm-23.1.6-rv64gcv-lp64d"
INPUTS = {
    "manual": ROOT / "experiments/riscv/manual_sat_i8.c",
    "intrinsic": ROOT / "experiments/riscv/intrinsic_sat_i8.ll",
}
TOOLS = {
    "llvm-config": LLVM_PREFIX / "bin/llvm-config",
    "clang": LLVM_PREFIX / "bin/clang",
    "opt": LLVM_PREFIX / "bin/opt",
    "llvm-as": LLVM_PREFIX / "bin/llvm-as",
    "llvm-mc": LLVM_PREFIX / "bin/llvm-mc",
    "llvm-objdump": LLVM_PREFIX / "bin/llvm-objdump",
}
TARGET_FLAGS = [
    "-target",
    TARGET,
    f"-march={MARCH}",
    f"-mabi={MABI}",
    "-fno-fast-math",
]
SCALAR_FLAGS = ["-fno-vectorize", "-fno-slp-vectorize"]


def run(command: list[str], *, stdout_path: pathlib.Path | None = None) -> str:
    result = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(
            f"command failed ({result.returncode}): {' '.join(command)}\n"
            f"{result.stdout}{result.stderr}"
        )
    if stdout_path is not None:
        stdout_path.write_text(result.stdout)
    return result.stderr


def tool_version(path: pathlib.Path) -> str:
    result = subprocess.run(
        [str(path), "--version"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(f"cannot query tool version: {path}\n{result.stdout}")
    if not re.search(rf"(?<![0-9.]){re.escape(EXPECTED_LLVM)}(?![0-9.])", result.stdout):
        raise RuntimeError(f"{path} is not LLVM {EXPECTED_LLVM}:\n{result.stdout}")
    return result.stdout.splitlines()[0]


def loop_summary(assembly: str) -> dict[str, object]:
    lines = assembly.splitlines()
    header_index = next(
        (i for i, line in enumerate(lines) if "Inner Loop Header" in line), None
    )
    if header_index is None:
        raise RuntimeError("assembly has no LLVM inner-loop header annotation")

    label_index = header_index
    label_match = re.match(r"\s*([.A-Za-z0-9_$]+):", lines[label_index])
    while label_match is None and label_index > 0:
        label_index -= 1
        label_match = re.match(r"\s*([.A-Za-z0-9_$]+):", lines[label_index])
    if label_match is None:
        raise RuntimeError("cannot identify the inner-loop label")
    label = label_match.group(1)

    body: list[str] = []
    backedge = None
    vector_stores: list[str] = []
    for line in lines[label_index + 1 :]:
        code = line.split("#", 1)[0].strip()
        if not code or code.startswith(".") or code.endswith(":"):
            continue
        fields = code.replace(",", " ").split()
        mnemonic = fields[0]
        body.append(mnemonic)
        if mnemonic in {"vse8.v", "vse16.v", "vse32.v", "vse64.v"}:
            vector_stores.append(mnemonic)
        if mnemonic in {"bnez", "beqz", "bne", "beq", "bltu", "bgeu", "blt", "bge"}:
            if fields[-1] == label:
                backedge = code
                break
    if backedge is None or not vector_stores:
        raise RuntimeError("could not count a vector loop body and its output store")
    return {
        "loop_label": label,
        "static_instructions_including_backedge": len(body),
        "backedge": backedge,
        "vector_store_instructions": vector_stores,
        "outputs_per_iteration": "VL elements (one vector byte store)",
    }


def main() -> None:
    versions = {name: tool_version(path) for name, path in TOOLS.items()}
    for name, path in TOOLS.items():
        if not path.is_file():
            raise RuntimeError(f"required LLVM tool is missing: {path} ({name})")

    out_ir = OUTPUT / "ir"
    out_asm = OUTPUT / "assembly"
    out_remarks = OUTPUT / "remarks"
    out_disassembly = OUTPUT / "disassembly"
    for directory in (out_ir, out_asm, out_remarks, out_disassembly):
        directory.mkdir(parents=True, exist_ok=True)

    commands: dict[str, list[list[str]]] = {}
    static_loops: dict[str, dict[str, object]] = {}

    with tempfile.TemporaryDirectory(prefix="kernelforge-m3b-") as temp:
        temp_dir = pathlib.Path(temp)

        frontend_ir = out_ir / "manual.frontend.ll"
        frontend_command = [
            str(TOOLS["clang"]),
            *TARGET_FLAGS,
            "-O0",
            "-Xclang",
            "-disable-O0-optnone",
            "-S",
            "-emit-llvm",
            str(INPUTS["manual"]),
            "-o",
            str(frontend_ir),
        ]
        run(frontend_command)
        commands["manual_frontend_ir"] = [frontend_command]
        frontend_verify = [
            str(TOOLS["opt"]),
            "-passes=verify",
            "-disable-output",
            str(frontend_ir),
        ]
        run(frontend_verify)
        commands["manual_frontend_verify"] = [frontend_verify]

        intrinsic_bc = temp_dir / "intrinsic.bc"
        llvm_as_command = [str(TOOLS["llvm-as"]), str(INPUTS["intrinsic"]), "-o", str(intrinsic_bc)]
        run(llvm_as_command)
        commands["verify_intrinsic_input"] = [llvm_as_command]

        for level in ("O2", "O3"):
            for variant, source in INPUTS.items():
                stem = f"{variant}.{level}"
                optimized_ir = out_ir / f"{stem}.ll"
                assembly = out_asm / f"{stem}.s"
                remarks = out_remarks / f"{stem}.txt"
                disassembly = out_disassembly / f"{stem}.txt"

                ir_command = [
                    str(TOOLS["clang"]),
                    *TARGET_FLAGS,
                    f"-{level}",
                    "-Rpass=loop-vectorize",
                    "-S",
                    "-emit-llvm",
                    str(source),
                    "-o",
                    str(optimized_ir),
                ]
                remark_text = run(ir_command)
                remarks.write_text(remark_text)
                commands[f"{stem}_optimized_ir"] = [ir_command]

                verify_command = [
                    str(TOOLS["opt"]),
                    "-passes=verify",
                    "-disable-output",
                    str(optimized_ir),
                ]
                run(verify_command)
                commands[f"{stem}_verify_ir"] = [verify_command]

                asm_command = [
                    str(TOOLS["clang"]),
                    *TARGET_FLAGS,
                    f"-{level}",
                    "-S",
                    str(source),
                    "-o",
                    str(assembly),
                ]
                run(asm_command)
                commands[f"{stem}_assembly"] = [asm_command]

                object_file = temp_dir / f"{stem}.o"
                mc_command = [
                    str(TOOLS["llvm-mc"]),
                    f"--triple={TARGET}",
                    "-mattr=+m,+a,+f,+d,+c,+v",
                    "-filetype=obj",
                    "-o",
                    str(object_file),
                    str(assembly),
                ]
                run(mc_command)
                commands[f"{stem}_llvm_mc_assembly_check"] = [mc_command]

                objdump_command = [
                    str(TOOLS["llvm-objdump"]),
                    "-d",
                    str(object_file),
                ]
                run(objdump_command, stdout_path=disassembly)
                commands[f"{stem}_llvm_objdump"] = [objdump_command]
                summary = loop_summary(assembly.read_text())
                summary["vectorizer_remark"] = remarks.read_text().strip()
                summary["maximum_outputs_per_iteration_at_vlen128"] = 8
                static_loops[stem] = summary

                scalar_assembly = out_asm / f"{variant}.scalar.{level}.s"
                scalar_disassembly = out_disassembly / f"{variant}.scalar.{level}.txt"
                scalar_assembly_command = [
                    str(TOOLS["clang"]),
                    *TARGET_FLAGS,
                    f"-{level}",
                    *SCALAR_FLAGS,
                    "-S",
                    str(source),
                    "-o",
                    str(scalar_assembly),
                ]
                run(scalar_assembly_command)
                commands[f"{stem}_scalar_assembly"] = [scalar_assembly_command]

                scalar_object = temp_dir / f"{variant}.scalar.{level}.o"
                scalar_mc_command = [
                    str(TOOLS["llvm-mc"]),
                    f"--triple={TARGET}",
                    "-mattr=+m,+a,+f,+d,+c,+v",
                    "-filetype=obj",
                    "-o",
                    str(scalar_object),
                    str(scalar_assembly),
                ]
                run(scalar_mc_command)
                commands[f"{stem}_scalar_llvm_mc_assembly_check"] = [scalar_mc_command]

                scalar_objdump_command = [
                    str(TOOLS["llvm-objdump"]),
                    "-d",
                    str(scalar_object),
                ]
                run(scalar_objdump_command, stdout_path=scalar_disassembly)
                commands[f"{stem}_scalar_llvm_objdump"] = [scalar_objdump_command]

    metadata = {
        "project": "KernelForge M3b RV64V conversion validation",
        "llvm_version_required": EXPECTED_LLVM,
        "llvm_tools": versions,
        "target_triple_argument": TARGET,
        "normalized_ir_triple": "riscv64-unknown-unknown-elf",
        "march": MARCH,
        "mabi": MABI,
        "flags": TARGET_FLAGS,
        "scalar_codegen_flags": SCALAR_FLAGS,
        "fast_math": False,
        "host": platform.platform(),
        "compiler_vectorization_and_loop_body": static_loops,
        "counting_method": (
            "Count assembly mnemonics from the line annotated as the LLVM inner-loop "
            "header through the conditional branch back to that label; directives, "
            "labels, and comments are excluded. This is a static count per loop "
            "iteration, not a dynamic instruction count or performance estimate."
        ),
        "vector_length_model": (
            "LLVM reports vscale x 4 with interleave count 1. The loop uses AVL as "
            "the remaining element count and advances by VL; with the QEMU VLEN=128 "
            "configuration, VLMAX is 8 output bytes for e32,m2."
        ),
        "performance_measurements": "not measured",
        "commands": commands,
    }
    (OUTPUT / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"Generated and verified M3b artifacts in {OUTPUT.relative_to(ROOT)}")
    for stem, loop in static_loops.items():
        print(
            f"{stem}: {loop['static_instructions_including_backedge']} static loop-body "
            f"instructions; {loop['outputs_per_iteration']}"
        )


if __name__ == "__main__":
    main()
