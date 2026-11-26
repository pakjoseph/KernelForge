; ModuleID = 'kernelforge-saxpy.report-input.ll'
source_filename = "kernels/saxpy.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress noinline nounwind ssp uwtable(sync)
define void @kernelforge_saxpy(i64 noundef %0, float noundef %1, ptr noalias noundef %2, ptr noalias noundef %3, ptr noalias noundef %4) #0 {
  br label %6

6:                                                ; preds = %15, %5
  %.0 = phi i64 [ 0, %5 ], [ %16, %15 ]
  %7 = icmp ult i64 %.0, %0
  br i1 %7, label %8, label %17

8:                                                ; preds = %6
  %9 = getelementptr inbounds nuw float, ptr %2, i64 %.0
  %10 = load float, ptr %9, align 4
  %11 = getelementptr inbounds nuw float, ptr %3, i64 %.0
  %12 = load float, ptr %11, align 4
  %13 = call float @llvm.fmuladd.f32(float %1, float %10, float %12)
  %14 = getelementptr inbounds nuw float, ptr %4, i64 %.0
  store float %13, ptr %14, align 4
  br label %15

15:                                               ; preds = %8
  %16 = add i64 %.0, 1
  br label %6, !llvm.loop !5

17:                                               ; preds = %6
  ret void
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #1

attributes #0 = { mustprogress noinline nounwind ssp uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-a14" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #1 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 5]}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 4}
!4 = !{!"Homebrew clang version 23.1.6"}
!5 = distinct !{!5, !6}
!6 = !{!"llvm.loop.mustprogress"}
