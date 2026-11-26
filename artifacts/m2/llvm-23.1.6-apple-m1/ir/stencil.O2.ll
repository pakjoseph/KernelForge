; ModuleID = 'kernelforge-stencil.O2.ll'
source_filename = "kernels/stencil.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync)
define void @kernelforge_stencil(i64 noundef %0, ptr noalias nofree noundef readonly captures(none) %1, ptr noalias nofree noundef writeonly captures(none) %2) local_unnamed_addr #0 {
  %4 = icmp eq i64 %0, 0
  br i1 %4, label %88, label %5

5:                                                ; preds = %3
  %6 = load float, ptr %1, align 4, !tbaa !10
  store float %6, ptr %2, align 4, !tbaa !10
  %7 = icmp eq i64 %0, 1
  br i1 %7, label %88, label %8

8:                                                ; preds = %5
  %9 = add i64 %0, -1
  %10 = icmp ugt i64 %9, 1
  br i1 %10, label %11, label %70

11:                                               ; preds = %8
  %12 = getelementptr i8, ptr %1, i64 4
  %13 = load float, ptr %12, align 4, !tbaa !10
  %14 = add i64 %0, -2
  %15 = icmp ult i64 %14, 16
  br i1 %15, label %67, label %16

16:                                               ; preds = %11
  %17 = and i64 %14, -16
  %18 = or disjoint i64 %17, 1
  %19 = insertelement <4 x float> poison, float %13, i64 3
  br label %20

20:                                               ; preds = %20, %16
  %21 = phi i64 [ 0, %16 ], [ %62, %20 ]
  %22 = phi <4 x float> [ %19, %16 ], [ %41, %20 ]
  %23 = or disjoint i64 %21, 1
  %24 = getelementptr [4 x i8], ptr %1, i64 %23
  %25 = getelementptr i8, ptr %24, i64 -4
  %26 = getelementptr i8, ptr %24, i64 12
  %27 = getelementptr i8, ptr %24, i64 28
  %28 = getelementptr i8, ptr %24, i64 44
  %29 = load <4 x float>, ptr %25, align 4, !tbaa !10
  %30 = load <4 x float>, ptr %26, align 4, !tbaa !10
  %31 = load <4 x float>, ptr %27, align 4, !tbaa !10
  %32 = load <4 x float>, ptr %28, align 4, !tbaa !10
  %33 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %21
  %34 = getelementptr inbounds nuw i8, ptr %33, i64 8
  %35 = getelementptr inbounds nuw i8, ptr %33, i64 24
  %36 = getelementptr inbounds nuw i8, ptr %33, i64 40
  %37 = getelementptr inbounds nuw i8, ptr %33, i64 56
  %38 = load <4 x float>, ptr %34, align 4, !tbaa !10
  %39 = load <4 x float>, ptr %35, align 4, !tbaa !10
  %40 = load <4 x float>, ptr %36, align 4, !tbaa !10
  %41 = load <4 x float>, ptr %37, align 4, !tbaa !10
  %42 = shufflevector <4 x float> %22, <4 x float> %38, <4 x i32> <i32 3, i32 4, i32 5, i32 6>
  %43 = shufflevector <4 x float> %38, <4 x float> %39, <4 x i32> <i32 3, i32 4, i32 5, i32 6>
  %44 = shufflevector <4 x float> %39, <4 x float> %40, <4 x i32> <i32 3, i32 4, i32 5, i32 6>
  %45 = shufflevector <4 x float> %40, <4 x float> %41, <4 x i32> <i32 3, i32 4, i32 5, i32 6>
  %46 = fadd <4 x float> %29, %42
  %47 = fadd <4 x float> %30, %43
  %48 = fadd <4 x float> %31, %44
  %49 = fadd <4 x float> %32, %45
  %50 = fadd <4 x float> %46, %38
  %51 = fadd <4 x float> %47, %39
  %52 = fadd <4 x float> %48, %40
  %53 = fadd <4 x float> %49, %41
  %54 = fdiv <4 x float> %50, splat (float 3.000000e+00)
  %55 = fdiv <4 x float> %51, splat (float 3.000000e+00)
  %56 = fdiv <4 x float> %52, splat (float 3.000000e+00)
  %57 = fdiv <4 x float> %53, splat (float 3.000000e+00)
  %58 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %23
  %59 = getelementptr inbounds nuw i8, ptr %58, i64 16
  %60 = getelementptr inbounds nuw i8, ptr %58, i64 32
  %61 = getelementptr inbounds nuw i8, ptr %58, i64 48
  store <4 x float> %54, ptr %58, align 4, !tbaa !10
  store <4 x float> %55, ptr %59, align 4, !tbaa !10
  store <4 x float> %56, ptr %60, align 4, !tbaa !10
  store <4 x float> %57, ptr %61, align 4, !tbaa !10
  %62 = add nuw i64 %21, 16
  %63 = icmp eq i64 %62, %17
  br i1 %63, label %64, label %20, !llvm.loop !12

64:                                               ; preds = %20
  %65 = extractelement <4 x float> %41, i64 3
  %66 = icmp eq i64 %14, %17
  br i1 %66, label %70, label %67

67:                                               ; preds = %11, %64
  %68 = phi float [ %13, %11 ], [ %65, %64 ]
  %69 = phi i64 [ 1, %11 ], [ %18, %64 ]
  br label %74

70:                                               ; preds = %74, %64, %8
  %71 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %9
  %72 = load float, ptr %71, align 4, !tbaa !10
  %73 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %9
  store float %72, ptr %73, align 4, !tbaa !10
  br label %88

74:                                               ; preds = %67, %74
  %75 = phi float [ %83, %74 ], [ %68, %67 ]
  %76 = phi i64 [ %81, %74 ], [ %69, %67 ]
  %77 = getelementptr [4 x i8], ptr %1, i64 %76
  %78 = getelementptr i8, ptr %77, i64 -4
  %79 = load float, ptr %78, align 4, !tbaa !10
  %80 = fadd float %79, %75
  %81 = add nuw i64 %76, 1
  %82 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %81
  %83 = load float, ptr %82, align 4, !tbaa !10
  %84 = fadd float %80, %83
  %85 = fdiv float %84, 3.000000e+00
  %86 = getelementptr inbounds nuw [4 x i8], ptr %2, i64 %76
  store float %85, ptr %86, align 4, !tbaa !10
  %87 = icmp eq i64 %81, %9
  br i1 %87, label %70, label %74, !llvm.loop !16

88:                                               ; preds = %5, %3, %70
  ret void
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-a14" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }

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
!16 = distinct !{!16, !13, !15, !14}
