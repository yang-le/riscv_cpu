`timescale 1ns/1ps

module testbench();

reg clock;
reg reset;

// 25MHz clock
always begin
    clock = 0; #40;
    clock = 1; #40;
end

// reset
initial begin
   reset = 0; #40;
   reset = 1;
end

top dut(
    .clock(clock),
    .reset(reset)
);

endmodule
