	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_v1p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvl128b1p0_zvl32b1p0_zvl64b1p0"
	.file	"manual_sat_i8.c"
	.text
	.globl	kernelforge_sat_i8_manual       # -- Begin function kernelforge_sat_i8_manual
	.p2align	1
	.type	kernelforge_sat_i8_manual,@function
kernelforge_sat_i8_manual:              # @kernelforge_sat_i8_manual
# %bb.0:
	beqz	a0, .LBB0_9
# %bb.1:
	lui	a3, 274400
	lui	a4, 798720
	fmv.w.x	fa5, a3
	fmv.w.x	fa4, a4
	add	a0, a0, a2
.LBB0_2:                                # =>This Inner Loop Header: Depth=1
	flw	fa2, 0(a1)
	feq.s	a3, fa2, fa2
	beqz	a3, .LBB0_8
# %bb.3:                                #   in Loop: Header=BB0_2 Depth=1
	flt.s	a3, fa5, fa2
	fmv.s	fa3, fa5
	bnez	a3, .LBB0_5
# %bb.4:                                #   in Loop: Header=BB0_2 Depth=1
	fmv.s	fa3, fa2
.LBB0_5:                                #   in Loop: Header=BB0_2 Depth=1
	flt.s	a3, fa3, fa4
	fmv.s	fa2, fa4
	bnez	a3, .LBB0_7
# %bb.6:                                #   in Loop: Header=BB0_2 Depth=1
	fmv.s	fa2, fa3
.LBB0_7:                                #   in Loop: Header=BB0_2 Depth=1
	fcvt.l.s	a3, fa2, rtz
.LBB0_8:                                #   in Loop: Header=BB0_2 Depth=1
	sb	a3, 0(a2)
	addi	a2, a2, 1
	addi	a1, a1, 4
	bne	a2, a0, .LBB0_2
.LBB0_9:
	ret
.Lfunc_end0:
	.size	kernelforge_sat_i8_manual, .Lfunc_end0-kernelforge_sat_i8_manual
                                        # -- End function
	.ident	"Homebrew clang version 23.1.6"
	.section	".note.GNU-stack","",@progbits
	.addrsig
