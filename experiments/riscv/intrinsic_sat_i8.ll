; Explicit-intrinsic version of the M3a scalar loop.
source_filename = "intrinsic_sat_i8.ll"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

define void @kernelforge_sat_i8_intrinsic(i64 %n, ptr noalias readonly %input,
                                          ptr noalias writeonly %output) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %body ]
  %more = icmp ult i64 %i, %n
  br i1 %more, label %body, label %exit

body:
  %in.ptr = getelementptr float, ptr %input, i64 %i
  %x = load float, ptr %in.ptr, align 4
  %converted = call i8 @llvm.fptosi.sat.i8.f32(float %x)
  %out.ptr = getelementptr i8, ptr %output, i64 %i
  store i8 %converted, ptr %out.ptr, align 1
  %next = add nuw i64 %i, 1
  br label %loop

exit:
  ret void
}

declare i8 @llvm.fptosi.sat.i8.f32(float)
