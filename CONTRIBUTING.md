# Contributing to KernelForge

## Toolchain

Use LLVM and Clang **23.1.6**. The CMake configuration rejects other LLVM
versions so that API and output comparisons remain tied to the recorded
toolchain. See the repository [README](README.md) for setup and build commands.

## Verification

For changes to the plugin, build and run the project checks:

```sh
cmake --build build
ctest --test-dir build --output-on-failure
```

For changes to the M3b RV64V experiment, regenerate the compiler artifacts and
run the optional functional harness when its preinstalled linker and QEMU are
available:

```sh
python3 experiments/riscv/generate.py
python3 experiments/riscv/run_qemu.py
```

Record the commands, tool versions, target, and flags for new compiler-output
evidence. Keep compiler output, correctness validation, and timing results
distinct. Do not describe vectorization or static instruction counts as proof
of speed, dependence safety, or vectorizability. Performance claims require
repeatable measurements on the stated hardware; emulator execution is
functional validation only.

## Scope

Keep `kernel-access-report` read-only and conservative. Alias-query results do
not establish iteration-level dependence safety. Add a custom optimization
only after documenting the gap against LLVM's standard pipeline, its legality
conditions, and regression coverage.
