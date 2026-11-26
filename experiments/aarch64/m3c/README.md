# M3c AArch64 conversion comparison

This standalone experiment compares the M3a manual clamp/select conversion
against the explicit `llvm.fptosi.sat.i8.f32` intrinsic on the recorded Apple
M1 Pro. Both kernels are linked into the same benchmark executable at O2 and
O3. Each kernel is `noinline`, compiled in a separate translation unit, and
linked without LTO. The driver creates input at runtime and checksums the
outputs after timing.

## Run

From the repository root, with the pinned LLVM/Clang 23.1.6 toolchain:

```sh
python3 experiments/aarch64/m3c/run_m3c.py
```

The runner saves optimized IR, vectorization remarks, standalone assembly,
default-pipeline traces, linked-kernel disassembly, correctness logs, raw
paired samples, summary statistics, exact command arrays, and machine/toolchain
metadata under `artifacts/m3c/llvm-23.1.6-apple-m1/`. It rejects an LLVM tool
version other than 23.1.6 and requires macOS arm64. Do not run it in CI; the
timing results are machine-specific and have no pass/fail threshold.

## Workload and measurement method

The independent correctness reference converts the input to `double`, applies
`std::trunc`, clamps the truncated value, and casts only after it is in the
signed int8 range. It checks NaN, infinities, signed zero, fractions, adjacent
float values around both saturation limits, and vector-tail lengths from zero
through 4097 elements. It also checks the 8,388,608-element large case before
timing.

The timed sizes are:

- 4,096 elements: a repeatedly reused 16 KiB input plus two 4 KiB output
  arrays, 24 KiB total.
- 8,388,608 elements: 32 MiB input plus two 8 MiB output arrays, 48 MiB total.

The large size exceeds M3a's 4,097-element correctness maximum. Benchmark
inputs are deterministic thousandth-step values in `[-160, 160]`, with one
value from the 39-element semantic edge corpus inserted every 257 elements.
This is a synthetic bounded workload, not an application trace.

At each size, six warmup pairs precede five calibration pairs. Calibration
chooses a shared repetition count for both kernels so the slower variant's
sample lasts about 20 ms. There are two independent process sessions per
optimization level, each with 20 paired samples (40 pairs total). The variant
order alternates within a session and reverses at the start of the second
session. O2 and O3 session order also reverses between sessions.

The timed region contains only repeated kernel calls. Allocation, input
generation, correctness checks, calibration, output comparison, checksums, and
formatting occur outside it. The metric is elapsed `steady_clock` nanoseconds
per call. The summary reports each variant's median, IQR, and MAD, plus paired
speedup ratios defined as manual time divided by intrinsic time. A 95%
percentile interval uses a stratified two-pair-block bootstrap within the two
process sessions. The interval is descriptive and may understate serial thermal
or scheduler correlation; no samples are excluded.

No source, output, or timing data is shared with the M3b RVV experiment.
