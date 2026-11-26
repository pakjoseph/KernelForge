; REPORT: function=known_disjoint alias access#0 access#1 = NoAlias
; REPORT: function=possibly_overlapping alias access#0 access#1 = MayAlias
; REPORT: function=same_location alias access#0 access#1 = MustAlias

define void @known_disjoint(ptr noalias %src, ptr noalias %dst) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %in = getelementptr i32, ptr %src, i64 %i
  %value = load i32, ptr %in, align 4
  %out = getelementptr i32, ptr %dst, i64 %i
  store i32 %value, ptr %out, align 4
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, 4
  br i1 %again, label %loop, label %exit

exit:
  ret void
}

define void @possibly_overlapping(ptr %src, ptr %dst) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %in = getelementptr i32, ptr %src, i64 %i
  %value = load i32, ptr %in, align 4
  %out = getelementptr i32, ptr %dst, i64 %i
  store i32 %value, ptr %out, align 4
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, 4
  br i1 %again, label %loop, label %exit

exit:
  ret void
}

define void @same_location(ptr %data) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %address = getelementptr i32, ptr %data, i64 %i
  %value = load i32, ptr %address, align 4
  store i32 %value, ptr %address, align 4
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, 4
  br i1 %again, label %loop, label %exit

exit:
  ret void
}
