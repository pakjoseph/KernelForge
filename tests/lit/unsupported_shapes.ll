; REPORT: function=nested_loop unsupported reason=nested loops are unsupported
; REPORT: function=multiple_exits unsupported reason=loop must have exactly one exiting block

define void @nested_loop(ptr %data) {
entry:
  br label %outer

outer:
  %i = phi i64 [ 0, %entry ], [ %i.next, %outer.latch ]
  %outer.more = icmp ult i64 %i, 2
  br i1 %outer.more, label %inner, label %exit

inner:
  %j = phi i64 [ 0, %outer ], [ %j.next, %inner ]
  %address = getelementptr i32, ptr %data, i64 %j
  %value = load i32, ptr %address, align 4
  %j.next = add nuw nsw i64 %j, 1
  %inner.more = icmp ult i64 %j.next, 2
  br i1 %inner.more, label %inner, label %outer.latch

outer.latch:
  %i.next = add nuw nsw i64 %i, 1
  br label %outer

exit:
  ret void
}

define void @multiple_exits(ptr %data, i1 %break_now) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %latch ]
  %more = icmp ult i64 %i, 8
  br i1 %more, label %body, label %exit

body:
  %address = getelementptr i32, ptr %data, i64 %i
  %value = load i32, ptr %address, align 4
  br i1 %break_now, label %exit, label %latch

latch:
  %next = add nuw nsw i64 %i, 1
  br label %loop

exit:
  ret void
}
