.section .init, "ax"
.global _start
_start:
    .cfi_startproc
    .cfi_undefined ra
    la sp, __stack_top
    add s0, sp, zero
    call main
halt:
    wfi
    j halt
    .cfi_endproc
    .end
