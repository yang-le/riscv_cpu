
module rom #(
	parameter WIDTH = 32,
	parameter DEPTH = 1024,
	parameter DATAFILE = ""
)(
	input [$clog2(DEPTH) - 1:0] addr,
	output [WIDTH - 1:0] data_o
);
    generic_rom #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .DATAFILE(DATAFILE)
    ) mem_inst (
        .addr_r(addr),
        .data_o(data_o)
    );
endmodule
