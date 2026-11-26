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
# %bb.1:                                # %vector.body.preheader
	li	a3, 0
.LBB0_2:                                # %vector.body
                                        # =>This Inner Loop Header: Depth=1
	vsetvli	a4, a0, e32, m2, ta, ma
	slli	a5, a3, 2
	add	a5, a5, a1
	vle32.v	v8, (a5)
	vmfne.vv	v0, v8, v8
	vsetvli	zero, zero, e16, m1, ta, ma
	vfncvt.rtz.x.f.w	v10, v8
	vsetvli	zero, zero, e8, mf2, ta, ma
	vnclip.wi	v8, v10, 0
	vmerge.vim	v8, v8, 0, v0
	add	a5, a2, a3
	sub	a0, a0, a4
	vse8.v	v8, (a5)
	add	a3, a3, a4
	bnez	a0, .LBB0_2
.LBB0_3:                                # %exit
	ret
.Lfunc_end0:
	.size	kernelforge_sat_i8_intrinsic, .Lfunc_end0-kernelforge_sat_i8_intrinsic
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
	.addrsig
