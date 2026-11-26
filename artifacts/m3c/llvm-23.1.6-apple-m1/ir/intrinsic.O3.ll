; ModuleID = '/Users/josephpak/KernelForge/experiments/aarch64/m3c/intrinsic_kernel.ll'
source_filename = "intrinsic_kernel.ll"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: nofree noinline norecurse nosync nounwind memory(argmem: readwrite)
define void @kernelforge_sat_i8_intrinsic(i64 %n, ptr noalias readonly captures(none) %input, ptr noalias nofree writeonly captures(none) %output) local_unnamed_addr #0 {
entry:
  %more1.not = icmp eq i64 %n, 0
  br i1 %more1.not, label %exit, label %iter.check

iter.check:                                       ; preds = %entry
  %min.iters.check = icmp ult i64 %n, 4
  br i1 %min.iters.check, label %body.preheader, label %vector.main.loop.iter.check

vector.main.loop.iter.check:                      ; preds = %iter.check
  %min.iters.check3 = icmp ult i64 %n, 64
  br i1 %min.iters.check3, label %vec.epilog.ph, label %vector.ph

vector.ph:                                        ; preds = %vector.main.loop.iter.check
  %n.mod.vf = and i64 %n, 60
  %n.vec = and i64 %n, -64
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %0 = getelementptr [4 x i8], ptr %input, i64 %index
  %1 = getelementptr i8, ptr %0, i64 64
  %2 = getelementptr i8, ptr %0, i64 128
  %3 = getelementptr i8, ptr %0, i64 192
  %wide.load = load <16 x float>, ptr %0, align 4
  %wide.load4 = load <16 x float>, ptr %1, align 4
  %wide.load5 = load <16 x float>, ptr %2, align 4
  %wide.load6 = load <16 x float>, ptr %3, align 4
  %4 = tail call <16 x i8> @llvm.fptosi.sat.v16i8.v16f32(<16 x float> %wide.load)
  %5 = tail call <16 x i8> @llvm.fptosi.sat.v16i8.v16f32(<16 x float> %wide.load4)
  %6 = tail call <16 x i8> @llvm.fptosi.sat.v16i8.v16f32(<16 x float> %wide.load5)
  %7 = tail call <16 x i8> @llvm.fptosi.sat.v16i8.v16f32(<16 x float> %wide.load6)
  %8 = getelementptr i8, ptr %output, i64 %index
  %9 = getelementptr i8, ptr %8, i64 16
  %10 = getelementptr i8, ptr %8, i64 32
  %11 = getelementptr i8, ptr %8, i64 48
  store <16 x i8> %4, ptr %8, align 1
  store <16 x i8> %5, ptr %9, align 1
  store <16 x i8> %6, ptr %10, align 1
  store <16 x i8> %7, ptr %11, align 1
  %index.next = add nuw i64 %index, 64
  %12 = icmp eq i64 %index.next, %n.vec
  br i1 %12, label %middle.block, label %vector.body, !llvm.loop !0

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %n, %n.vec
  br i1 %cmp.n, label %exit, label %vec.epilog.iter.check

vec.epilog.iter.check:                            ; preds = %middle.block
  %min.epilog.iters.check = icmp eq i64 %n.mod.vf, 0
  br i1 %min.epilog.iters.check, label %body.preheader, label %vec.epilog.ph, !prof !4

vec.epilog.ph:                                    ; preds = %vector.main.loop.iter.check, %vec.epilog.iter.check
  %vec.epilog.resume.val = phi i64 [ %n.vec, %vec.epilog.iter.check ], [ 0, %vector.main.loop.iter.check ]
  %n.vec8 = and i64 %n, -4
  br label %vec.epilog.vector.body

vec.epilog.vector.body:                           ; preds = %vec.epilog.vector.body, %vec.epilog.ph
  %index9 = phi i64 [ %vec.epilog.resume.val, %vec.epilog.ph ], [ %index.next11, %vec.epilog.vector.body ]
  %13 = getelementptr [4 x i8], ptr %input, i64 %index9
  %wide.load10 = load <4 x float>, ptr %13, align 4
  %14 = tail call <4 x i8> @llvm.fptosi.sat.v4i8.v4f32(<4 x float> %wide.load10)
  %15 = getelementptr i8, ptr %output, i64 %index9
  store <4 x i8> %14, ptr %15, align 1
  %index.next11 = add nuw i64 %index9, 4
  %16 = icmp eq i64 %index.next11, %n.vec8
  br i1 %16, label %vec.epilog.middle.block, label %vec.epilog.vector.body, !llvm.loop !5

vec.epilog.middle.block:                          ; preds = %vec.epilog.vector.body
  %cmp.n12 = icmp eq i64 %n, %n.vec8
  br i1 %cmp.n12, label %exit, label %body.preheader

body.preheader:                                   ; preds = %iter.check, %vec.epilog.iter.check, %vec.epilog.middle.block
  %i2.ph = phi i64 [ 0, %iter.check ], [ %n.vec, %vec.epilog.iter.check ], [ %n.vec8, %vec.epilog.middle.block ]
  br label %body

body:                                             ; preds = %body.preheader, %body
  %i2 = phi i64 [ %next, %body ], [ %i2.ph, %body.preheader ]
  %in.ptr = getelementptr [4 x i8], ptr %input, i64 %i2
  %x = load float, ptr %in.ptr, align 4
  %converted = tail call i8 @llvm.fptosi.sat.i8.f32(float %x)
  %out.ptr = getelementptr i8, ptr %output, i64 %i2
  store i8 %converted, ptr %out.ptr, align 1
  %next = add nuw i64 %i2, 1
  %exitcond.not = icmp eq i64 %next, %n
  br i1 %exitcond.not, label %exit, label %body, !llvm.loop !7

exit:                                             ; preds = %body, %middle.block, %vec.epilog.middle.block, %entry
  ret void
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i8 @llvm.fptosi.sat.i8.f32(float) #1

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <16 x i8> @llvm.fptosi.sat.v16i8.v16f32(<16 x float>) #2

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x i8> @llvm.fptosi.sat.v4i8.v4f32(<4 x float>) #2

attributes #0 = { nofree noinline norecurse nosync nounwind memory(argmem: readwrite) }
attributes #1 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!0 = distinct !{!0, !1, !2, !3}
!1 = !{!"llvm.loop.isvectorized", i32 1}
!2 = !{!"llvm.loop.vectorize.body", i32 1}
!3 = !{!"llvm.loop.unroll.runtime.disable"}
!4 = !{!"branch_weights", i32 4, i32 60}
!5 = distinct !{!5, !1, !6, !2, !3}
!6 = !{!"llvm.loop.vectorize.epilogue", i32 1}
!7 = distinct !{!7, !3, !1, !6, !6}
