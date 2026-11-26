# M3 design gate

## Decision

**NO-GO: do not implement a custom transformation yet.** The M2 kernels do not
show a missed basic optimization, and the candidate transformations reviewed
here either already exist in LLVM 23.1.6 or are not exposed by the current
workload. The artifacts contain no performance measurements, so they cannot
support a profitability claim. This document is a research decision only; no
pass, test, build rule, or M2 artifact was changed for M3.

## Evidence reviewed

Repository instructions and design material reviewed:

- No `KernelForge/AGENTS.md` is present. The global engineering instructions
  supplied for this task apply.
- [README.md](../README.md), [M0/M1 design](design.md),
  [M2 baseline findings](m2-baseline.md),
  [baseline generator](../tools/generate_baselines.py), and
  [correctness tests](../tests/kernel_correctness.cpp).
- The six M1 FileCheck fixtures in `tests/lit/`, which check access reports,
  including the explicit `loop-carried-dependence=not-analyzed` field.

M2 artifacts reviewed under
[`artifacts/m2/llvm-23.1.6-apple-m1`](../artifacts/m2/llvm-23.1.6-apple-m1/README.md):

- `metadata.json` records LLVM/Clang 23.1.6, target
  `arm64-apple-darwin25.6.0`, `-mcpu=apple-m1`, `-fno-fast-math`, MacBook Pro
  18,3 / Apple M1 Pro, macOS 26.6.2, workloads, and commands.
- `ir/*.frontend.ll` and `ir/*.report-input.ll` contain the frontend and
  prepared inputs to `kernel-access-report`. `ir/*.O2.ll` and `ir/*.O3.ll`
  contain optimized IR.
- `reports/*.txt` contains the M1 pass output. Each kernel's dynamic trip count
  is unknown; its accesses are 4-byte unit stride in address space 0. SAXPY and
  stencil report pairwise `NoAlias` under the documented preconditions; dot's
  read-only inputs report `MayAlias`.
- All six files in `remarks/` report vectorization width 4 and interleave count
  4. The optimized dot IR contains `llvm.vector.reduce.fadd.v4f32`; its assembly
  contains four-lane `fmul.4s` operations and reduction work. The optimized
  stencil IR contains vector loads and `shufflevector` operations to form its
  neighboring windows; its assembly contains `ext.16b` and vector arithmetic.
  These are compiler-output observations, not speed or legality claims.
- `assembly/*.O2.s` and `assembly/*.O3.s` are generated for the recorded
  AArch64 target. The snapshot README explicitly says they are not timing data.

The project README records that both correctness executables passed all 20
sizes using separate scalar references and the stated tolerance. The artifact
snapshot does not contain per-run correctness logs. No timing data is recorded
in M2. The M1 pairwise alias answers do not prove loop-carried dependence
safety.

For the overlap check, the installed tool reported `Homebrew LLVM version
23.1.6`. Its `opt --print-passes` output includes `loop-fusion`,
`loop-unroll-and-jam`, and `aggressive-instcombine`. A local
`-passes=default<O3> -debug-pass-manager` trace on the M2 dot frontend IR showed
`AggressiveInstCombinePass`, `LoopVectorizePass`, and `LoopUnrollPass`; it did
not show fusion or unroll-and-jam. That input has only one loop, so this trace
does not test those loop-nest transformations.

I also fed a scratch IR pattern to the exact local `opt` without writing a
project file. The pattern was `fptosi float to i32`, followed by
`llvm.smax.i32(..., INT32_MIN)` and `llvm.smin.i32(..., INT32_MAX)`. Explicit
`-passes=aggressive-instcombine` rewrote it to `llvm.fptosi.sat.i32.f32`.
`default<O2>` and `default<O3>` removed the full-range min/max as identity
operations and left plain `fptosi`. This probe establishes that the named
existing pass can perform the canonicalization; it does not establish that the
rewrite benefits a real workload or changes generated machine code.

## Candidate comparison

| Candidate | LLVM overlap | Novelty | Difficulty | Correctness risk | Relevance to M2 |
| --- | --- | --- | --- | --- | --- |
| Adjacent loop fusion | LLVM 23.1.6 has `loop-fusion` | Low unless a specific gap beyond that pass is demonstrated | High | High | Low: each M2 kernel has one loop, not an adjacent pair |
| Unroll-and-jam | LLVM 23.1.6 has `loop-unroll-and-jam` | Low for the standard transform | Medium-high | High | None: M2 has no nested loop |
| Saturating FP-to-int canonicalization | `aggressive-instcombine` recognizes the tested `fptosi`/min/max pattern; LLVM IR defines `llvm.fptosi.sat` | Low for that pattern | Medium | High around poison, NaNs, infinities, bounds, and rounding | None: M2 has no conversion workload |
| Stencil neighbor-window reuse | Standard loop vectorization already emitted vector loads and shuffles for this stencil | None for this exact pattern | High | High around boundaries, tails, and memory overlap | Direct, but already performed in M2 output |
| Dot reduction tree | Standard loop vectorization already emitted a vector reduction | Low for a generic vector reduction | Medium | High because changing FP accumulation order changes results | Direct, but no missed vector reduction is shown |

### Adjacent loop fusion

The candidate input would be two adjacent loops with matching iteration
domains, such as:

```text
for i in [0, N): tmp[i] = f(x[i])
for i in [0, N): out[i] = g(tmp[i])
```

The proposed fused form executes both bodies for each `i`, preserving the
producer-before-consumer order while removing a loop boundary and potentially
keeping `tmp[i]` nearer in cache. LLVM's existing fusion pass already handles
eligible adjacent loops and uses ScalarEvolution and DependenceAnalysis. Its
documented restrictions include compatible loop form and trip counts, strict
adjacency, and rejection of unsafe dependencies or cross-loop SSA use. A
`NoAlias` answer from `kernel-access-report` would not replace these checks.

A custom pass would need a concrete gap beyond LLVM's pass before it is
justified. Tests would need equal and unequal trip counts, guarded and
unguarded loops, zero and one iterations, dependence directions, aliasing,
side effects, and rejection cases. Compare the same input under default O2/O3,
explicit `loop-fusion`, and any future custom pass. The M2 suite provides no
such loop pair.

### Unroll-and-jam

A small workload that can expose this transform is a row-wise matrix update:

```text
for i in [0, M):
  for j in [0, N): C[i,j] = A[i,j] + b[j]
```

With outer factor two, the proposed form runs one inner `j` loop for rows `i`
and `i+1`, potentially reusing `b[j]`. LLVM already has a LoopNest
`loop-unroll-and-jam` pass and loop metadata to request or control it. The M2
kernels are one-dimensional and cannot show a missed nested-loop opportunity;
this matrix workload would therefore be new research data, not support for a
custom implementation today.

Legality tests would need odd/even outer trip counts and remainder rows,
varying inner bounds, aliasing, loop-carried dependences, and memory effects.
Compare default O2/O3 with the explicit LLVM pass before considering a custom
variant. No current artifact suggests that LLVM's pass misses a case that
matters to this project.

### Saturating conversion canonicalization

For the tested full-range pattern, the before/after forms are:

```llvm
%cv = fptosi float %x to i32
%lo = call i32 @llvm.smax.i32(i32 %cv, i32 -2147483648)
%result = call i32 @llvm.smin.i32(i32 %lo, i32 2147483647)
```

```llvm
%result = call i32 @llvm.fptosi.sat.i32.f32(float %x)
```

The saturating intrinsic returns zero for NaN and clamps out-of-range values;
plain `fptosi` produces poison for out-of-range conversion. The replacement is
therefore a refinement of the original IR, not a claim of identical behavior
on poison inputs. LLVM 23.1.6's explicit `aggressive-instcombine` performed
this rewrite in the scratch probe. A custom implementation of the same pattern
would duplicate LLVM. The default pipeline's plain `fptosi` output is not
evidence of a missed runtime optimization, since M2 contains no such workload
and no assembly comparison or timing was made.

If this area is revisited, first define a small `f32`-to-`i32` saturating
conversion workload whose reference semantics cover NaN, positive and negative
infinity, values near both integer limits, and round-toward-zero behavior.
Inspect its frontend IR, default O2/O3 IR, explicit
`aggressive-instcombine` result, and AArch64 assembly. A custom candidate would
need to show a remaining IR or code-generation gap beyond that pass, plus
regression tests for scalar and vector lanes, boundary values, and tails.

### Stencil neighbor-window reuse

The source loop reads `input[i-1]`, `input[i]`, and `input[i+1]` for each
interior output. A custom vector-window transform might load adjacent vector
blocks and use lane shuffles to reduce repeated overlapping loads. M2's O2/O3
optimized stencil IR already contains vector loads and `shufflevector` nodes;
the saved assembly contains `ext.16b` instructions and vector adds/divides.
That is direct evidence LLVM already formed and lowered a neighboring-lane
window for this kernel. A custom rewrite would duplicate that result unless a
different measured target or workload exposed a specific deficiency.

Any alternative would need correctness checks for `n` from 0 through vector
tails, endpoint preservation, input/output disjointness, and exact floating
point evaluation order. Compare default O2/O3 assembly and correctness against
the custom result; vector instructions alone do not demonstrate a benefit.

### Dot reduction tree

The scalar source loop is a multiply-and-accumulate reduction. The M2 O2/O3
IR contains vector multiplies and `llvm.vector.reduce.fadd.v4f32`, and the
remarks report width four. Replacing this with a custom reduction tree would
repeat a capability already exercised by the baseline. A different tree may
change floating-point rounding and would need a clearly stated numerical
contract. The current evidence does not identify a missed reduction pattern.

## LLVM references and exact-version checks

The versioned LLVM 23.1 documentation describes the existing
[`loop-fusion`](https://releases.llvm.org/23.1.0/docs/LoopFusion.html),
[`loop-unroll-and-jam`, `aggressive-instcombine`, and other passes](https://releases.llvm.org/23.1.0/docs/Passes.html), and
[`llvm.fptosi.sat` semantics](https://releases.llvm.org/23.1.0/docs/LangRef.html#saturating-floating-point-to-integer-conversions).
LLVM publishes the 23.1 documentation at 23.1.0; the project itself remains
pinned to 23.1.6. The exact local 23.1.6 `opt --print-passes` output and
scratch-pass experiment above independently confirm the relevant pass names
and saturation rewrite on the selected toolchain. The corresponding sources in
the [`llvmorg-23.1.6` tag](https://github.com/llvm/llvm-project/tree/llvmorg-23.1.6)
are [`LoopFuse.cpp`](https://github.com/llvm/llvm-project/blob/llvmorg-23.1.6/llvm/lib/Transforms/Scalar/LoopFuse.cpp),
[`LoopUnrollAndJamPass.cpp`](https://github.com/llvm/llvm-project/blob/llvmorg-23.1.6/llvm/lib/Transforms/Scalar/LoopUnrollAndJamPass.cpp),
and [`AggressiveInstCombine.cpp`](https://github.com/llvm/llvm-project/blob/llvmorg-23.1.6/llvm/lib/Transforms/AggressiveInstCombine/AggressiveInstCombine.cpp).
The web retrieval tool could not open the tagged GitHub source pages, so I did
not inspect those source bodies; the source links identify the exact tagged
files, while the installed 23.1.6 binary probes above establish the overlap
observations used for this decision.

## Next research step

Do not start a custom transform from the current evidence. If pursuing a new
candidate, the smallest focused study is the saturating conversion workload
described above: the current suite cannot expose conversion canonicalization,
and an existing LLVM pass already recognizes one relevant IR pattern. The
study should first establish whether real source IR reaches that pattern and
whether the standard pipeline leaves a reproducible code-generation gap.

If runtime performance is the proposed benefit, collect controlled local
measurements on the same M1 Pro with identical inputs and flags, warmups,
repeated runs, and summarized variability. Keep timing out of CI and make no
performance claim until the result is repeatable. Correctness and IR legality
must be established independently of timing.
