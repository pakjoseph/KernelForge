	.build_version macos, 26, 0
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_kernelforge_sat_i8_intrinsic   ; -- Begin function kernelforge_sat_i8_intrinsic
	.p2align	2
_kernelforge_sat_i8_intrinsic:          ; @kernelforge_sat_i8_intrinsic
; %bb.0:                                ; %entry
	cbz	x0, LBB0_14
; %bb.1:                                ; %iter.check
	cmp	x0, #4
	b.hs	LBB0_3
; %bb.2:
	mov	x8, #0                          ; =0x0
	b	LBB0_12
LBB0_3:                                 ; %vector.main.loop.iter.check
	cmp	x0, #64
	b.hs	LBB0_5
; %bb.4:
	mov	x8, #0                          ; =0x0
	b	LBB0_9
LBB0_5:                                 ; %vector.ph
	and	x9, x0, #0x3c
	and	x8, x0, #0xffffffffffffffc0
	add	x10, x1, #128
	add	x11, x2, #32
	movi.4s	v0, #127
	mvni.4s	v1, #127
	and	x12, x0, #0xffffffffffffffc0
LBB0_6:                                 ; %vector.body
                                        ; =>This Inner Loop Header: Depth=1
	ldp	q2, q3, [x10, #-96]
	fcvtzs.4s	v3, v3
	smin.4s	v3, v3, v0
	smax.4s	v3, v3, v1
	fcvtzs.4s	v2, v2
	smin.4s	v2, v2, v0
	smax.4s	v2, v2, v1
	ldp	q4, q5, [x10, #-128]
	uzp1.8h	v2, v2, v3
	fcvtzs.4s	v3, v5
	smin.4s	v3, v3, v0
	ldp	q5, q6, [x10, #-64]
	ldp	q7, q16, [x10, #-32]
	ldp	q17, q18, [x10]
	ldp	q19, q20, [x10, #32]
	ldp	q21, q22, [x10, #64]
	smax.4s	v3, v3, v1
	fcvtzs.4s	v4, v4
	smin.4s	v4, v4, v0
	smax.4s	v4, v4, v1
	uzp1.8h	v3, v4, v3
	uzp1.16b	v2, v3, v2
	fcvtzs.4s	v3, v16
	smin.4s	v3, v3, v0
	smax.4s	v3, v3, v1
	fcvtzs.4s	v4, v7
	smin.4s	v4, v4, v0
	smax.4s	v4, v4, v1
	ldp	q7, q16, [x10, #96]
	uzp1.8h	v3, v4, v3
	fcvtzs.4s	v4, v6
	smin.4s	v4, v4, v0
	smax.4s	v4, v4, v1
	fcvtzs.4s	v5, v5
	smin.4s	v5, v5, v0
	smax.4s	v5, v5, v1
	uzp1.8h	v4, v5, v4
	uzp1.16b	v3, v4, v3
	fcvtzs.4s	v4, v20
	smin.4s	v4, v4, v0
	smax.4s	v4, v4, v1
	fcvtzs.4s	v5, v19
	smin.4s	v5, v5, v0
	smax.4s	v5, v5, v1
	uzp1.8h	v4, v5, v4
	fcvtzs.4s	v5, v18
	smin.4s	v5, v5, v0
	smax.4s	v5, v5, v1
	fcvtzs.4s	v6, v17
	smin.4s	v6, v6, v0
	smax.4s	v6, v6, v1
	uzp1.8h	v5, v6, v5
	uzp1.16b	v4, v5, v4
	fcvtzs.4s	v5, v16
	smin.4s	v5, v5, v0
	smax.4s	v5, v5, v1
	fcvtzs.4s	v6, v7
	smin.4s	v6, v6, v0
	smax.4s	v6, v6, v1
	uzp1.8h	v5, v6, v5
	fcvtzs.4s	v6, v22
	smin.4s	v6, v6, v0
	smax.4s	v6, v6, v1
	fcvtzs.4s	v7, v21
	stp	q2, q3, [x11, #-32]
	smin.4s	v2, v7, v0
	smax.4s	v2, v2, v1
	uzp1.8h	v2, v2, v6
	uzp1.16b	v2, v2, v5
	stp	q4, q2, [x11], #64
	add	x10, x10, #256
	subs	x12, x12, #64
	b.ne	LBB0_6
; %bb.7:                                ; %middle.block
	cmp	x0, x8
	b.eq	LBB0_14
; %bb.8:                                ; %vec.epilog.iter.check
	cbz	x9, LBB0_12
LBB0_9:                                 ; %vec.epilog.ph
	mov	x11, x8
	and	x8, x0, #0xfffffffffffffffc
	sub	x9, x11, x8
	add	x10, x2, x11
	add	x11, x1, x11, lsl #2
	movi.4s	v0, #127
	mvni.4s	v1, #127
LBB0_10:                                ; %vec.epilog.vector.body
                                        ; =>This Inner Loop Header: Depth=1
	ldr	q2, [x11], #16
	fcvtzs.4s	v2, v2
	smin.4s	v2, v2, v0
	smax.4s	v2, v2, v1
	xtn.4h	v2, v2
	uzp1.8b	v2, v2, v0
	st1.s	{ v2 }[0], [x10], #4
	adds	x9, x9, #4
	b.ne	LBB0_10
; %bb.11:                               ; %vec.epilog.middle.block
	cmp	x0, x8
	b.eq	LBB0_14
LBB0_12:                                ; %body.preheader
	sub	x9, x0, x8
	add	x10, x2, x8
	mov	w11, #127                       ; =0x7f
	mov	w12, #-128                      ; =0xffffff80
	add	x8, x1, x8, lsl #2
LBB0_13:                                ; %body
                                        ; =>This Inner Loop Header: Depth=1
	ldr	s0, [x8], #4
	fcvtzs	w13, s0
	cmp	w13, #127
	csel	w13, w13, w11, lt
	cmn	w13, #128
	csel	w13, w13, w12, gt
	strb	w13, [x10], #1
	subs	x9, x9, #1
	b.ne	LBB0_13
LBB0_14:                                ; %exit
	ret
                                        ; -- End function
.subsections_via_symbols
