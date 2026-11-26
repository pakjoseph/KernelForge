#!/usr/bin/env python3
"""Run the conversion correctness oracle on the already installed QEMU RVV CPU."""

from __future__ import annotations

import pathlib
import os
import re
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[2]
LLVM_PREFIX = pathlib.Path(
    os.environ.get("LLVM_PREFIX", "/opt/homebrew/opt/llvm")
)
CLANG = LLVM_PREFIX / "bin/clang"
GNU_LD = pathlib.Path("/opt/homebrew/bin/riscv64-unknown-elf-ld")
QEMU = pathlib.Path("/opt/homebrew/bin/qemu-system-riscv64")
TARGET_FLAGS = [
    "-target",
    "riscv64-unknown-elf",
    "-march=rv64gcv",
    "-mabi=lp64d",
    "-mcmodel=medany",
    "-fno-fast-math",
    "-ffreestanding",
    "-fno-stack-protector",
    "-fno-pic",
]


def run(command: list[str], *, timeout: int = 30) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
    )


def main() -> None:
    for tool in (CLANG, GNU_LD, QEMU):
        if not tool.is_file():
            raise SystemExit(f"required preinstalled tool is missing: {tool}")

    output = ROOT / "artifacts/m3b/llvm-23.1.6-rv64gcv-lp64d"
    output.mkdir(parents=True, exist_ok=True)
    clang_version = run([str(CLANG), "--version"])
    if clang_version.returncode or not re.search(r"(?<![0-9.])23\.1\.6(?![0-9.])", clang_version.stdout + clang_version.stderr):
        raise SystemExit("QEMU harness requires Clang 23.1.6")
    ld_version = run([str(GNU_LD), "--version"])
    qemu_version = run([str(QEMU), "--version"])
    report_lines = [
        "Functional validation only; QEMU emulation time is not performance data.",
        "CPU: rv64 with VLEN=128 and ELEN=64; QEMU virt finisher reports process status.",
        f"Clang: {clang_version.stdout.splitlines()[0]}",
        f"Linker: {ld_version.stdout.splitlines()[0]}",
        f"QEMU: {qemu_version.stdout.splitlines()[0]}",
    ]

    with tempfile.TemporaryDirectory(prefix="kernelforge-m3b-qemu-") as temp:
        temp_dir = pathlib.Path(temp)
        for level in ("O2", "O3"):
            objects: list[str] = []
            compile_inputs = (
                (ROOT / "experiments/riscv/manual_sat_i8.c", "manual"),
                (ROOT / "experiments/riscv/intrinsic_sat_i8.ll", "intrinsic"),
                (ROOT / "experiments/riscv/correctness.c", "correctness"),
                (ROOT / "experiments/riscv/start.S", "start"),
            )
            commands: list[list[str]] = []
            for source, name in compile_inputs:
                object_file = temp_dir / f"{name}.{level}.o"
                command = [
                    str(CLANG),
                    *TARGET_FLAGS,
                    f"-{level}",
                    "-c",
                    str(source),
                    "-o",
                    str(object_file),
                ]
                result = run(command)
                if result.returncode:
                    raise RuntimeError(
                        f"compile failed: {' '.join(command)}\n{result.stderr}"
                    )
                commands.append(command)
                objects.append(str(object_file))

            executable = temp_dir / f"correctness.{level}.elf"
            link_command = [
                str(GNU_LD),
                "-Ttext=0x80000000",
                "--no-relax",
                "-e",
                "_start",
                "-o",
                str(executable),
                objects[-1],
                *objects[:-1],
            ]
            result = run(link_command)
            if result.returncode:
                raise RuntimeError(
                    f"link failed: {' '.join(link_command)}\n{result.stderr}"
                )
            commands.append(link_command)

            qemu_command = [
                str(QEMU),
                "-machine",
                "virt",
                "-cpu",
                "rv64,v=true,vlen=128,elen=64",
                "-nographic",
                "-bios",
                "none",
                "-kernel",
                str(executable),
                "-monitor",
                "none",
                "-serial",
                "none",
            ]
            result = run(qemu_command, timeout=20)
            report_lines.append(f"{level}: exit={result.returncode}")
            report_lines.extend(f"  command: {' '.join(command)}" for command in commands)
            if result.stdout.strip():
                report_lines.append(f"  stdout: {result.stdout.strip()}")
            if result.stderr.strip():
                report_lines.append(f"  stderr: {result.stderr.strip()}")
            if result.returncode != 0:
                raise RuntimeError(
                    f"QEMU correctness run failed at {level}: exit {result.returncode}\n"
                    f"{result.stdout}{result.stderr}"
                )

    report = "\n".join(report_lines) + "\n"
    (output / "functional-validation.txt").write_text(report)
    print(report, end="")


if __name__ == "__main__":
    main()
