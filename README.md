# KernelForge

## About

KernelForge is an independent LLVM compiler engineering portfolio project. It
demonstrates an out-of-tree LLVM plugin, analysis using LLVM's New Pass Manager,
regression testing, and reproducible compiler-output investigations. It
complements prior work on RISC-V Vector instruction semantics and simulator
validation; this repository focuses on LLVM compiler behavior and does not
implement RVV instruction semantics.

The project is pinned to LLVM/Clang 23.1.6. Its implemented pass is
read-only: it reports memory-access facts for a deliberately limited class of
loops and does not transform IR or claim that a loop is vectorizable.

## Project status

- **M0/M1 — implemented:** an out-of-tree New Pass Manager plugin with the
  `kernel-access-report` analysis pass and LLVM-style regression fixtures.
- **M2 — recorded:** SAXPY, dot product, and three-point stencil correctness
  tests and LLVM compiler-output baselines. No timing data was collected.
- **M3a/M3c — research:** the manual and explicit saturating-conversion forms
  were compared on the M1 Pro. The tested synthetic workload shows a repeatable
  runtime difference; no custom optimization has been implemented, and a
  separate legality/design review is still required.
- **M3b — backend study:** LLVM 23.1.6 RV64V lowering and QEMU functional
  validation are recorded. No hardware or performance result is claimed.

No custom optimizer has been implemented. See [design](docs/design.md), the
[M2 baseline report](docs/m2-baseline.md), the [M3 design gate](docs/m3-design-gate.md),
the [M3b RVV report](docs/m3b-rvv-validation.md), and the
[M3c AArch64 runtime study](docs/m3c-aarch64-runtime-study.md).

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
count 4 for all three kernels. These results do not justify a custom
vectorization pass. The M3 design gate and subsequent conversion study are
documented separately; M1 alias remarks remain pairwise alias-query results,
not iteration-level dependence proofs.

## M3b RV64V conversion study

The M3b experiment compares a manually clamped float-to-int8 loop with the
explicit `llvm.fptosi.sat` intrinsic under LLVM 23.1.6 for RV64GCV. It saves
optimized IR, vectorization remarks, scalar-only and vector assembly,
disassembly, and command/tool metadata. A freestanding harness checks
hand-derived results under QEMU; the study contains no runtime timing and does
not demonstrate performance on RISC-V hardware or the M1 Pro.

Regenerate the compiler artifacts and optional QEMU correctness result from the
repository root:

```sh
python3 experiments/riscv/generate.py
python3 experiments/riscv/run_qemu.py
```

See [the experiment instructions](experiments/riscv/README.md) and [the M3b
report](docs/m3b-rvv-validation.md) for prerequisites, exact flags, and limits.

## M3c AArch64 runtime comparison

The M3c study compares the manual and explicit saturating-conversion forms
under LLVM/Clang 23.1.6 at O2 and O3 on the recorded M1 Pro. It includes
independent-reference correctness results, optimized IR and assembly, and
paired local timing samples with variability summaries. The result applies to
the tested synthetic workload only; timings are not run in CI and do not
establish application-level performance. See the [M3c report](docs/m3c-aarch64-runtime-study.md)
and [reproduction instructions](experiments/aarch64/m3c/README.md).

## M0/M1 limits

The pass reports facts established by LLVM analyses for a deliberately small
loop shape. `NoAlias`, `MayAlias`, and `MustAlias` are pairwise alias-query
results, not loop-dependence proofs. The pass does not identify vectorizable
loops, predict performance, or change the program.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the pinned toolchain, verification
commands, and evidence standards used for changes to the pass and experiments.

## License

KernelForge is distributed under the [MIT License](LICENSE). LLVM is an external
toolchain dependency and is not included in this repository.
