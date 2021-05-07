
module ram #(
	parameter WORDSIZE = 4,
	parameter MEMSIZE = 32 * 1024
)(
	input clock,
	input write_en,
    input read_en,
	input [$clog2(MEMSIZE) - 1:0] address,
	input [WORDSIZE * 8 - 1:0] data_i,
	output [WORDSIZE * 8 - 1:0] data_o
);
    generic_mem #(
        .WORDSIZE(WORDSIZE),
        .MEMSIZE(MEMSIZE)
    ) mem_inst (
        .clock(clock),
        .write_en(write_en),
        .read_en(read_en),
        .address(address),
        .data_i(data_i),
        .data_o(data_o)
    );
endmodule
