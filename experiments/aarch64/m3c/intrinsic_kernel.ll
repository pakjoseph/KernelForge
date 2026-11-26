; Explicit llvm.fptosi.sat form corresponding to manual_kernel.cpp.
source_filename = "intrinsic_kernel.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-darwin25.6.0"

define void @kernelforge_sat_i8_intrinsic(i64 %n, ptr noalias readonly %input,
                                          ptr noalias writeonly %output) #0 {
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

attributes #0 = { noinline nounwind }
