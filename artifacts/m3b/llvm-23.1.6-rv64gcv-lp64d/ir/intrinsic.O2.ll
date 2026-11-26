; ModuleID = '/Users/josephpak/KernelForge/experiments/riscv/intrinsic_sat_i8.ll'
source_filename = "intrinsic_sat_i8.ll"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite)
define void @kernelforge_sat_i8_intrinsic(i64 %n, ptr noalias readonly captures(none) %input, ptr noalias nofree writeonly captures(none) %output) local_unnamed_addr #0 {
entry:
  %more1.not = icmp eq i64 %n, 0
  br i1 %more1.not, label %exit, label %vector.body

vector.body:                                      ; preds = %entry, %vector.body
  %index = phi i64 [ %current.iteration.next, %vector.body ], [ 0, %entry ]
  %avl = phi i64 [ %avl.next, %vector.body ], [ %n, %entry ]
  %0 = tail call i32 @llvm.experimental.get.vector.length.i64(i64 %avl, i32 4, i1 true)
  %1 = getelementptr [4 x i8], ptr %input, i64 %index
  %vp.op.load = tail call <vscale x 4 x float> @llvm.vp.load.nxv4f32.p0(ptr align 4 %1, <vscale x 4 x i1> splat (i1 true), i32 %0)
  %2 = tail call <vscale x 4 x i8> @llvm.fptosi.sat.nxv4i8.nxv4f32(<vscale x 4 x float> %vp.op.load)
  %3 = getelementptr i8, ptr %output, i64 %index
  tail call void @llvm.vp.store.nxv4i8.p0(<vscale x 4 x i8> %2, ptr align 1 %3, <vscale x 4 x i1> splat (i1 true), i32 %0)
  %4 = zext i32 %0 to i64
  %current.iteration.next = add i64 %index, %4
  %avl.next = sub nuw i64 %avl, %4
  %5 = icmp eq i64 %avl.next, 0
  br i1 %5, label %exit, label %vector.body, !llvm.loop !0

exit:                                             ; preds = %vector.body, %entry
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.experimental.get.vector.length.i64(i64, i32 immarg, i1 immarg) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: read)
declare <vscale x 4 x float> @llvm.vp.load.nxv4f32.p0(ptr captures(none), <vscale x 4 x i1>, i32) #2

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <vscale x 4 x i8> @llvm.fptosi.sat.nxv4i8.nxv4f32(<vscale x 4 x float>) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: write)
declare void @llvm.vp.store.nxv4i8.p0(<vscale x 4 x i8>, ptr captures(none), <vscale x 4 x i1>, i32) #4

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: read) }
attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: write) }

!0 = distinct !{!0, !1, !2, !3}
!1 = !{!"llvm.loop.isvectorized", i32 1}
!2 = !{!"llvm.loop.vectorize.body", i32 1}
!3 = !{!"llvm.loop.unroll.runtime.disable"}
