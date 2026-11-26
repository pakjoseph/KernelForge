# M3b: RV64V saturating conversion validation

## Decision

**RVV code generation validates this as a useful backend study.** LLVM 23.1.6
accepts the ratified vector target and emits meaningfully different scalar and
vector sequences for the manual conversion and `llvm.fptosi.sat` forms. This
does not establish a runtime benefit or justify implementing a custom
canonicalization pass. M3a's runtime-evidence requirement remains open.

## Evidence reviewed

- M3a design gate: [docs/m3-design-gate.md](m3-design-gate.md).
- M2 baseline summary and machine/tool metadata: [docs/m2-baseline.md](m2-baseline.md)
  and `artifacts/m2/llvm-23.1.6-apple-m1/metadata.json`.
- The M3a scratch sources were present at `/private/tmp/kernelforge-m3a.EkNveV`
  and inspected. The experiment uses a small freestanding C/LLVM IR version of
  that documented conversion contract because direct C++ cross-compilation
  needs a RISC-V C++ sysroot that is not installed.
- Inputs and rerun instructions: [experiments/riscv/README.md](../experiments/riscv/README.md).
- Generator and correctness harness: `experiments/riscv/generate.py`,
  `experiments/riscv/run_qemu.py`, `experiments/riscv/correctness.c`, and
  `experiments/riscv/start.S`.
- Generated LLVM IR, remarks, assembly, disassembly, command metadata, and QEMU
  results: `artifacts/m3b/llvm-23.1.6-rv64gcv-lp64d/`.

M2's recorded machine is a MacBook Pro 18,3 with Apple M1 Pro, running macOS
26.6.2. The M3b cross-compilation host metadata reports macOS 26.6.2 arm64.
LLVM tools resolved from `/opt/homebrew/opt/llvm` identify as 23.1.6:
`clang`, `opt`, `llvm-as`, `llvm-mc`, `llvm-objdump`, and `llvm-config`.
Commands use `-target riscv64-unknown-elf -march=rv64gcv -mabi=lp64d` and
`-fno-fast-math`; Clang emits the normalized IR triple
`riscv64-unknown-unknown-elf`. No RISC-V sysroot was used for the compiler
output experiment.

## Workload and semantics

Both variants read `n` `float` values and write `n` signed 8-bit results. The
manual form checks NaN, clamps to `[-128, 127]`, then performs an in-range
conversion that truncates toward zero. The explicit form uses
`llvm.fptosi.sat.i8.f32`, with the same NaN-to-zero, saturation, and
round-toward-zero contract. Both inputs declare non-aliasing input/output
pointers; this is a harness precondition.

The hand-derived cases include finite values inside and outside the range,
positive and negative infinity, positive and negative large finite overflow,
the adjacent representable `float` values around both endpoints, fractions,
positive and negative zero, and NaN. The manual C code does not use an
out-of-range cast as an oracle: it checks NaN and clamps before casting.
Ordinary LLVM `fptosi` has poison behavior for NaN or an out-of-range source;
the explicit saturating intrinsic defines clamping and NaN handling. These
forms must not be treated as interchangeable unless the manual guards remain
part of the semantics.

The QEMU harness checks hand-written expected bytes rather than deriving its
expected result through either implementation. It tests sizes `0, 1, 2, 3, 4,
5, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64, 65, 257, 4097`. At size zero it
also calls both kernels with null pointers to check that no memory access is
performed.

## Compiler output

At both O2 and O3, LLVM reports vectorization width `vscale x 4` with
interleave count 1 for both variants. The explicit intrinsic's vector IR
contains `llvm.fptosi.sat.nxv4i8.nxv4f32`; the manual vector IR retains ordered
comparisons, selects, `fptosi`, and a NaN-to-zero select. The remarks are saved
in `remarks/` and optimized IR in `ir/`.

With loop and SLP vectorization disabled for the separate scalar comparison,
the manual sequence uses `feq.s` for the NaN check, ordered `flt.s` comparisons
and conditional branches plus `fmv.s` operations for the clamps, `fcvt.l.s`
with `rtz`, then `sb`. The intrinsic sequence uses `fmax.s`, `fmin.s`, `feq.s`,
`fcvt.l.s` with `rtz`, an
integer mask to map NaN to zero, then `sb`. The complete scalar assembly is
saved as `assembly/*.scalar.O2.s` and `assembly/*.scalar.O3.s`.

In vector assembly, the manual form loads with `vle32.v`, clamps using
`vmfgt.vf`/`vmerge.vxm` and `vmflt.vf`/`vmerge.vxm`, detects NaN with
`vmfne.vv`, converts with `vfncvt.rtz.x.f.w`, narrows with `vnsrl.wi` after
clamping, selects zero for NaNs with `vmerge.vim`, then stores with `vse8.v`.
The intrinsic form uses `vmfne.vv`, `vfncvt.rtz.x.f.w`, saturating narrow
`vnclip.wi`, NaN zeroing via `vmerge.vim`, and `vse8.v`. Its saved IR retains
the vector saturating intrinsic before lowering.

Both vector loops use `vsetvli` with the remaining element count as AVL and
advance by the returned VL. LLVM's vector length remark is scalable; at the
QEMU configuration `VLEN=128`, `e32,m2` has VLMAX 8, so one loop iteration
handles up to 8 outputs. The final iteration uses the remaining VL, and the
loop exits when the remaining count reaches zero. The assembly has no separate
scalar conversion tail. For `n=0`, a scalar zero-count branch skips the loop.

The static count from the annotated vector loop header through its conditional
backedge is:

| Form | O2 | O3 |
| --- | ---: | ---: |
| Manual clamp/select | 20 instructions | 20 instructions |
| `llvm.fptosi.sat` | 15 instructions | 15 instructions |

The count excludes setup before the loop and includes pointer/index arithmetic,
vector configuration, and the backedge. It is a static assembly count per loop
iteration, not a dynamic instruction count, cycle estimate, or performance
claim. Full assembly and disassemblies are in `assembly/` and `disassembly/`.

## Functional validation and execution limits

`python3 experiments/riscv/generate.py` completed successfully. It checked all
listed LLVM tool versions, verified the optimized IR with `opt -passes=verify`,
assembled each vector and scalar assembly file with LLVM 23.1.6 `llvm-mc`, and
saved `llvm-objdump` output.

`python3 experiments/riscv/run_qemu.py` completed successfully at O2 and O3.
The freestanding executable tested both conversion forms and the documented
sizes/cases under QEMU 10.2.1, `virt`, `rv64,v=true,vlen=128,elen=64`, using GNU
ld 2.45. Both runs exited 0. The commands and tool versions are recorded in
`functional-validation.txt`. QEMU here establishes functional behavior for
this configured emulator; it is not hardware execution or performance data.

No RISC-V hardware run was available. No runtime timing was collected, on QEMU
or hardware. No performance improvement is claimed. The experiment did not
change the M1 pass, M2 baselines, or implement a custom pass.

## Next step

Keep the custom canonicalization on hold. The smallest next step for M3a's
runtime question is a controlled A/B measurement on the M1 Pro using the
existing AArch64 workload and pinned compiler, with warmups, repeated
alternating runs, deterministic inputs, and checksums. RVV code shape does not
answer whether either form is faster on the M1 Pro. If that study does not show
a repeatable effect or a separate correctness-relevant gap, pivot to further
backend validation without adding a custom optimization.

## Commands

Run from the repository root:

```sh
python3 experiments/riscv/generate.py
python3 experiments/riscv/run_qemu.py
```

Exact individual compiler and verification command arrays are stored in
`artifacts/m3b/llvm-23.1.6-rv64gcv-lp64d/metadata.json`.
