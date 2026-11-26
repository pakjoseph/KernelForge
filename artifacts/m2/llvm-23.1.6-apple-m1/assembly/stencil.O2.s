	.build_version macos, 26, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_kernelforge_stencil            ; -- Begin function kernelforge_stencil
	.p2align	2
_kernelforge_stencil:                   ; @kernelforge_stencil
	.cfi_startproc
; %bb.0:
	cbz	x0, LBB0_12
; %bb.1:
	ldr	s0, [x1]
	str	s0, [x2]
	subs	x8, x0, #1
	b.eq	LBB0_12
; %bb.2:
	cmp	x8, #2
	b.lo	LBB0_11
; %bb.3:
	ldr	s0, [x1, #4]
	sub	x10, x0, #2
	cmp	x10, #16
	b.hs	LBB0_5
; %bb.4:
	mov	w9, #1                          ; =0x1
	b	LBB0_9
LBB0_5:
	and	x11, x10, #0xfffffffffffffff0
	orr	x9, x11, #0x1
	dup.4s	v1, v0[0]
	add	x12, x2, #36
	add	x13, x1, #32
	fmov.4s	v0, #3.00000000
	and	x14, x10, #0xfffffffffffffff0
LBB0_6:                                 ; =>This Inner Loop Header: Depth=1
	ldp	q2, q3, [x13, #-32]
	ldp	q4, q5, [x13]
	ldur	q6, [x13, #-24]
	ldur	q7, [x13, #-8]
	ldur	q16, [x13, #8]
	ext.16b	v17, v1, v6, #12
	ldur	q1, [x13, #24]
	ext.16b	v18, v6, v7, #12
	ext.16b	v19, v7, v16, #12
	ext.16b	v20, v16, v1, #12
	fadd.4s	v2, v2, v17
	fadd.4s	v3, v3, v18
	fadd.4s	v4, v4, v19
	fadd.4s	v5, v5, v20
	fadd.4s	v2, v2, v6
	fadd.4s	v3, v3, v7
	fadd.4s	v4, v4, v16
	fadd.4s	v5, v5, v1
	fdiv.4s	v2, v2, v0
	fdiv.4s	v3, v3, v0
	fdiv.4s	v4, v4, v0
	stp	q2, q3, [x12, #-32]
	fdiv.4s	v2, v5, v0
	stp	q4, q2, [x12], #64
	add	x13, x13, #64
	subs	x14, x14, #16
	b.ne	LBB0_6
; %bb.7:
	cmp	x10, x11
	b.eq	LBB0_11
; %bb.8:
	mov	s0, v1[3]
LBB0_9:
	lsl	x11, x9, #2
	add	x10, x2, x11
	mvn	x9, x9
	add	x9, x9, x0
	add	x11, x11, x1
	add	x11, x11, #4
	fmov	s1, #3.00000000
LBB0_10:                                ; =>This Inner Loop Header: Depth=1
	ldur	s2, [x11, #-8]
	fadd	s2, s2, s0
	ldr	s0, [x11], #4
	fadd	s2, s2, s0
	fdiv	s2, s2, s1
	str	s2, [x10], #4
	subs	x9, x9, #1
	b.ne	LBB0_10
LBB0_11:
	ldr	s0, [x1, x8, lsl #2]
	str	s0, [x2, x8, lsl #2]
LBB0_12:
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
