; ModuleID = 'kernelforge-dot.O3.ll'
source_filename = "kernels/dot.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync)
define float @kernelforge_dot(i64 noundef %0, ptr nofree noundef readonly captures(none) %1, ptr nofree noundef readonly captures(none) %2) local_unnamed_addr #0 {
  %4 = icmp eq i64 %0, 0
  br i1 %4, label %65, label %5

5:                                                ; preds = %3
  %6 = icmp ult i64 %0, 4
  br i1 %6, label %62, label %7

7:                                                ; preds = %5
  %8 = icmp ult i64 %0, 16
  br i1 %8, label %45, label %9

9:                                                ; preds = %7
  %10 = and i64 %0, 12
  %11 = and i64 %0, -16
  br label %12

12:                                               ; preds = %12, %9
  %13 = phi i64 [ 0, %9 ], [ %39, %12 ]
  %14 = phi float [ 0.000000e+00, %9 ], [ %38, %12 ]
  %15 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %13
  %16 = getelementptr inbounds nuw i8, ptr %15, i64 16
  %17 = getelementptr inbounds nuw i8, ptr %15, i64 32
  %18 = getelementptr inbounds nuw i8, ptr %15, i64 48
  %19 = load <4 x float>, ptr %15, align 4, !tbaa !10
  %20 = load <4 x float>, ptr %16, align 4, !tbaa !10
  %21 = load <4 x float>, ptr %17, align 4, !tbaa !10
  %22 = load <4 x float>, ptr %18, align 4, !tbaa !10
  %23 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %13
  %24 = getelementptr inbounds nuw i8, ptr %23, i64 16
  %25 = getelementptr inbounds nuw i8, ptr %23, i64 32
  %26 = getelementptr inbounds nuw i8, ptr %23, i64 48
  %27 = load <4 x float>, ptr %23, align 4, !tbaa !10
  %28 = load <4 x float>, ptr %24, align 4, !tbaa !10
  %29 = load <4 x float>, ptr %25, align 4, !tbaa !10
  %30 = load <4 x float>, ptr %26, align 4, !tbaa !10
  %31 = fmul <4 x float> %19, %27
  %32 = fmul <4 x float> %20, %28
  %33 = fmul <4 x float> %21, %29
  %34 = fmul <4 x float> %22, %30
  %35 = tail call float @llvm.vector.reduce.fadd.v4f32(float %14, <4 x float> %31)
  %36 = tail call float @llvm.vector.reduce.fadd.v4f32(float %35, <4 x float> %32)
  %37 = tail call float @llvm.vector.reduce.fadd.v4f32(float %36, <4 x float> %33)
  %38 = tail call float @llvm.vector.reduce.fadd.v4f32(float %37, <4 x float> %34)
  %39 = add nuw i64 %13, 16
  %40 = icmp eq i64 %39, %11
  br i1 %40, label %41, label %12, !llvm.loop !12

41:                                               ; preds = %12
  %42 = icmp eq i64 %0, %11
  br i1 %42, label %65, label %43

43:                                               ; preds = %41
  %44 = icmp eq i64 %10, 0
  br i1 %44, label %62, label %45, !prof !16

45:                                               ; preds = %7, %43
  %46 = phi i64 [ %11, %43 ], [ 0, %7 ]
  %47 = phi float [ %38, %43 ], [ 0.000000e+00, %7 ]
  %48 = and i64 %0, -4
  br label %49

49:                                               ; preds = %49, %45
  %50 = phi i64 [ %46, %45 ], [ %58, %49 ]
  %51 = phi float [ %47, %45 ], [ %57, %49 ]
  %52 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %50
  %53 = load <4 x float>, ptr %52, align 4, !tbaa !10
  %54 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %50
  %55 = load <4 x float>, ptr %54, align 4, !tbaa !10
  %56 = fmul <4 x float> %53, %55
  %57 = tail call float @llvm.vector.reduce.fadd.v4f32(float %51, <4 x float> %56)
  %58 = add nuw i64 %50, 4
  %59 = icmp eq i64 %58, %48
  br i1 %59, label %60, label %49, !llvm.loop !17

60:                                               ; preds = %49
  %61 = icmp eq i64 %0, %48
  br i1 %61, label %65, label %62

62:                                               ; preds = %5, %43, %60
  %63 = phi i64 [ 0, %5 ], [ %11, %43 ], [ %48, %60 ]
  %64 = phi float [ 0.000000e+00, %5 ], [ %38, %43 ], [ %57, %60 ]
  br label %67

65:                                               ; preds = %67, %41, %60, %3
  %66 = phi float [ 0.000000e+00, %3 ], [ %57, %60 ], [ %38, %41 ], [ %74, %67 ]
  ret float %66

67:                                               ; preds = %62, %67
  %68 = phi i64 [ %75, %67 ], [ %63, %62 ]
  %69 = phi float [ %74, %67 ], [ %64, %62 ]
  %70 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %68
  %71 = load float, ptr %70, align 4, !tbaa !10
  %72 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %68
  %73 = load float, ptr %72, align 4, !tbaa !10
  %74 = tail call float @llvm.fmuladd.f32(float %71, float %73, float %69)
  %75 = add nuw i64 %68, 1
  %76 = icmp eq i64 %75, %0
  br i1 %76, label %65, label %67, !llvm.loop !18
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.vector.reduce.fadd.v4f32(float, <4 x float>) #2

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-a14" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
attributes #1 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}
!llvm.errno.tbaa = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 5]}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 4}
!4 = !{!"Homebrew clang version 23.1.6"}
!5 = !{!6, !7, i64 0}
!6 = !{!"__libc_errno", !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"float", !8, i64 0}
!12 = distinct !{!12, !13, !14, !15}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.isvectorized", i32 1}
!15 = !{!"llvm.loop.unroll.runtime.disable"}
!16 = !{!"branch_weights", i32 4, i32 12}
!17 = distinct !{!17, !13, !14, !15}
!18 = distinct !{!18, !13, !15, !14}
