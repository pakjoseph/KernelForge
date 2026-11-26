#!/usr/bin/env python3
"""Run FileCheck regression fixtures and verify the pass preserves LLVM IR."""

import argparse
import pathlib
import subprocess
import tempfile


def run(command, *, input_text=None):
    return subprocess.run(
        [str(part) for part in command],
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--opt", required=True)
    parser.add_argument("--filecheck", required=True)
    parser.add_argument("--llvm-diff", required=True)
    parser.add_argument("--plugin", required=True)
    parser.add_argument("--tests", required=True, type=pathlib.Path)
    args = parser.parse_args()

    fixtures = sorted(args.tests.glob("*.ll"))
    if not fixtures:
        raise SystemExit(f"no LLVM IR fixtures found in {args.tests}")

    failures = []
    with tempfile.TemporaryDirectory(prefix="kernelforge-tests-") as temporary:
        temporary_path = pathlib.Path(temporary)
        for fixture in fixtures:
            output_ir = temporary_path / f"{fixture.stem}.out.ll"
            command = [
                args.opt,
                "-load-pass-plugin",
                args.plugin,
                "-passes=kernel-access-report",
                "-verify-each",
                "-S",
                str(fixture),
                "-o",
                str(output_ir),
                "-pass-remarks-analysis=kernel-access-report",
            ]
            opt_result = run(command)
            if opt_result.returncode:
                failures.append(
                    f"{fixture.name}: opt failed ({opt_result.returncode})\n"
                    f"{opt_result.stderr}"
                )
                continue

            diff_result = run([args.llvm_diff, str(fixture), str(output_ir)])
            if diff_result.returncode:
                failures.append(
                    f"{fixture.name}: output IR changed\n"
                    f"{diff_result.stdout}{diff_result.stderr}"
                )
                continue

            check_result = run(
                [args.filecheck, "--check-prefix=REPORT", str(fixture)],
                input_text=opt_result.stderr,
            )
            if check_result.returncode:
                failures.append(
                    f"{fixture.name}: FileCheck failed\n"
                    f"{check_result.stdout}{check_result.stderr}\n"
                    f"Remarks:\n{opt_result.stderr}"
                )
                continue

            print(f"PASS {fixture.name}")

    if failures:
        for failure in failures:
            print(f"FAIL {failure}")
        raise SystemExit(1)

    print(f"Passed {len(fixtures)} KernelForge regression fixtures.")


if __name__ == "__main__":
    main()
