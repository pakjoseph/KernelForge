; ModuleID = 'kernelforge-stencil.report-input.ll'
source_filename = "kernels/stencil.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress noinline nounwind ssp uwtable(sync)
define void @kernelforge_stencil(i64 noundef %0, ptr noalias noundef %1, ptr noalias noundef %2) #0 {
  %4 = icmp eq i64 %0, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %3
  br label %37

6:                                                ; preds = %3
  %7 = getelementptr inbounds float, ptr %1, i64 0
  %8 = load float, ptr %7, align 4
  %9 = getelementptr inbounds float, ptr %2, i64 0
  store float %8, ptr %9, align 4
  %10 = icmp eq i64 %0, 1
  br i1 %10, label %11, label %12

11:                                               ; preds = %6
  br label %37

12:                                               ; preds = %6
  br label %13

13:                                               ; preds = %29, %12
  %.0 = phi i64 [ 1, %12 ], [ %30, %29 ]
  %14 = sub i64 %0, 1
  %15 = icmp ult i64 %.0, %14
  br i1 %15, label %16, label %31

16:                                               ; preds = %13
  %17 = sub i64 %.0, 1
  %18 = getelementptr inbounds nuw float, ptr %1, i64 %17
  %19 = load float, ptr %18, align 4
  %20 = getelementptr inbounds nuw float, ptr %1, i64 %.0
  %21 = load float, ptr %20, align 4
  %22 = fadd float %19, %21
  %23 = add i64 %.0, 1
  %24 = getelementptr inbounds nuw float, ptr %1, i64 %23
  %25 = load float, ptr %24, align 4
  %26 = fadd float %22, %25
  %27 = fdiv float %26, 3.000000e+00
  %28 = getelementptr inbounds nuw float, ptr %2, i64 %.0
  store float %27, ptr %28, align 4
  br label %29

29:                                               ; preds = %16
  %30 = add i64 %.0, 1
  br label %13, !llvm.loop !5

31:                                               ; preds = %13
  %32 = sub i64 %0, 1
  %33 = getelementptr inbounds nuw float, ptr %1, i64 %32
  %34 = load float, ptr %33, align 4
  %35 = sub i64 %0, 1
  %36 = getelementptr inbounds nuw float, ptr %2, i64 %35
  store float %34, ptr %36, align 4
  br label %37

37:                                               ; preds = %31, %11, %5
  ret void
}

attributes #0 = { mustprogress noinline nounwind ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-a14" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 5]}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 4}
!4 = !{!"Homebrew clang version 23.1.6"}
!5 = distinct !{!5, !6}
!6 = !{!"llvm.loop.mustprogress"}
