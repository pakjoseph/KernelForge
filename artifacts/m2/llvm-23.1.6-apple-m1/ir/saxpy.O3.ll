; ModuleID = 'kernelforge-saxpy.O3.ll'
source_filename = "kernels/saxpy.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync)
define void @kernelforge_saxpy(i64 noundef %0, float noundef %1, ptr noalias nofree noundef readonly captures(none) %2, ptr noalias nofree noundef readonly captures(none) %3, ptr noalias nofree noundef writeonly captures(none) %4) local_unnamed_addr #0 {
  %6 = icmp eq i64 %0, 0
  br i1 %6, label %67, label %7

7:                                                ; preds = %5
  %8 = icmp ult i64 %0, 4
  br i1 %8, label %65, label %9

9:                                                ; preds = %7
  %10 = icmp ult i64 %0, 16
  br i1 %10, label %48, label %11

11:                                               ; preds = %9
  %12 = and i64 %0, 12
  %13 = and i64 %0, -16
  %14 = insertelement <4 x float> poison, float %1, i64 0
  %15 = shufflevector <4 x float> %14, <4 x float> poison, <4 x i32> zeroinitializer
  br label %16

16:                                               ; preds = %16, %11
  %17 = phi i64 [ 0, %11 ], [ %42, %16 ]
  %18 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %17
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 16
  %20 = getelementptr inbounds nuw i8, ptr %18, i64 32
  %21 = getelementptr inbounds nuw i8, ptr %18, i64 48
  %22 = load <4 x float>, ptr %18, align 4, !tbaa !10
  %23 = load <4 x float>, ptr %19, align 4, !tbaa !10
  %24 = load <4 x float>, ptr %20, align 4, !tbaa !10
  %25 = load <4 x float>, ptr %21, align 4, !tbaa !10
  %26 = getelementptr inbounds nuw [4 x i8], ptr %3, i64 %17
  %27 = getelementptr inbounds nuw i8, ptr %26, i64 16
  %28 = getelementptr inbounds nuw i8, ptr %26, i64 32
  %29 = getelementptr inbounds nuw i8, ptr %26, i64 48
  %30 = load <4 x float>, ptr %26, align 4, !tbaa !10
  %31 = load <4 x float>, ptr %27, align 4, !tbaa !10
  %32 = load <4 x float>, ptr %28, align 4, !tbaa !10
  %33 = load <4 x float>, ptr %29, align 4, !tbaa !10
  %34 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %15, <4 x float> %22, <4 x float> %30)
  %35 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %15, <4 x float> %23, <4 x float> %31)
  %36 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %15, <4 x float> %24, <4 x float> %32)
  %37 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %15, <4 x float> %25, <4 x float> %33)
  %38 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %17
  %39 = getelementptr inbounds nuw i8, ptr %38, i64 16
  %40 = getelementptr inbounds nuw i8, ptr %38, i64 32
  %41 = getelementptr inbounds nuw i8, ptr %38, i64 48
  store <4 x float> %34, ptr %38, align 4, !tbaa !10
  store <4 x float> %35, ptr %39, align 4, !tbaa !10
  store <4 x float> %36, ptr %40, align 4, !tbaa !10
  store <4 x float> %37, ptr %41, align 4, !tbaa !10
  %42 = add nuw i64 %17, 16
  %43 = icmp eq i64 %42, %13
  br i1 %43, label %44, label %16, !llvm.loop !12

44:                                               ; preds = %16
  %45 = icmp eq i64 %0, %13
  br i1 %45, label %67, label %46

46:                                               ; preds = %44
  %47 = icmp eq i64 %12, 0
  br i1 %47, label %65, label %48, !prof !16

48:                                               ; preds = %9, %46
  %49 = phi i64 [ %13, %46 ], [ 0, %9 ]
  %50 = and i64 %0, -4
  %51 = insertelement <4 x float> poison, float %1, i64 0
  %52 = shufflevector <4 x float> %51, <4 x float> poison, <4 x i32> zeroinitializer
  br label %53

53:                                               ; preds = %53, %48
  %54 = phi i64 [ %49, %48 ], [ %61, %53 ]
  %55 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %54
  %56 = load <4 x float>, ptr %55, align 4, !tbaa !10
  %57 = getelementptr inbounds nuw [4 x i8], ptr %3, i64 %54
  %58 = load <4 x float>, ptr %57, align 4, !tbaa !10
  %59 = tail call <4 x float> @llvm.fmuladd.v4f32(<4 x float> %52, <4 x float> %56, <4 x float> %58)
  %60 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %54
  store <4 x float> %59, ptr %60, align 4, !tbaa !10
  %61 = add nuw i64 %54, 4
  %62 = icmp eq i64 %61, %50
  br i1 %62, label %63, label %53, !llvm.loop !17

63:                                               ; preds = %53
  %64 = icmp eq i64 %0, %50
  br i1 %64, label %67, label %65

65:                                               ; preds = %7, %46, %63
  %66 = phi i64 [ 0, %7 ], [ %13, %46 ], [ %50, %63 ]
  br label %68

67:                                               ; preds = %68, %44, %63, %5
  ret void

68:                                               ; preds = %65, %68
  %69 = phi i64 [ %76, %68 ], [ %66, %65 ]
  %70 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %69
  %71 = load float, ptr %70, align 4, !tbaa !10
  %72 = getelementptr inbounds nuw [4 x i8], ptr %3, i64 %69
  %73 = load float, ptr %72, align 4, !tbaa !10
  %74 = tail call float @llvm.fmuladd.f32(float %1, float %71, float %73)
  %75 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 %69
  store float %74, ptr %75, align 4, !tbaa !10
  %76 = add nuw i64 %69, 1
  %77 = icmp eq i64 %76, %0
  br i1 %77, label %67, label %68, !llvm.loop !18
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #1

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x float> @llvm.fmuladd.v4f32(<4 x float>, <4 x float>, <4 x float>) #2

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-a14" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }
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
