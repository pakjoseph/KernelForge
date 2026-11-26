; ModuleID = '/Users/josephpak/KernelForge/artifacts/m3c/llvm-23.1.6-apple-m1/ir/manual.frontend.ll'
source_filename = "/Users/josephpak/KernelForge/experiments/aarch64/m3c/manual_kernel.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress noinline nounwind ssp uwtable(sync)
define void @kernelforge_sat_i8_manual(i64 noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  br label %4

4:                                                ; preds = %21, %3
  %.01 = phi i64 [ 0, %3 ], [ %22, %21 ]
  %5 = icmp ult i64 %.01, %0
  br i1 %5, label %6, label %23

6:                                                ; preds = %4
  %7 = getelementptr inbounds nuw float, ptr %1, i64 %.01
  %8 = load float, ptr %7, align 4
  %9 = fcmp une float %8, %8
  br i1 %9, label %10, label %12

10:                                               ; preds = %6
  %11 = getelementptr inbounds nuw i8, ptr %2, i64 %.01
  store i8 0, ptr %11, align 1
  br label %21

12:                                               ; preds = %6
  %13 = fcmp ogt float %8, 1.270000e+02
  br i1 %13, label %14, label %15

14:                                               ; preds = %12
  br label %15

15:                                               ; preds = %14, %12
  %.0 = phi float [ 1.270000e+02, %14 ], [ %8, %12 ]
  %16 = fcmp olt float %.0, -1.280000e+02
  br i1 %16, label %17, label %18

17:                                               ; preds = %15
  br label %18

18:                                               ; preds = %17, %15
  %.1 = phi float [ -1.280000e+02, %17 ], [ %.0, %15 ]
  %19 = fptosi float %.1 to i8
  %20 = getelementptr inbounds nuw i8, ptr %2, i64 %.01
  store i8 %19, ptr %20, align 1
  br label %21

21:                                               ; preds = %18, %10
  %22 = add i64 %.01, 1
  br label %4, !llvm.loop !5

23:                                               ; preds = %4
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
