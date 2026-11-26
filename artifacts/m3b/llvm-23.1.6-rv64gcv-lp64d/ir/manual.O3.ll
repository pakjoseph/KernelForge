; ModuleID = '/Users/josephpak/KernelForge/experiments/riscv/manual_sat_i8.c'
source_filename = "/Users/josephpak/KernelForge/experiments/riscv/manual_sat_i8.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-unknown-elf"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) vscale_range(2,1024)
define dso_local void @kernelforge_sat_i8_manual(i64 noundef %0, ptr noalias nofree noundef readonly captures(none) %1, ptr noalias nofree noundef writeonly captures(none) %2) local_unnamed_addr #0 !dbg !13 {
  %4 = icmp eq i64 %0, 0, !dbg !17
  br i1 %4, label %23, label %5, !dbg !18

5:                                                ; preds = %3, %5
  %6 = phi i64 [ %20, %5 ], [ 0, %3 ], !dbg !19
  %7 = phi i64 [ %21, %5 ], [ %0, %3 ]
  %8 = tail call i32 @llvm.experimental.get.vector.length.i64(i64 %7, i32 4, i1 true)
  %9 = getelementptr inbounds nuw [4 x i8], ptr %1, i64 %6, !dbg !20
  %10 = tail call <vscale x 4 x float> @llvm.vp.load.nxv4f32.p0(ptr align 4 %9, <vscale x 4 x i1> splat (i1 true), i32 %8), !dbg !20, !tbaa !21
  %11 = fcmp uno <vscale x 4 x float> %10, zeroinitializer, !dbg !23
  %12 = fcmp ogt <vscale x 4 x float> %10, splat (float 1.270000e+02), !dbg !24
  %13 = select <vscale x 4 x i1> %12, <vscale x 4 x float> splat (float 1.270000e+02), <vscale x 4 x float> %10, !dbg !24
  %14 = fcmp olt <vscale x 4 x float> %13, splat (float -1.280000e+02), !dbg !25
  %15 = select <vscale x 4 x i1> %14, <vscale x 4 x float> splat (float -1.280000e+02), <vscale x 4 x float> %13, !dbg !25
  %16 = fptosi <vscale x 4 x float> %15 to <vscale x 4 x i8>, !dbg !26
  %17 = select <vscale x 4 x i1> %11, <vscale x 4 x i8> zeroinitializer, <vscale x 4 x i8> %16, !dbg !27
  %18 = getelementptr inbounds nuw i8, ptr %2, i64 %6, !dbg !27
  tail call void @llvm.vp.store.nxv4i8.p0(<vscale x 4 x i8> %17, ptr align 1 %18, <vscale x 4 x i1> splat (i1 true), i32 %8), !dbg !27, !tbaa !28
  %19 = zext i32 %8 to i64, !dbg !19
  %20 = add i64 %6, %19, !dbg !19
  %21 = sub nuw i64 %7, %19
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %23, label %5, !dbg !18, !llvm.loop !29

23:                                               ; preds = %5, %3
  ret void, !dbg !34
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.experimental.get.vector.length.i64(i64, i32 immarg, i1 immarg) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: read)
declare <vscale x 4 x float> @llvm.vp.load.nxv4f32.p0(ptr captures(none), <vscale x 4 x i1>, i32) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: write)
declare void @llvm.vp.store.nxv4i8.p0(<vscale x 4 x i8>, ptr captures(none), <vscale x 4 x i1>, i32) #3

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite) vscale_range(2,1024) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+v,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,+zve32f,+zve32x,+zve64d,+zve64f,+zve64x,+zvl128b,+zvl32b,+zvl64b,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl4096b,-zvl512b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: read) }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: write) }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !6}
!llvm.ident = !{!7}
!llvm.errno.tbaa = !{!8}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "Homebrew clang version 23.1.6", isOptimized: true, runtimeVersion: 0, emissionKind: NoDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "/Users/josephpak/KernelForge/experiments/riscv/manual_sat_i8.c", directory: "/Users/josephpak/KernelForge")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"target-abi", !"lp64d"}
!4 = !{i32 6, !"riscv-isa", !5}
!5 = !{!"rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_v1p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvl128b1p0_zvl32b1p0_zvl64b1p0"}
!6 = !{i32 8, !"SmallDataLimit", i32 0}
!7 = !{!"Homebrew clang version 23.1.6"}
!8 = !{!9, !10, i64 0}
!9 = !{!"__libc_errno", !10, i64 0}
!10 = !{!"int", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = distinct !DISubprogram(name: "kernelforge_sat_i8_manual", scope: !14, file: !14, line: 9, type: !15, scopeLine: 11, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!14 = !DIFile(filename: "experiments/riscv/manual_sat_i8.c", directory: "/Users/josephpak/KernelForge")
!15 = !DISubroutineType(types: !16)
!16 = !{}
!17 = !DILocation(line: 12, column: 31, scope: !13)
!18 = !DILocation(line: 12, column: 3, scope: !13)
!19 = !DILocation(line: 12, column: 36, scope: !13)
!20 = !DILocation(line: 13, column: 19, scope: !13)
!21 = !{!22, !22, i64 0}
!22 = !{!"float", !11, i64 0}
!23 = !DILocation(line: 14, column: 15, scope: !13)
!24 = !DILocation(line: 18, column: 15, scope: !13)
!25 = !DILocation(line: 20, column: 15, scope: !13)
!26 = !DILocation(line: 22, column: 17, scope: !13)
!27 = !DILocation(line: 0, scope: !13)
!28 = !{!11, !11, i64 0}
!29 = distinct !{!29, !30, !31, !32, !33}
!30 = !{!"llvm.loop.mustprogress"}
!31 = !{!"llvm.loop.isvectorized", i32 1}
!32 = !{!"llvm.loop.vectorize.body", i32 1}
!33 = !{!"llvm.loop.unroll.runtime.disable"}
!34 = !DILocation(line: 24, column: 1, scope: !13)
