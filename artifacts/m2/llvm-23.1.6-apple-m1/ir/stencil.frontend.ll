; ModuleID = 'kernels/stencil.cpp'
source_filename = "kernels/stencil.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx26.0.0"

; Function Attrs: mustprogress noinline nounwind ssp uwtable(sync)
define void @kernelforge_stencil(i64 noundef %0, ptr noalias noundef %1, ptr noalias noundef %2) #0 {
  %4 = alloca i64, align 8
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i64, align 8
  store i64 %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store ptr %2, ptr %6, align 8
  %8 = load i64, ptr %4, align 8
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %3
  br label %60

11:                                               ; preds = %3
  %12 = load ptr, ptr %5, align 8
  %13 = getelementptr inbounds float, ptr %12, i64 0
  %14 = load float, ptr %13, align 4
  %15 = load ptr, ptr %6, align 8
  %16 = getelementptr inbounds float, ptr %15, i64 0
  store float %14, ptr %16, align 4
  %17 = load i64, ptr %4, align 8
  %18 = icmp eq i64 %17, 1
  br i1 %18, label %19, label %20

19:                                               ; preds = %11
  br label %60

20:                                               ; preds = %11
  store i64 1, ptr %7, align 8
  br label %21

21:                                               ; preds = %47, %20
  %22 = load i64, ptr %7, align 8
  %23 = load i64, ptr %4, align 8
  %24 = sub i64 %23, 1
  %25 = icmp ult i64 %22, %24
  br i1 %25, label %26, label %50

26:                                               ; preds = %21
  %27 = load ptr, ptr %5, align 8
  %28 = load i64, ptr %7, align 8
  %29 = sub i64 %28, 1
  %30 = getelementptr inbounds nuw float, ptr %27, i64 %29
  %31 = load float, ptr %30, align 4
  %32 = load ptr, ptr %5, align 8
  %33 = load i64, ptr %7, align 8
  %34 = getelementptr inbounds nuw float, ptr %32, i64 %33
  %35 = load float, ptr %34, align 4
  %36 = fadd float %31, %35
  %37 = load ptr, ptr %5, align 8
  %38 = load i64, ptr %7, align 8
  %39 = add i64 %38, 1
  %40 = getelementptr inbounds nuw float, ptr %37, i64 %39
  %41 = load float, ptr %40, align 4
  %42 = fadd float %36, %41
  %43 = fdiv float %42, 3.000000e+00
  %44 = load ptr, ptr %6, align 8
  %45 = load i64, ptr %7, align 8
  %46 = getelementptr inbounds nuw float, ptr %44, i64 %45
  store float %43, ptr %46, align 4
  br label %47

47:                                               ; preds = %26
  %48 = load i64, ptr %7, align 8
  %49 = add i64 %48, 1
  store i64 %49, ptr %7, align 8
  br label %21, !llvm.loop !5

50:                                               ; preds = %21
  %51 = load ptr, ptr %5, align 8
  %52 = load i64, ptr %4, align 8
  %53 = sub i64 %52, 1
  %54 = getelementptr inbounds nuw float, ptr %51, i64 %53
  %55 = load float, ptr %54, align 4
  %56 = load ptr, ptr %6, align 8
  %57 = load i64, ptr %4, align 8
  %58 = sub i64 %57, 1
  %59 = getelementptr inbounds nuw float, ptr %56, i64 %58
  store float %55, ptr %59, align 4
  br label %60

60:                                               ; preds = %50, %19, %10
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
