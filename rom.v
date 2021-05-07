
module rom #(
	parameter WORDSIZE = 4,
	parameter MEMSIZE = 32 * 1024,
	parameter DATAFILE = "data_file_not_defined"
)(
	input clock,
	input [$clog2(MEMSIZE) - 1:0] address,
	output [WORDSIZE * 8 - 1:0] data_o
);
    generic_mem #(
        .WORDSIZE(WORDSIZE),
        .MEMSIZE(MEMSIZE),
        .DATAFILE(DATAFILE)
    ) mem_inst (
        .clock(clock),
        .write_en(0),
        .read_en(1),
        .address(address),
        .data_i(0),
        .data_o(data_o)
    );
endmodule
