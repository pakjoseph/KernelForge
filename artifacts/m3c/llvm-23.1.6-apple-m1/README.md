# M3c AArch64 conversion artifacts

This snapshot records the LLVM 23.1.6 AArch64 comparison of the manual
float-to-int8 clamp/select loop and the explicit `llvm.fptosi.sat` loop.
`metadata.json` records the host and tool identities, target flags, exact
commands, correctness status, IR counts, loop-body observations, and timing
method. The detailed interpretation and limitations are in
[`docs/m3c-aarch64-runtime-study.md`](../../../docs/m3c-aarch64-runtime-study.md).

- `ir/` contains optimized O2/O3 IR for both kernels, manual frontend IR, the
  explicit `mem2reg,aggressive-instcombine` result, and manual IR processed by
  the default O2/O3 pipelines.
- `remarks/` contains Clang loop-vectorization remarks for each kernel and
  optimization level.
- `assembly/` contains the standalone generated O2/O3 AArch64 assembly.
- `linked/` contains disassembly of both kernel symbols from the final
  O2/O3 benchmark executables. The temporary executables are not retained.
- `traces/` contains default-pipeline `opt -debug-pass-manager` output for the
  manual input.
- `correctness/` contains the O2/O3 independent-reference results.
- `timings/raw.csv` contains the 160 paired observations. `summary.json`
  contains per-variant medians/IQR/MAD, paired-speedup summaries and
  descriptive bootstrap intervals; `*.stderr.txt` are the timing-session
  stderr logs.

Regenerate on the recorded machine with the pinned toolchain using
`python3 experiments/aarch64/m3c/run_m3c.py` from the repository root. Timing
is machine-specific, has no CI threshold, and is not a general performance
claim.
