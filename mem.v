
module generic_ram #(
	parameter WIDTH = 8,
	parameter DEPTH = 32,
    parameter DATAFILE = ""
)(
	input clock,
	input write_en,
    input [$clog2(DEPTH) - 1:0] addr,
	input [WIDTH - 1:0] data_i,
	output [WIDTH - 1:0] data_o
);
    reg [WIDTH - 1:0] words[DEPTH - 1:0];

	initial begin: init
		integer i;
		for (i = 0; i < DEPTH; i = i + 1)
			words[i] = 0;
	end

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    endgenerate

    always @ (posedge clock) begin
		if (write_en)
            words[addr] <= data_i;
    end

    assign data_o = words[addr];
endmodule

module generic_ram_dp #(
	parameter WIDTH = 8,
	parameter DEPTH = 32,
    parameter DATAFILE = ""
)(
	input clock,
	input write_en,
	input [$clog2(DEPTH) - 1:0] addr_w,
    input [$clog2(DEPTH) - 1:0] addr_r1,
    input [$clog2(DEPTH) - 1:0] addr_r2,
	input [WIDTH - 1:0] data_i,
	output [WIDTH - 1:0] data_o1,
    output [WIDTH - 1:0] data_o2
);
    reg [WIDTH - 1:0] words[DEPTH - 1:0];

	initial begin: init
		integer i;
		for (i = 0; i < DEPTH; i = i + 1)
			words[i] = 0;
	end

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    endgenerate

    always @ (posedge clock) begin
		if (write_en)
            words[addr_w] <= data_i;
    end

    assign data_o1 = words[addr_r1];
    assign data_o2 = words[addr_r2];
endmodule

module generic_rom #(
	parameter WIDTH = 8,
	parameter DEPTH = 32,
    parameter DATAFILE = ""
)(
    input [$clog2(DEPTH) - 1:0] addr_r,
	output [WIDTH - 1:0] data_o
);
    reg [WIDTH - 1:0] words[DEPTH - 1:0];

	initial begin: init
		integer i;
		for (i = 0; i < DEPTH; i = i + 1)
			words[i] = 0;
	end

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    endgenerate

    assign data_o = words[addr_r];
endmodule
