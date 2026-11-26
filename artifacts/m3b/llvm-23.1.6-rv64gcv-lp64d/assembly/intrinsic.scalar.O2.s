	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_v1p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvl128b1p0_zvl32b1p0_zvl64b1p0"
	.file	"intrinsic_sat_i8.ll"
	.text
	.globl	kernelforge_sat_i8_intrinsic    # -- Begin function kernelforge_sat_i8_intrinsic
	.p2align	1
	.type	kernelforge_sat_i8_intrinsic,@function
kernelforge_sat_i8_intrinsic:           # @kernelforge_sat_i8_intrinsic
# %bb.0:                                # %entry
	beqz	a0, .LBB0_3
# %bb.1:                                # %body.preheader
	lui	a3, 798720
	lui	a4, 274400
	fmv.w.x	fa5, a3
	fmv.w.x	fa4, a4
	add	a0, a0, a2
.LBB0_2:                                # %body
                                        # =>This Inner Loop Header: Depth=1
	flw	fa3, 0(a1)
	fmax.s	fa2, fa3, fa5
	fmin.s	fa2, fa2, fa4
	feq.s	a3, fa3, fa3
	fcvt.l.s	a4, fa2, rtz
	neg	a3, a3
	and	a3, a3, a4
	sb	a3, 0(a2)
	addi	a2, a2, 1
	addi	a1, a1, 4
	bne	a2, a0, .LBB0_2
.LBB0_3:                                # %exit
	ret
.Lfunc_end0:
	.size	kernelforge_sat_i8_intrinsic, .Lfunc_end0-kernelforge_sat_i8_intrinsic
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
	.addrsig
