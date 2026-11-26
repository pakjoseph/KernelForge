; ModuleID = '/Users/josephpak/KernelForge/experiments/aarch64/m3c/manual_kernel.cpp'
source_filename = "/Users/josephpak/KernelForge/experiments/aarch64/m3c/manual_kernel.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress noinline nounwind ssp uwtable(sync)
define void @kernelforge_sat_i8_manual(i64 noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  %4 = alloca i64, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  %8 = alloca float, align 4
  store i64 %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  store i64 0, ptr %7, align 8
  br label %9

9:                                                ; preds = %39, %3
  %10 = load i64, ptr %7, align 8
  %11 = load i64, ptr %4, align 8
  %12 = icmp ult i64 %10, %11
  br i1 %12, label %13, label %42

13:                                               ; preds = %9
  %14 = load ptr, ptr %5, align 8
  %15 = load i64, ptr %7, align 8
  %16 = getelementptr inbounds nuw float, ptr %14, i64 %15
  %17 = load float, ptr %16, align 4
  store float %17, ptr %8, align 4
  %18 = load float, ptr %8, align 4
  %19 = load float, ptr %8, align 4
  %20 = fcmp une float %18, %19
  br i1 %20, label %21, label %25

21:                                               ; preds = %13
  %22 = load ptr, ptr %6, align 8
  %23 = load i64, ptr %7, align 8
  %24 = getelementptr inbounds nuw i8, ptr %22, i64 %23
  store i8 0, ptr %24, align 1
  br label %39

25:                                               ; preds = %13
  %26 = load float, ptr %8, align 4
  %27 = fcmp ogt float %26, 1.270000e+02
  br i1 %27, label %28, label %29

28:                                               ; preds = %25
  store float 1.270000e+02, ptr %8, align 4
  br label %29

29:                                               ; preds = %28, %25
  %30 = load float, ptr %8, align 4
  %31 = fcmp olt float %30, -1.280000e+02
  br i1 %31, label %32, label %33

32:                                               ; preds = %29
  store float -1.280000e+02, ptr %8, align 4
  br label %33

33:                                               ; preds = %32, %29
  %34 = load float, ptr %8, align 4
  %35 = fptosi float %34 to i8
  %36 = load ptr, ptr %6, align 8
  %37 = load i64, ptr %7, align 8
  %38 = getelementptr inbounds nuw i8, ptr %36, i64 %37
  store i8 %35, ptr %38, align 1
  br label %39

39:                                               ; preds = %33, %21
  %40 = load i64, ptr %7, align 8
  %41 = add i64 %40, 1
  store i64 %41, ptr %7, align 8
  br label %9, !llvm.loop !5

42:                                               ; preds = %9
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
