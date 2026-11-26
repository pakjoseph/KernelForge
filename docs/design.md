# M0/M1 design

## Toolchain

The initial implementation is pinned to LLVM and Clang 23.1.6. The plugin is a
separate C++ shared module built against the LLVM CMake package and loaded by
the same release's `opt` executable. The plugin uses LLVM's New Pass Manager.

## Pass contract

`kernel-access-report` is a read-only function pass. It accepts one top-level,
single-level loop in LoopSimplify form with one preheader, one latch, one
exiting block, and one exit block. It uses LoopInfo, ScalarEvolution, alias
analysis, and the module DataLayout to report constant trip counts, scalar or
scalable load/store widths, address spaces, affine byte strides, and pairwise
alias-query results.

If a fact cannot be established, the pass reports `unknown` or an unsupported
reason. It reports small constant trip counts; symbolic or unavailable counts
are reported as unknown. It reports only `NoAlias`, `MayAlias`, or `MustAlias`;
LLVM's `PartialAlias` is presented as `MayAlias (partial overlap)`. It does not
infer iteration-level dependence safety from alias results and does not assess
vectorizability or profitability. Loads, stores, and aliases are all
descriptive facts; the pass makes no IR changes and preserves all analyses.

The intentionally unsupported cases include nested or multiple loops,
non-canonical control flow, no loop, and unsupported memory operations such as
calls or memory intrinsics. A load/store with a non-affine or non-constant byte
stride is still reported, with its stride marked unknown. If the module has no
data layout and an access type needs one to determine its width, width is also
reported as unknown. Unsupported memory operations are called out even when
other accesses in the loop can be reported.

## Verification model

Regression fixtures use FileCheck-style `REPORT` directives. The test driver
runs `opt` with `-verify-each`, checks the emitted optimization remarks, and
uses `llvm-diff` to confirm the output IR is unchanged. LLVM `lit` was not
present in the initial Apple Silicon toolchain, so CTest runs these fixtures
directly with FileCheck.
