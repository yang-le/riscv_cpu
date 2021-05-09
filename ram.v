
module ram #(
	parameter WIDTH = 32,
	parameter DEPTH = 1024
)(
	input clock,
	input write_en,
	input [$clog2(DEPTH) - 1:0] addr,
	input [WIDTH - 1:0] data_i,
	output [WIDTH - 1:0] data_o
);
    generic_ram #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) mem_inst (
        .clock(clock),
        .write_en(write_en),
        .addr(addr),
        .data_i(data_i),
        .data_o(data_o)
    );
endmodule
