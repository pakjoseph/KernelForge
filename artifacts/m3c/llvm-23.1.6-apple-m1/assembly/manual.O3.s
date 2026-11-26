	.build_version macos, 26, 0	sdk_version 26, 5
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_kernelforge_sat_i8_manual      ; -- Begin function kernelforge_sat_i8_manual
	.p2align	2
_kernelforge_sat_i8_manual:             ; @kernelforge_sat_i8_manual
	.cfi_startproc
; %bb.0:
	cbz	x0, LBB0_17
; %bb.1:
	cmp	x0, #4
	b.lo	LBB0_3
; %bb.2:
	add	x8, x1, x0, lsl #2
	add	x9, x2, x0
	cmp	x1, x9
	ccmp	x2, x8, #2, lo
	b.hs	LBB0_8
LBB0_3:
	mov	x8, #0                          ; =0x0
LBB0_4:
	add	x9, x2, x8
	sub	x10, x0, x8
	add	x8, x1, x8, lsl #2
	mov	w11, #1123942400                ; =0x42fe0000
	fmov	s0, w11
	movi.2s	v1, #195, lsl #24
LBB0_5:                                 ; =>This Inner Loop Header: Depth=1
	ldr	s2, [x8], #4
	fcmp	s2, s2
	b.vs	LBB0_7
; %bb.6:                                ;   in Loop: Header=BB0_5 Depth=1
	fcmp	s2, s0
	fcsel	s2, s0, s2, gt
	fcmp	s2, s1
	fcsel	s2, s1, s2, mi
	fcvtzs	w11, s2
	strb	w11, [x9], #1
	subs	x10, x10, #1
	b.ne	LBB0_5
	b	LBB0_17
LBB0_7:                                 ;   in Loop: Header=BB0_5 Depth=1
	mov	w11, #0                         ; =0x0
	strb	w11, [x9], #1
	subs	x10, x10, #1
	b.ne	LBB0_5
	b	LBB0_17
LBB0_8:
	cmp	x0, #16
	b.hs	LBB0_10
; %bb.9:
	mov	x8, #0                          ; =0x0
	b	LBB0_14
LBB0_10:
	and	x9, x0, #0xc
	and	x8, x0, #0xfffffffffffffff0
	mov	w10, #1123942400                ; =0x42fe0000
	dup.4s	v0, w10
	movi.4s	v1, #195, lsl #24
	mov	x10, x1
	mov	x11, x2
	and	x12, x0, #0xfffffffffffffff0
LBB0_11:                                ; =>This Inner Loop Header: Depth=1
	ldp	q2, q3, [x10]
	ldp	q4, q5, [x10, #32]
	fcmeq.4s	v6, v5, v5
	fcmeq.4s	v7, v4, v4
	uzp1.8h	v6, v7, v6
	fcmeq.4s	v7, v3, v3
	fcmeq.4s	v16, v2, v2
	uzp1.8h	v7, v16, v7
	uzp1.16b	v6, v7, v6
	fcmgt.4s	v7, v5, v0
	fcmgt.4s	v16, v4, v0
	fcmgt.4s	v17, v3, v0
	fcmgt.4s	v18, v2, v0
	bit.16b	v2, v0, v18
	bit.16b	v3, v0, v17
	bit.16b	v4, v0, v16
	bit.16b	v5, v0, v7
	fcmgt.4s	v7, v1, v5
	fcmgt.4s	v16, v1, v4
	fcmgt.4s	v17, v1, v3
	fcmgt.4s	v18, v1, v2
	bit.16b	v2, v1, v18
	bit.16b	v3, v1, v17
	bit.16b	v4, v1, v16
	bit.16b	v5, v1, v7
	fcvtzs.4s	v5, v5
	xtn.4h	v5, v5
	fcvtzs.4s	v4, v4
	xtn.4h	v4, v4
	mov.d	v4[1], v5[0]
	fcvtzs.4s	v3, v3
	xtn.4h	v3, v3
	fcvtzs.4s	v2, v2
	xtn.4h	v2, v2
	mov.d	v2[1], v3[0]
	uzp1.16b	v2, v2, v4
	and.16b	v2, v6, v2
	str	q2, [x11], #16
	add	x10, x10, #64
	subs	x12, x12, #16
	b.ne	LBB0_11
; %bb.12:
	cmp	x0, x8
	b.eq	LBB0_17
; %bb.13:
	cbz	x9, LBB0_4
LBB0_14:
	mov	x11, x8
	and	x8, x0, #0xfffffffffffffffc
	sub	x9, x11, x8
	add	x10, x2, x11
	add	x11, x1, x11, lsl #2
	mov	w12, #1123942400                ; =0x42fe0000
	dup.4s	v0, w12
	movi.4s	v1, #195, lsl #24
LBB0_15:                                ; =>This Inner Loop Header: Depth=1
	ldr	q2, [x11], #16
	fcmeq.4s	v3, v2, v2
	mvn.16b	v3, v3
	xtn.4h	v3, v3
	fcmgt.4s	v4, v2, v0
	bit.16b	v2, v0, v4
	fcmgt.4s	v4, v1, v2
	bit.16b	v2, v1, v4
	fcvtzs.4s	v2, v2
	xtn.4h	v2, v2
	bic.8b	v2, v2, v3
	uzp1.8b	v2, v2, v0
	st1.s	{ v2 }[0], [x10], #4
	adds	x9, x9, #4
	b.ne	LBB0_15
; %bb.16:
	cmp	x0, x8
	b.ne	LBB0_4
LBB0_17:
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
