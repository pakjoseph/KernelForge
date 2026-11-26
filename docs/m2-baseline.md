# M2 baseline findings

## Environment and method

This snapshot was generated with LLVM/Clang 23.1.6 on a MacBook Pro 18,3 with
Apple M1 Pro, running macOS 26.6.2. Code generation targets
`arm64-apple-darwin25.6.0` with `-mcpu=apple-m1`, matching the LLVM toolchain's
reported host CPU. `metadata.json` records the full commands, flags, tool
versions, machine information, and deterministic workload sizes.

For M1 reports, each kernel was compiled to unoptimized frontend IR with
`-O0 -Xclang -disable-O0-optnone`, prepared by `mem2reg,loop-simplify`, then run
through the unchanged `kernel-access-report` plugin. The O2/O3 artifacts use
Clang's standard pipelines with `-fno-fast-math`; the generator verifies each
optimized IR file and captures `-Rpass`, `-Rpass-missed`, and `-Rpass-analysis`
remarks for loop vectorization.

Correctness uses 20 deterministic lengths: 0–9 around the first four-float
vector boundary, 15–17, 31–33, 63–65, 257, and 4097. O2 and O3 tests compare
against separately compiled scalar references. The tolerance is absolute
`1e-4` plus relative `2e-5 * abs(reference)`. No timing runs were performed.

## Observed compiler output

At both O2 and O3, LLVM reports a vectorization width of 4 and interleave count
of 4 for SAXPY, dot, and stencil. The dot-product optimized IR contains
`llvm.vector.reduce.fadd.v4f32`; its assembly includes four-lane `fmul.4s`
operations and scalar accumulation steps. This shows the standard pipeline
already handles this reduction shape without `-ffast-math` on this toolchain.
SAXPY and stencil also have vector instructions in their saved assembly.

The access reports find 4-byte unit strides for the memory accesses in all
three loops. SAXPY and stencil report `NoAlias` results under their documented
non-overlap preconditions. Dot reports `MayAlias` between its two read-only
inputs because they may be the same array. Each report says
`loop-carried-dependence=not-analyzed`.

## M3 selection evidence

These results argue against selecting a basic SIMD/vectorization rewrite for
these exact kernels: LLVM 23.1.6 already vectorizes every loop at both O2 and
O3. M3 should compare candidate ideas with this baseline and focus on a
well-defined gap in standard optimization, or select a constrained kernel
variant that demonstrates a specific missed opportunity. The access report
does not establish iteration-level legality, and these artifacts contain no
performance evidence, so neither should be used to claim a speedup or prove a
transformation safe.

No Linux/WSL portability check or `-ffast-math` experiment is included.
