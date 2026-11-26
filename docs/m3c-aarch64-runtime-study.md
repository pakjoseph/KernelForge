# M3c: AArch64 saturating-conversion runtime study

## Result

The M3c run found a repeatable runtime difference for this conversion loop on
the recorded Apple M1 Pro. At O2 and O3, and at both tested sizes, the explicit
`llvm.fptosi.sat.i8.f32` version was faster in all 160 paired observations;
all descriptive paired 95% bootstrap intervals were above 1. This addresses
M3a's missing runtime evidence for the tested pattern and workload. It does not
show an application speedup or generalize to other inputs, machines, or LLVM
builds.

The experiment also reproduces an LLVM IR gap: O2 and O3 retain the manual
NaN-check/clamp/convert sequence, while the intrinsic remains an explicit
saturating conversion. Running `aggressive-instcombine` on the manual frontend
IR did not produce the intrinsic; the default O2/O3 traces show that
`AggressiveInstCombinePass` ran. This is a concrete candidate for a separate
legality and design review. The custom pass remains unimplemented and on hold
until that review establishes a narrow input contract and semantic proof.
Together, the IR and timing results meet the evidence threshold to reconsider
this pattern in that separate review; they do not authorize implementation or
establish a legal pass contract.

## Evidence reviewed

- M3a scratch sources and outputs were available at
  `/private/tmp/kernelforge-m3a.EkNveV`. I inspected `kernel.cpp`,
  `reference.cpp`, `manual-loop.ll`, `sat-loop.ll`, optimized O2/O3 IR,
  vectorizer remarks, assembly, and default-pipeline traces.
- M3a's claim that the intrinsic had a smaller *raw* static loop-body count is
  not supported by those saved loop assemblies under one consistent counting
  method. At both O2 and O3, the annotated vector body has 41 instructions for
  manual and 73 for intrinsic, including the backedge. The manual body stores
  16 output bytes per iteration; the intrinsic body stores 64. These are
  static code-shape observations, not dynamic instruction counts or a
  performance model.
- The M3c inputs are [`manual_kernel.cpp`](../experiments/aarch64/m3c/manual_kernel.cpp),
  [`intrinsic_kernel.ll`](../experiments/aarch64/m3c/intrinsic_kernel.ll), and
  [`benchmark.cpp`](../experiments/aarch64/m3c/benchmark.cpp). The reproducible
  runner and method are documented in
  [`experiments/aarch64/m3c/README.md`](../experiments/aarch64/m3c/README.md).
- Generated IR, remarks, standalone assembly, linked-kernel disassembly,
  pass-manager traces, correctness logs, raw timings, summaries, and command
  metadata are in
  [`artifacts/m3c/llvm-23.1.6-apple-m1`](../artifacts/m3c/llvm-23.1.6-apple-m1/README.md).

The M2 and M3b artifacts were not inputs to the AArch64 timing comparison. No
RVV code generation or timing is included.

## Workload and correctness

Both noinline kernels map each `float` to signed `int8`: NaNs become zero,
finite and infinite values clamp to `[-128, 127]`, and in-range values
truncate toward zero. The independent scalar oracle converts to `double`,
applies `std::trunc`, and casts only after the result is in the int8 range.
Thus an out-of-range C++ float-to-integer conversion is never used as the
oracle. The kernels require input and output storage not to overlap; both
interfaces communicate this with restricted/noalias pointers.

O2 and O3 correctness runs passed. Each checked 39 hand-selected values
including NaNs, both infinities, signed zero, positive and negative fractions,
large finite overflow, and representable `float` neighbors around both clamp
limits. Those values were rotated over 28 lengths from 0 through 4097, plus
8,388,608. The generated benchmark inputs were separately checked against the
same oracle before timing. At length zero the harness permits null pointers.

## Compiler output

The pinned Homebrew LLVM tools report 23.1.6. Compilation used target argument
`arm64-apple-darwin25.6.0`, `-mcpu=apple-m1`, and `-fno-fast-math` at both O2
and O3. Both kernels are built in separate objects, marked noinline, linked
into the same harness without LTO, and checked in the final linked disassembly.
The linked symbols are present and their disassemblies differ at both
optimization levels. Clang's Apple target configuration normalizes emitted
IR to `arm64-apple-macosx26.0.0` and target CPU `apple-a14`; this normalization
is recorded in the IR. The explicit IR compile emits a module-triple override
warning, but the same command-line target and CPU flags are used for both
variants.

In the optimized manual IR, the NaN check, float bounds checks/selects, and
ordinary `fptosi` remain; it contains no `llvm.fptosi.sat` call. The explicit
version contains six saturating calls after vectorization (four 16-lane calls
in the main loop, plus vector and scalar remainder forms), and no ordinary
`fptosi` opcode. The manual frontend IR passed through
`mem2reg,aggressive-instcombine` still contained no saturating call. Default
O2 and O3 `opt` traces include `AggressiveInstCombinePass`, but the optimized
manual IR still contains no saturating call. The explicit pass test therefore
did not replace this tested int8 clamp pattern.

At O2 and O3, Clang reports vectorization width 16 for both. The manual loop
uses interleave count 1 and the intrinsic loop interleave count 4. The
annotated main vector bodies contain 41 and 73 static instructions,
respectively, including each backedge, and store 16 and 64 output bytes per
iteration. Counts run from LLVM's inner-loop marker through the conditional
backedge; directives, labels, comments, and setup before the loop are excluded.
Output bytes are summed from the vector stores in that loop body. The intrinsic
body is larger in raw instruction count while processing four times as many
elements per iteration. Remainder loops and scalar handling differ too; see
the complete assembly and linked disassembly. No instruction count is used as
a speed estimate.

## Runtime method and measurements

The recorded host is a MacBook Pro 18,3 with Apple M1 Pro, 16 GB memory, macOS
26.6.2 arm64. It was on AC power before and after measurement. `pmset -g therm`
did not expose thermal telemetry, and the process was not CPU-pinned.

The small case uses 4,096 elements (16 KiB input and two 4 KiB outputs, 24 KiB
combined). The large case uses 8,388,608 elements (32 MiB input and two 8 MiB
outputs, 48 MiB combined), above the M3a correctness maximum. Input is
deterministic, with thousandth-step values over `[-160,160]` and one edge-case
value every 257 elements. It is a synthetic workload, not a captured
application distribution.

Each process warmed both variants for six pairs and calibrated a common
repetition count to make the slower variant's timing batch about 20 ms. There
were two process sessions per optimization level and size, with 20 paired
samples per session (40 pairs per cell). Variant order alternated within each
session and reversed at session start. O2/O3 process order also reversed in
the second session. Timing covered only kernel calls; setup, input generation,
correctness, output comparison, checksums, and formatting were outside the
timed region. No samples were excluded. The summary reports median, IQR, and
MAD for each variant and for paired speedup. The 95% interval is a stratified
percentile bootstrap over two-pair blocks within the two sessions; it is
descriptive and does not remove serial thermal or scheduler correlation.

| Level | Elements | Manual median (IQR) | Intrinsic median (IQR) | Paired speedup median (IQR) | Paired 95% interval |
| --- | ---: | ---: | ---: | ---: | ---: |
| O2 | 4,096 | 0.705 µs (0.004) | 0.300 µs (0.001) | 2.354× (0.015) | 2.3516–2.3553 |
| O2 | 8,388,608 | 1,457.097 µs (12.557) | 642.478 µs (15.366) | 2.271× (0.042) | 2.2518–2.2867 |
| O3 | 4,096 | 0.705 µs (0.002) | 0.300 µs (0.002) | 2.353× (0.013) | 2.3469–2.3550 |
| O3 | 8,388,608 | 1,449.412 µs (4.181) | 634.958 µs (9.228) | 2.284× (0.037) | 2.2600–2.2878 |

Variant values are per-call medians and IQRs across the 40 measurements. Paired
speedup is `manual ns/call / intrinsic ns/call`, so values above one favor the
intrinsic. No timing was run in CI and no timing threshold was added.

## Interpretation and next step

For this host, compiler build, code, and deterministic input distribution,
both variants vectorize, but the intrinsic's loop interleave count and runtime
results differ consistently. The measured difference is repeatable across the
two process sessions, both optimization levels, and both working-set sizes.
This is evidence for a narrow optimization opportunity, not proof of speedup
for arbitrary applications or other targets. A repeat on another day or a
second realistic input distribution would strengthen the runtime evidence.

The smallest next step is a separate design and legality review for a narrowly
specified canonicalization of the observed NaN-check/clamp/fptosi pattern.
That review must define exact IR and semantic preconditions, preserve negative
cases, and compare the candidate fairly against LLVM 23.1.6 before any pass is
implemented. M3c compared the two source forms only; it did not implement a
custom pass.

## Reproduction

From the repository root on the recorded Apple Silicon host:

```sh
python3 experiments/aarch64/m3c/run_m3c.py
```

The runner checks the LLVM version, verifies IR, compiles and disassembles the
linked variants, runs O2/O3 correctness first, then collects timings. Exact
commands, tool identities, raw samples, summaries, and generated outputs are
saved under `artifacts/m3c/llvm-23.1.6-apple-m1/`.
