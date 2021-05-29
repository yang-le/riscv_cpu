`ifndef VERILATOR

`include "defines.vh"
`timescale 1ns/1ps
`define CYCLE   40

module testbench();

localparam HCYCLE = `CYCLE / 2;

reg clock;
reg reset;

// 25MHz clock
always begin
    clock = 1; # HCYCLE;
    clock = 0; # HCYCLE;
end

// reset
initial begin
   reset = 0; # HCYCLE;
   reset = 1; # `CYCLE;
   reset = 0;
end

top dut(
    .clock(clock),
    .reset(reset)
);

endmodule

`endif
