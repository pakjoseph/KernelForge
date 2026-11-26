# LLVM 23.1.6 RV64V conversion artifacts

This directory contains O2/O3 optimized LLVM IR, vectorization remarks, RV64V
assembly, scalar-only comparison assembly, and `llvm-objdump` disassemblies
for the manual and explicit `llvm.fptosi.sat` forms. `metadata.json` records
LLVM tool versions, target and ABI flags, exact generator command arrays,
vector loop-body instruction counts, and the counting method.
`functional-validation.txt` records the separate QEMU correctness run. No
performance measurements are included.

Regenerate compiler artifacts with `python3 experiments/riscv/generate.py` and
functional results with `python3 experiments/riscv/run_qemu.py` from the
repository root. The generated code is for the cross-compile target and does
not use a RISC-V sysroot.
