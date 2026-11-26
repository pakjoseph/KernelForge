	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_v1p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvl128b1p0_zvl32b1p0_zvl64b1p0"
	.file	"manual_sat_i8.c"
	.text
	.globl	kernelforge_sat_i8_manual       # -- Begin function kernelforge_sat_i8_manual
	.p2align	1
	.type	kernelforge_sat_i8_manual,@function
kernelforge_sat_i8_manual:              # @kernelforge_sat_i8_manual
# %bb.0:
	beqz	a0, .LBB0_3
# %bb.1:
	lui	a3, 274400
	lui	a4, 798720
	fmv.w.x	fa5, a3
	fmv.w.x	fa4, a4
	li	a5, 0
.LBB0_2:                                # =>This Inner Loop Header: Depth=1
	vsetvli	a6, a0, e32, m2, ta, ma
	slli	a7, a5, 2
	add	a7, a7, a1
	vle32.v	v10, (a7)
	vmfgt.vf	v0, v10, fa5
	vmerge.vxm	v12, v10, a3, v0
	vmflt.vf	v0, v12, fa4
	vmfne.vv	v8, v10, v10
	vmerge.vxm	v10, v12, a4, v0
	vsetvli	zero, zero, e16, m1, ta, ma
	vfncvt.rtz.x.f.w	v9, v10
	vsetvli	zero, zero, e8, mf2, ta, ma
	vnsrl.wi	v9, v9, 0
	vmv1r.v	v0, v8
	vmerge.vim	v8, v9, 0, v0
	add	a7, a2, a5
	sub	a0, a0, a6
	vse8.v	v8, (a7)
	add	a5, a5, a6
	bnez	a0, .LBB0_2
.LBB0_3:
	ret
.Lfunc_end0:
	.size	kernelforge_sat_i8_manual, .Lfunc_end0-kernelforge_sat_i8_manual
                                        # -- End function
	.ident	"Homebrew clang version 23.1.6"
	.section	".note.GNU-stack","",@progbits
	.addrsig
