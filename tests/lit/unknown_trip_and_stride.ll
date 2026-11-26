; REPORT: function=unknown_trip_and_stride loop trip-count=unknown loop-carried-dependence=not-analyzed
; REPORT: function=unknown_trip_and_stride access#0 load width=4 bytes address-space=0 stride=unknown (byte step is not constant)
; REPORT: function=unknown_trip_and_stride access#1 store width=4 bytes address-space=0 stride=unknown (byte step is not constant)
; REPORT: function=unknown_trip_known_stride loop trip-count=unknown loop-carried-dependence=not-analyzed
; REPORT: function=unknown_trip_known_stride access#0 load width=4 bytes address-space=0 stride=4 bytes/iteration
; REPORT: function=unknown_trip_known_stride access#1 store width=4 bytes address-space=0 stride=4 bytes/iteration

define void @unknown_trip_and_stride(ptr noalias %src, ptr noalias %dst,
                                     i64 %count, i64 %scale) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %index = mul i64 %i, %scale
  %in = getelementptr float, ptr %src, i64 %index
  %value = load float, ptr %in, align 4
  %out = getelementptr float, ptr %dst, i64 %index
  store float %value, ptr %out, align 4
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, %count
  br i1 %again, label %loop, label %exit

exit:
  ret void
}

define void @unknown_trip_known_stride(ptr noalias %src, ptr noalias %dst,
                                       i64 %count) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %in = getelementptr float, ptr %src, i64 %i
  %value = load float, ptr %in, align 4
  %out = getelementptr float, ptr %dst, i64 %i
  store float %value, ptr %out, align 4
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, %count
  br i1 %again, label %loop, label %exit

exit:
  ret void
}
