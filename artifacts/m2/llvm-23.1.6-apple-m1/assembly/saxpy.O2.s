	.build_version macos, 26, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_kernelforge_saxpy              ; -- Begin function kernelforge_saxpy
	.p2align	2
_kernelforge_saxpy:                     ; @kernelforge_saxpy
	.cfi_startproc
; %bb.0:
                                        ; kill: def $s0 killed $s0 def $q0
	cbz	x0, LBB0_14
; %bb.1:
	cmp	x0, #4
	b.hs	LBB0_3
; %bb.2:
	mov	x8, #0                          ; =0x0
	b	LBB0_12
LBB0_3:
	cmp	x0, #16
	b.hs	LBB0_5
; %bb.4:
	mov	x8, #0                          ; =0x0
	b	LBB0_9
LBB0_5:
	and	x9, x0, #0xc
	and	x8, x0, #0xfffffffffffffff0
	add	x10, x1, #32
	add	x11, x2, #32
	add	x12, x3, #32
	and	x13, x0, #0xfffffffffffffff0
LBB0_6:                                 ; =>This Inner Loop Header: Depth=1
	ldp	q1, q2, [x10, #-32]
	ldp	q3, q4, [x10], #64
	ldp	q5, q6, [x11, #-32]
	ldp	q7, q16, [x11], #64
	fmla.4s	v5, v1, v0[0]
	fmla.4s	v6, v2, v0[0]
	fmla.4s	v7, v3, v0[0]
	fmla.4s	v16, v4, v0[0]
	stp	q5, q6, [x12, #-32]
	stp	q7, q16, [x12], #64
	subs	x13, x13, #16
	b.ne	LBB0_6
; %bb.7:
	cmp	x0, x8
	b.eq	LBB0_14
; %bb.8:
	cbz	x9, LBB0_12
LBB0_9:
	mov	x10, x8
	and	x8, x0, #0xfffffffffffffffc
	sub	x9, x10, x8
	lsl	x12, x10, #2
	add	x10, x3, x12
	add	x11, x2, x12
	add	x12, x1, x12
LBB0_10:                                ; =>This Inner Loop Header: Depth=1
	ldr	q1, [x12], #16
	ldr	q2, [x11], #16
	fmla.4s	v2, v1, v0[0]
	str	q2, [x10], #16
	adds	x9, x9, #4
	b.ne	LBB0_10
; %bb.11:
	cmp	x0, x8
	b.eq	LBB0_14
LBB0_12:
	sub	x9, x0, x8
	lsl	x11, x8, #2
	add	x8, x3, x11
	add	x10, x2, x11
	add	x11, x1, x11
LBB0_13:                                ; =>This Inner Loop Header: Depth=1
	ldr	s1, [x11], #4
	ldr	s2, [x10], #4
	fmadd	s1, s0, s1, s2
	str	s1, [x8], #4
	subs	x9, x9, #1
	b.ne	LBB0_13
LBB0_14:
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
