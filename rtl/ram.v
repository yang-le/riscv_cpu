
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

module ram_dp #(
	parameter WIDTH = 32,
	parameter DEPTH = 1024,
    parameter BURST = 1,
    parameter DATAFILE = ""
)(
	input clock,
	input write_en,
	input [$clog2(DEPTH) - 1:0] iaddr,
    input [$clog2(DEPTH) - 1:0] daddr,
	input [WIDTH * BURST - 1:0] data_i,
	output [WIDTH * BURST - 1:0] data_o,
    output [WIDTH * BURST - 1:0] inst_o
);
    generic_ram_dp #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .BURST(BURST),
        .DATAFILE(DATAFILE)
    ) mem_inst (
        .clock(clock),
        .write_en(write_en),
        .addr_w(daddr),
        .addr_r1(daddr),
        .addr_r2(iaddr),
        .data_i(data_i),
        .data_o1(data_o),
        .data_o2(inst_o)
    );
endmodule
