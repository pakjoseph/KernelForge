# KernelForge

KernelForge is an independent LLVM compiler engineering project. M0 establishes
an out-of-tree New Pass Manager plugin; M1 implements the read-only
`kernel-access-report` analysis pass; M2 establishes correctness and
compiler-output baselines. Later roadmap items remain proposals.

## Toolchain

The first implementation is pinned exactly to LLVM/Clang 23.1.6. The validated
development machine is Apple Silicon (`arm64-apple-darwin25.6.0`) using the
Homebrew LLVM 23.1.6 bottle at `/opt/homebrew/opt/llvm`. The installed `opt`,
`llvm-config`, `clang`, `clang++`, and `FileCheck` all report 23.1.6. `llvm-diff`
is also from this toolchain. The initial LLVM installation did not include
`lit`/`llvm-lit`; CTest runs the FileCheck fixtures directly.

| Tool | Recorded version or status |
| --- | --- |
| `llvm-config`, `opt`, `clang`, `clang++`, `FileCheck`, `llvm-diff` | LLVM 23.1.6 |
| CMake | 4.4.5 |
| Ninja | 1.13.2 |
| LLVM `lit` / `llvm-lit` | Not installed |

## Setup

The Homebrew `llvm` formula supplied a native Apple Silicon 23.1.6 bottle for
this setup. Because the formula tracks LLVM's latest release, check its version
before installing; continue only when it is exactly 23.1.6:

```sh
brew info llvm
brew install llvm
```

If Homebrew has moved to another LLVM release, use an archived 23.1.6 formula or
bottle instead. Do not build against a different release; CMake rejects it.

Check the selected toolchain before configuring:

```sh
LLVM_PREFIX="$(brew --prefix llvm)"
"$LLVM_PREFIX/bin/llvm-config" --version
"$LLVM_PREFIX/bin/opt" --version
"$LLVM_PREFIX/bin/clang" --version
```

Each LLVM/Clang version must be exactly `23.1.6`. CMake also rejects another
LLVM package version.

## Build

```sh
LLVM_PREFIX="$(brew --prefix llvm)"
cmake -S . -B build -G Ninja \
  -DLLVM_DIR="$LLVM_PREFIX/lib/cmake/llvm" \
  -DCMAKE_C_COMPILER="$LLVM_PREFIX/bin/clang" \
  -DCMAKE_CXX_COMPILER="$LLVM_PREFIX/bin/clang++"
cmake --build build
```

## Run the pass

```sh
LLVM_PREFIX="$(brew --prefix llvm)"
"$LLVM_PREFIX/bin/opt" \
  -load-pass-plugin build/KernelAccessReport.so \
  -passes=kernel-access-report \
  -pass-remarks-analysis=kernel-access-report \
  -verify-each -disable-output tests/lit/unit_stride.ll
```

Use `-S input.ll -o output.ll` instead of `-disable-output` to write IR. The
pass is read-only, and the regression suite checks this with `llvm-diff`.

## Test

```sh
ctest --test-dir build --output-on-failure
```

Tests cover unit and non-unit byte strides, known and unknown trip counts,
known-disjoint, possibly-overlapping, and identical memory locations, dynamic
strides, and unsupported nested/multi-exit loop shapes. They verify the IR and
check that the pass leaves it unchanged.

## M2 kernel and baseline suite

The suite adds SAXPY, a floating-point dot product, and a one-dimensional
three-point stencil. Stencil endpoints copy the corresponding input values;
interior elements are the average of their left, center, and right neighbors.
For non-empty calls, SAXPY's `x`, `y`, and output arrays must be pairwise
disjoint; stencil input and output must not overlap. Dot-product inputs are
read-only and may overlap. Empty calls may pass null pointers.

Correctness tests use deterministic inputs for 20 sizes from 0 through 4097,
including odd lengths and sizes around four-float AArch64 vector boundaries.
O2 and O3 kernel executables are compared with separate scalar references using
`abs(actual - expected) <= 1e-4 + 2e-5 * abs(expected)`. Reference code is built
without loop/SLP vectorization or floating-point contraction.

Generate the saved compiler outputs on Apple Silicon with the pinned toolchain:

```sh
cmake --build build --target m2-baselines
```

The snapshot is in
[`artifacts/m2/llvm-23.1.6-apple-m1`](artifacts/m2/llvm-23.1.6-apple-m1/README.md).
It contains Clang frontend IR and prepared report input IR, M1 access remarks,
O2/O3 optimized IR, vectorizer remarks, AArch64 assembly, and tool/machine/flag
metadata. CTest also regenerates artifacts into the build directory and checks
that the report and vectorizer remarks were produced.

The README in the snapshot and [the M2 report](docs/m2-baseline.md) distinguish
compiler output from correctness results and performance measurements:

- **Compiler output:** saved IR, remarks, and assembly for each kernel at O2
  and O3, with `-fno-fast-math`.
- **Correctness:** the O2 and O3 CTest executables each passed all 20 sizes.
- **Local performance:** not measured. M2 and CTest contain no timing runs or
  performance thresholds.

On this host, Clang's O2 and O3 vectorizer remarks report width 4 and interleave
count 4 for all three kernels. These results make simple loop vectorization a
poor M3 target; M3 should first identify a specific behavior the standard
pipeline misses. M1 alias remarks remain pairwise alias-query results, not
iteration-level dependence proofs.

## M0/M1 limits

The pass reports facts established by LLVM analyses for a deliberately small
loop shape. `NoAlias`, `MayAlias`, and `MustAlias` are pairwise alias-query
results, not loop-dependence proofs. The pass does not identify vectorizable
loops, predict performance, or change the program.

M3 and later remain proposed work: selecting and validating a narrowly scoped
transformation, examining RVV code generation, optional OpenCL/SPIR-V
exploration, and preparing a reproducible portfolio release.
