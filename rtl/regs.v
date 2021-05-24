
module regs #(
	parameter WIDTH = 32,
	parameter NUM = 32
)(
	input clock,
	input [$clog2(NUM) - 1:0] addr_w,
	input [$clog2(NUM) - 1:0] addr_r1,
	input [$clog2(NUM) - 1:0] addr_r2,
	input [WIDTH - 1:0] data_w,
	output [WIDTH - 1:0] data_r1,
	output [WIDTH - 1:0] data_r2
);
    generic_ram_dp #(
        .WIDTH(WIDTH),
        .DEPTH(NUM)
    ) mem_inst (
        .clock(clock),
        .write_en(|addr_w),
        .addr_w(addr_w),
        .addr_r1(addr_r1),
        .addr_r2(addr_r2),
        .data_i(data_w),
        .data_o1(data_r1),
        .data_o2(data_r2)
    );
endmodule
