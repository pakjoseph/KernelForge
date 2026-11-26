# RV64V saturating conversion experiment

This experiment ports the M3a conversion contract to freestanding inputs so
LLVM can cross-compile without a RISC-V C/C++ sysroot. `manual_sat_i8.c`
preserves the M3a NaN check, floating-point clamps, and signed 8-bit cast.
`intrinsic_sat_i8.ll` uses LLVM's explicit `llvm.fptosi.sat` intrinsic with the
same loop bounds, pointer assumptions, and element types.

On RV64, `unsigned long` is 64 bits and `signed char` is one byte. Compile-time
assertions check those assumptions. The compiler command spells the requested
triple `riscv64-unknown-elf`; Clang normalizes the emitted IR triple to
`riscv64-unknown-unknown-elf`.

Regenerate the O2/O3 LLVM IR, remarks, assembly, verified object disassemblies,
scalar-only comparison assembly, and static vector loop-body instruction
counts from the repository root:

```sh
python3 experiments/riscv/generate.py
```

The generator requires the already installed LLVM/Clang 23.1.6 tools and checks
their versions. It uses `-march=rv64gcv -mabi=lp64d -fno-fast-math`; assembly
generation does not use a RISC-V sysroot. Scalar-only assembly adds
`-fno-vectorize -fno-slp-vectorize` to expose scalar conversion lowering.
`run_qemu.py` is a separate optional freestanding correctness check using the
installed QEMU system emulator and RISC-V linker. It reports emulator results
only and does not time the kernels.

All compiler artifacts are placed under
`artifacts/m3b/llvm-23.1.6-rv64gcv-lp64d/`.
