# A Simple Riscv Verilog Implementation

## Intro
This is a simple riscv verilog implementation. It can be built successfully using Quartus 20.1 Lite and/or Verilator. It is also passed the [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test/tree/old-framework-2.x).

## Simulator Build
    cd sim
    make

## Test
You need to get [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test/tree/old-framework-2.x) and copy test into its riscv-target dir. Then

    cd riscv-arch-test
    RISCV_TARGET=test SIM_DIR=/PATH/TO/sim make

The test should all pass and output
    
    OK: 38/38 RISCV_TARGET=test RISCV_DEVICE=I XLEN=32

## Doc
Chinese document at [CSDN](https://blog.csdn.net/weixin_41871524/article/details/116890604).
