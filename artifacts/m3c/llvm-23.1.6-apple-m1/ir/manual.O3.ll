; ModuleID = '/Users/josephpak/KernelForge/experiments/aarch64/m3c/manual_kernel.cpp'
source_filename = "/Users/josephpak/KernelForge/experiments/aarch64/m3c/manual_kernel.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync)
define void @kernelforge_sat_i8_manual(i64 noundef %0, ptr nofree noundef readonly captures(none) %1, ptr nofree noundef writeonly captures(none) %2) local_unnamed_addr #0 !dbg !13 {
  %4 = icmp eq i64 %0, 0, !dbg !17
  br i1 %4, label %58, label %5, !dbg !18

5:                                                ; preds = %3
  %6 = icmp ult i64 %0, 4, !dbg !18
  br i1 %6, label %56, label %7, !dbg !18

7:                                                ; preds = %5
  %8 = getelementptr i8, ptr %2, i64 %0, !dbg !18
  %9 = shl i64 %0, 2, !dbg !18
  %10 = getelementptr i8, ptr %1, i64 %9, !dbg !18
  %11 = icmp ult ptr %2, %10, !dbg !18
  %12 = icmp ult ptr %1, %8, !dbg !18
  %13 = and i1 %11, %12, !dbg !18
  br i1 %13, label %56, label %14, !dbg !19

14:                                               ; preds = %7
  %15 = icmp ult i64 %0, 16, !dbg !18
  br i1 %15, label %37, label %16, !dbg !18

16:                                               ; preds = %14
  %17 = and i64 %0, 12
  %18 = and i64 %0, -16
  br label %19, !dbg !18

19:                                               ; preds = %19, %16
  %20 = phi i64 [ 0, %16 ], [ %31, %19 ], !dbg !19
  %21 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %20, !dbg !20
  %22 = load <16 x float>, ptr %21, align 4, !dbg !20, !tbaa !21, !alias.scope !23
  %23 = fcmp uno <16 x float> %22, zeroinitializer, !dbg !26
  %24 = fcmp ogt <16 x float> %22, splat (float 1.270000e+02), !dbg !27
  %25 = select <16 x i1> %24, <16 x float> splat (float 1.270000e+02), <16 x float> %22, !dbg !27
  %26 = fcmp olt <16 x float> %25, splat (float -1.280000e+02), !dbg !28
  %27 = select <16 x i1> %26, <16 x float> splat (float -1.280000e+02), <16 x float> %25, !dbg !28
  %28 = fptosi <16 x float> %27 to <16 x i8>, !dbg !29
  %29 = select <16 x i1> %23, <16 x i8> zeroinitializer, <16 x i8> %28, !dbg !30
  %30 = getelementptr inbounds nuw i8, ptr %2, i64 %20, !dbg !30
  store <16 x i8> %29, ptr %30, align 1, !dbg !30, !tbaa !31, !alias.scope !32, !noalias !23
  %31 = add nuw i64 %20, 16, !dbg !19
  %32 = icmp eq i64 %31, %18, !dbg !18
  br i1 %32, label %33, label %19, !dbg !18, !llvm.loop !34

33:                                               ; preds = %19
  %34 = icmp eq i64 %0, %18, !dbg !18
  br i1 %34, label %58, label %35, !dbg !18

35:                                               ; preds = %33
  %36 = icmp eq i64 %17, 0
  br i1 %36, label %56, label %37, !prof !39

37:                                               ; preds = %14, %35
  %38 = phi i64 [ %18, %35 ], [ 0, %14 ]
  %39 = and i64 %0, -4
  br label %40

40:                                               ; preds = %40, %37
  %41 = phi i64 [ %38, %37 ], [ %52, %40 ], !dbg !19
  %42 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %41, !dbg !20
  %43 = load <4 x float>, ptr %42, align 4, !dbg !20, !tbaa !21, !alias.scope !23
  %44 = fcmp uno <4 x float> %43, zeroinitializer, !dbg !26
  %45 = fcmp ogt <4 x float> %43, splat (float 1.270000e+02), !dbg !27
  %46 = select <4 x i1> %45, <4 x float> splat (float 1.270000e+02), <4 x float> %43, !dbg !27
  %47 = fcmp olt <4 x float> %46, splat (float -1.280000e+02), !dbg !28
  %48 = select <4 x i1> %47, <4 x float> splat (float -1.280000e+02), <4 x float> %46, !dbg !28
  %49 = fptosi <4 x float> %48 to <4 x i8>, !dbg !29
  %50 = select <4 x i1> %44, <4 x i8> zeroinitializer, <4 x i8> %49, !dbg !30
  %51 = getelementptr inbounds nuw i8, ptr %2, i64 %41, !dbg !30
  store <4 x i8> %50, ptr %51, align 1, !dbg !30, !tbaa !31, !alias.scope !32, !noalias !23
  %52 = add nuw i64 %41, 4, !dbg !19
  %53 = icmp eq i64 %52, %39, !dbg !18
  br i1 %53, label %54, label %40, !dbg !18, !llvm.loop !40

54:                                               ; preds = %40
  %55 = icmp eq i64 %0, %39, !dbg !18
  br i1 %55, label %58, label %56, !dbg !18

56:                                               ; preds = %7, %5, %35, %54
  %57 = phi i64 [ 0, %5 ], [ 0, %7 ], [ %18, %35 ], [ %39, %54 ]
  br label %59, !dbg !18

58:                                               ; preds = %70, %33, %54, %3
  ret void, !dbg !42

59:                                               ; preds = %56, %70
  %60 = phi i64 [ %73, %70 ], [ %57, %56 ]
  %61 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %60, !dbg !20
  %62 = load float, ptr %61, align 4, !dbg !20, !tbaa !21
  %63 = fcmp uno float %62, 0.000000e+00, !dbg !26
  br i1 %63, label %70, label %64, !dbg !26

64:                                               ; preds = %59
  %65 = fcmp ogt float %62, 1.270000e+02, !dbg !27
  %66 = select i1 %65, float 1.270000e+02, float %62, !dbg !27
  %67 = fcmp olt float %66, -1.280000e+02, !dbg !28
  %68 = select i1 %67, float -1.280000e+02, float %66, !dbg !28
  %69 = fptosi float %68 to i8, !dbg !29
  br label %70, !dbg !43

70:                                               ; preds = %59, %64
  %71 = phi i8 [ %69, %64 ], [ 0, %59 ], !dbg !30
  %72 = getelementptr inbounds nuw i8, ptr %2, i64 %60, !dbg !30
  store i8 %71, ptr %72, align 1, !dbg !30, !tbaa !31
  %73 = add nuw i64 %60, 1, !dbg !19
  %74 = icmp eq i64 %73, %0, !dbg !17
  br i1 %74, label %58, label %59, !dbg !18, !llvm.loop !44
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp memory(argmem: readwrite) uwtable(sync) "frame-pointer"="non-leaf-no-reserve" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-a14" "target-features"="+aes,+altnzcv,+ccdp,+ccidx,+ccpp,+complxnum,+crc,+dit,+dotprod,+flagm,+fp-armv8,+fp16fml,+fptoint,+fullfp16,+jsconv,+lse,+neon,+pauth,+perfmon,+predres,+ras,+rcpc,+rdm,+sb,+sha2,+sha3,+specrestrict,+ssbs,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8a" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.dbg.cu = !{!5}
!llvm.ident = !{!7}
!llvm.errno.tbaa = !{!8}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 5]}
!1 = !{i32 2, !"Debug Info Version", i32 3}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 1}
!4 = !{i32 7, !"frame-pointer", i32 4}
!5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !6, producer: "Homebrew clang version 23.1.6", isOptimized: true, runtimeVersion: 0, emissionKind: NoDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!6 = !DIFile(filename: "/Users/josephpak/KernelForge/experiments/aarch64/m3c/manual_kernel.cpp", directory: "/Users/josephpak/KernelForge")
!7 = !{!"Homebrew clang version 23.1.6"}
!8 = !{!9, !10, i64 0}
!9 = !{!"__libc_errno", !10, i64 0}
!10 = !{!"int", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C++ TBAA"}
!13 = distinct !DISubprogram(name: "kernelforge_sat_i8_manual", scope: !14, file: !14, line: 9, type: !15, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !5)
!14 = !DIFile(filename: "experiments/aarch64/m3c/manual_kernel.cpp", directory: "/Users/josephpak/KernelForge")
!15 = !DISubroutineType(types: !16)
!16 = !{}
!17 = !DILocation(line: 12, column: 29, scope: !13)
!18 = !DILocation(line: 12, column: 3, scope: !13)
!19 = !DILocation(line: 12, column: 34, scope: !13)
!20 = !DILocation(line: 13, column: 19, scope: !13)
!21 = !{!22, !22, i64 0}
!22 = !{!"float", !11, i64 0}
!23 = !{!24}
!24 = distinct !{!24, !25}
!25 = distinct !{!25, !"LVerDomain"}
!26 = !DILocation(line: 14, column: 15, scope: !13)
!27 = !DILocation(line: 18, column: 15, scope: !13)
!28 = !DILocation(line: 20, column: 15, scope: !13)
!29 = !DILocation(line: 22, column: 42, scope: !13)
!30 = !DILocation(line: 0, scope: !13)
!31 = !{!11, !11, i64 0}
!32 = !{!33}
!33 = distinct !{!33, !25}
!34 = distinct !{!34, !35, !36, !37, !38}
!35 = !{!"llvm.loop.mustprogress"}
!36 = !{!"llvm.loop.isvectorized", i32 1}
!37 = !{!"llvm.loop.vectorize.body", i32 1}
!38 = !{!"llvm.loop.unroll.runtime.disable"}
!39 = !{!"branch_weights", i32 4, i32 12}
!40 = distinct !{!40, !35, !36, !41, !37, !38}
!41 = !{!"llvm.loop.vectorize.epilogue", i32 1}
!42 = !DILocation(line: 24, column: 1, scope: !13)
!43 = !DILocation(line: 23, column: 3, scope: !13)
!44 = distinct !{!44, !18, !43, !35, !36, !41, !41}
