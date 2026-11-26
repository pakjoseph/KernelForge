; REPORT: function=address_space_one access#0 load width=4 bytes address-space=1 stride=4 bytes/iteration
; REPORT: function=address_space_one access#1 store width=4 bytes address-space=1 stride=4 bytes/iteration
; REPORT: function=unknown_pointer_width access#0 load width=unknown (module has no data layout for this access type) address-space=0 stride=0 bytes/iteration

define void @address_space_one(ptr addrspace(1) noalias %src,
                               ptr addrspace(1) noalias %dst) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %in = getelementptr i32, ptr addrspace(1) %src, i64 %i
  %value = load i32, ptr addrspace(1) %in, align 4
  %out = getelementptr i32, ptr addrspace(1) %dst, i64 %i
  store i32 %value, ptr addrspace(1) %out, align 4
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, 4
  br i1 %again, label %loop, label %exit

exit:
  ret void
}

define void @unknown_pointer_width(ptr %slot) {
entry:
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %value = load ptr, ptr %slot, align 8
  %next = add nuw nsw i64 %i, 1
  %again = icmp ult i64 %next, 4
  br i1 %again, label %loop, label %exit

exit:
  ret void
}
