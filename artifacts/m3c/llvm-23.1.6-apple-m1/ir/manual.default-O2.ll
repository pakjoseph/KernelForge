; ModuleID = '/Users/josephpak/KernelForge/artifacts/m3c/llvm-23.1.6-apple-m1/ir/manual.frontend.ll'
source_filename = "/Users/josephpak/KernelForge/experiments/aarch64/m3c/manual_kernel.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync)
define void @kernelforge_sat_i8_manual(i64 noundef %0, ptr nofree noundef readonly captures(none) %1, ptr nofree noundef writeonly captures(none) %2) local_unnamed_addr #0 {
  %.not = icmp eq i64 %0, 0
  br i1 %.not, label %._crit_edge, label %iter.check

iter.check:                                       ; preds = %3
  %min.iters.check = icmp ult i64 %0, 4
  br i1 %min.iters.check, label %.lr.ph.preheader, label %vector.memcheck

vector.memcheck:                                  ; preds = %iter.check
  %scevgep = getelementptr i8, ptr %2, i64 %0
  %4 = shl i64 %0, 2
  %scevgep19 = getelementptr i8, ptr %1, i64 %4
  %bound0 = icmp ult ptr %2, %scevgep19
  %bound1 = icmp ult ptr %1, %scevgep
  %found.conflict = and i1 %bound0, %bound1
  br i1 %found.conflict, label %.lr.ph.preheader, label %vector.main.loop.iter.check

vector.main.loop.iter.check:                      ; preds = %vector.memcheck
  %min.iters.check20 = icmp ult i64 %0, 16
  br i1 %min.iters.check20, label %vec.epilog.ph, label %vector.ph

vector.ph:                                        ; preds = %vector.main.loop.iter.check
  %n.mod.vf = and i64 %0, 12
  %n.vec = and i64 %0, -16
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i64 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %5 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %index
  %wide.load = load <16 x float>, ptr %5, align 4, !alias.scope !5
  %6 = fcmp uno <16 x float> %wide.load, zeroinitializer
  %7 = fcmp ogt <16 x float> %wide.load, splat (float 1.270000e+02)
  %8 = select <16 x i1> %7, <16 x float> splat (float 1.270000e+02), <16 x float> %wide.load
  %9 = fcmp olt <16 x float> %8, splat (float -1.280000e+02)
  %10 = select <16 x i1> %9, <16 x float> splat (float -1.280000e+02), <16 x float> %8
  %11 = fptosi <16 x float> %10 to <16 x i8>
  %predphi = select <16 x i1> %6, <16 x i8> zeroinitializer, <16 x i8> %11
  %12 = getelementptr inbounds nuw i8, ptr %2, i64 %index
  store <16 x i8> %predphi, ptr %12, align 1, !alias.scope !8, !noalias !5
  %index.next = add nuw i64 %index, 16
  %13 = icmp eq i64 %index.next, %n.vec
  br i1 %13, label %middle.block, label %vector.body, !llvm.loop !10

middle.block:                                     ; preds = %vector.body
  %cmp.n = icmp eq i64 %0, %n.vec
  br i1 %cmp.n, label %._crit_edge, label %vec.epilog.iter.check

vec.epilog.iter.check:                            ; preds = %middle.block
  %min.epilog.iters.check = icmp eq i64 %n.mod.vf, 0
  br i1 %min.epilog.iters.check, label %.lr.ph.preheader, label %vec.epilog.ph, !prof !14

vec.epilog.ph:                                    ; preds = %vector.main.loop.iter.check, %vec.epilog.iter.check
  %vec.epilog.resume.val = phi i64 [ %n.vec, %vec.epilog.iter.check ], [ 0, %vector.main.loop.iter.check ]
  %n.vec22 = and i64 %0, -4
  br label %vec.epilog.vector.body

vec.epilog.vector.body:                           ; preds = %vec.epilog.vector.body, %vec.epilog.ph
  %index23 = phi i64 [ %vec.epilog.resume.val, %vec.epilog.ph ], [ %index.next26, %vec.epilog.vector.body ]
  %14 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %index23
  %wide.load24 = load <4 x float>, ptr %14, align 4, !alias.scope !5
  %15 = fcmp uno <4 x float> %wide.load24, zeroinitializer
  %16 = fcmp ogt <4 x float> %wide.load24, splat (float 1.270000e+02)
  %17 = select <4 x i1> %16, <4 x float> splat (float 1.270000e+02), <4 x float> %wide.load24
  %18 = fcmp olt <4 x float> %17, splat (float -1.280000e+02)
  %19 = select <4 x i1> %18, <4 x float> splat (float -1.280000e+02), <4 x float> %17
  %20 = fptosi <4 x float> %19 to <4 x i8>
  %predphi25 = select <4 x i1> %15, <4 x i8> zeroinitializer, <4 x i8> %20
  %21 = getelementptr inbounds nuw i8, ptr %2, i64 %index23
  store <4 x i8> %predphi25, ptr %21, align 1, !alias.scope !8, !noalias !5
  %index.next26 = add nuw i64 %index23, 4
  %22 = icmp eq i64 %index.next26, %n.vec22
  br i1 %22, label %vec.epilog.middle.block, label %vec.epilog.vector.body, !llvm.loop !15

vec.epilog.middle.block:                          ; preds = %vec.epilog.vector.body
  %cmp.n27 = icmp eq i64 %0, %n.vec22
  br i1 %cmp.n27, label %._crit_edge, label %.lr.ph.preheader

.lr.ph.preheader:                                 ; preds = %vector.memcheck, %iter.check, %vec.epilog.iter.check, %vec.epilog.middle.block
  %.01315.ph = phi i64 [ 0, %iter.check ], [ 0, %vector.memcheck ], [ %n.vec, %vec.epilog.iter.check ], [ %n.vec22, %vec.epilog.middle.block ]
  br label %.lr.ph

.lr.ph:                                           ; preds = %.lr.ph.preheader, %30
  %.01315 = phi i64 [ %32, %30 ], [ %.01315.ph, %.lr.ph.preheader ]
  %23 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %.01315
  %24 = load float, ptr %23, align 4
  %25 = fcmp uno float %24, 0.000000e+00
  br i1 %25, label %30, label %26

26:                                               ; preds = %.lr.ph
  %27 = fcmp ogt float %24, 1.270000e+02
  %.0 = select i1 %27, float 1.270000e+02, float %24
  %28 = fcmp olt float %.0, -1.280000e+02
  %.1 = select i1 %28, float -1.280000e+02, float %.0
  %29 = fptosi float %.1 to i8
  br label %30

30:                                               ; preds = %.lr.ph, %26
  %.sink = phi i8 [ %29, %26 ], [ 0, %.lr.ph ]
  %31 = getelementptr inbounds nuw i8, ptr %2, i64 %.01315
  store i8 %.sink, ptr %31, align 1
  %32 = add nuw i64 %.01315, 1
  %exitcond.not = icmp eq i64 %32, %0
  br i1 %exitcond.not, label %._crit_edge, label %.lr.ph, !llvm.loop !16

._crit_edge:                                      ; preds = %30, %middle.block, %vec.epilog.middle.block, %3
  ret void
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-a14" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 5]}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 4}
!4 = !{!"Homebrew clang version 23.1.6"}
!5 = !{!6}
!6 = distinct !{!6, !7}
!7 = distinct !{!7, !"LVerDomain"}
!8 = !{!9}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !11, !12, !13}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.isvectorized", i32 1}
!13 = !{!"llvm.loop.unroll.runtime.disable"}
!14 = !{!"branch_weights", i32 4, i32 12}
!15 = distinct !{!15, !11, !12, !13}
!16 = distinct !{!16, !11, !12}
