  .section .text.startup,"ax",@progbits
  .globl _start
  .type _start,@function
_start:
  li sp, 0x80200000
  /* Bare-metal entry must enable scalar FP and vector architectural state. */
  li t0, 0x6600
  csrs mstatus, t0
  call m3b_test
  li t0, 0x00100000
  beqz a0, 1f
  li t1, 0x3333
  sw t1, 0(t0)
2:
  j 2b
1:
  li t1, 0x5555
  sw t1, 0(t0)
3:
  j 3b
  .size _start, .-_start
