; REPORT: function=unit_stride loop trip-count=known(8) loop-carried-dependence=not-analyzed
; REPORT: function=unit_stride access#0 load width=4 bytes address-space=0 stride=4 bytes/iteration
; REPORT: function=unit_stride access#1 store width=4 bytes address-space=0 stride=4 bytes/iteration
; REPORT: function=unit_stride alias access#0 access#1 = NoAlias

define void @unit_stride(ptr noalias %src, ptr noalias %dst) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %in = getelementptr float, ptr %src, i64 %i
  %value = load float, ptr %in, align 4
  %out = getelementptr float, ptr %dst, i64 %i
  store float %value, ptr %out, align 4
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, 8
  br i1 %again, label %loop, label %exit

exit:
  ret void
}
