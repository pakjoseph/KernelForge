# KernelForge M2 compiler-output baseline

This directory separates report input IR, optimized IR, optimization remarks, access reports, and AArch64 assembly. `metadata.json` records the selected tool versions, host/target, flags, workloads, tolerances, and commands.

- `ir/*.report-input.ll` is Clang `-O0` frontend IR prepared with `mem2reg` and `loop-simplify` for `kernel-access-report`; `ir/*.frontend.ll` is the unprepared Clang frontend output. Nonsemantic IR ModuleID comments are normalized to keep artifacts independent of the output directory.
- `reports/*.txt` contains M1 optimization-analysis remarks.
- `ir/*.O2.ll` and `ir/*.O3.ll` are standard Clang optimized IR outputs.
- `remarks/*.txt` contains vectorizer analysis, passed, and missed remarks for the matching optimization level.
- `assembly/*.s` contains matching AArch64 assembly.

These are compiler outputs, not correctness logs or performance results. No timing is collected here or in CTest. Reproduce from the project root with `cmake --build build --target m2-baselines`.
