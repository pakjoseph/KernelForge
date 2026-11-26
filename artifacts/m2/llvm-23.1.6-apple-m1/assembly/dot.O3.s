	.build_version macos, 26, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_kernelforge_dot                ; -- Begin function kernelforge_dot
	.p2align	2
_kernelforge_dot:                       ; @kernelforge_dot
	.cfi_startproc
; %bb.0:
	cbz	x0, LBB0_3
; %bb.1:
	cmp	x0, #4
	b.hs	LBB0_4
; %bb.2:
	mov	x8, #0                          ; =0x0
	movi.2d	v0, #0000000000000000
	b	LBB0_13
LBB0_3:
	movi.2d	v0, #0000000000000000
	ret
LBB0_4:
	cmp	x0, #16
	b.hs	LBB0_6
; %bb.5:
	mov	x8, #0                          ; =0x0
	movi.2d	v0, #0000000000000000
	b	LBB0_10
LBB0_6:
	and	x9, x0, #0xc
	and	x8, x0, #0xfffffffffffffff0
	add	x10, x1, #32
	add	x11, x2, #32
	movi.2d	v0, #0000000000000000
	and	x12, x0, #0xfffffffffffffff0
LBB0_7:                                 ; =>This Inner Loop Header: Depth=1
	ldp	q1, q2, [x10, #-32]
	ldp	q3, q4, [x10], #64
	ldp	q5, q6, [x11, #-32]
	ldp	q7, q16, [x11], #64
	fmul.4s	v1, v1, v5
	mov	s5, v1[3]
	mov	s17, v1[2]
	mov	s18, v1[1]
	fmul.4s	v2, v2, v6
	mov	s6, v2[3]
	mov	s19, v2[2]
	mov	s20, v2[1]
	fmul.4s	v3, v3, v7
	mov	s7, v3[3]
	mov	s21, v3[2]
	mov	s22, v3[1]
	fmul.4s	v4, v4, v16
	mov	s16, v4[3]
	mov	s23, v4[2]
	mov	s24, v4[1]
	fadd	s0, s0, s1
	fadd	s0, s0, s18
	fadd	s0, s0, s17
	fadd	s0, s0, s5
	fadd	s0, s0, s2
	fadd	s0, s0, s20
	fadd	s0, s0, s19
	fadd	s0, s0, s6
	fadd	s0, s0, s3
	fadd	s0, s0, s22
	fadd	s0, s0, s21
	fadd	s0, s0, s7
	fadd	s0, s0, s4
	fadd	s0, s0, s24
	fadd	s0, s0, s23
	fadd	s0, s0, s16
	subs	x12, x12, #16
	b.ne	LBB0_7
; %bb.8:
	cmp	x0, x8
	b.eq	LBB0_15
; %bb.9:
	cbz	x9, LBB0_13
LBB0_10:
	mov	x10, x8
	and	x8, x0, #0xfffffffffffffffc
	sub	x9, x10, x8
	lsl	x11, x10, #2
	add	x10, x2, x11
	add	x11, x1, x11
LBB0_11:                                ; =>This Inner Loop Header: Depth=1
	ldr	q1, [x11], #16
	ldr	q2, [x10], #16
	fmul.4s	v1, v1, v2
	mov	s2, v1[3]
	mov	s3, v1[2]
	mov	s4, v1[1]
	fadd	s0, s0, s1
	fadd	s0, s0, s4
	fadd	s0, s0, s3
	fadd	s0, s0, s2
	adds	x9, x9, #4
	b.ne	LBB0_11
; %bb.12:
	cmp	x0, x8
	b.eq	LBB0_15
LBB0_13:
	sub	x9, x0, x8
	lsl	x10, x8, #2
	add	x8, x2, x10
	add	x10, x1, x10
LBB0_14:                                ; =>This Inner Loop Header: Depth=1
	ldr	s1, [x10], #4
	ldr	s2, [x8], #4
	fmadd	s0, s1, s2, s0
	subs	x9, x9, #1
	b.ne	LBB0_14
LBB0_15:
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
