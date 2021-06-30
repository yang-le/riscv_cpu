
module generic_ram #(
	parameter WIDTH = 8,
	parameter DEPTH = 32,
    parameter DATAFILE = "",
    parameter READ_OLD = 1
)(
	input clock,
	input write_en,
    input [$clog2(DEPTH) - 1:0] addr,
	input [WIDTH - 1:0] data_i,
	output [WIDTH - 1:0] data_o
);
    reg [WIDTH - 1:0] words[DEPTH - 1:0];

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    else
        initial begin: init
            integer i;
            for (i = 0; i < DEPTH; i = i + 1)
                words[i] = 0;
        end
    endgenerate

    always @ (posedge clock) begin
		if (write_en)
            words[addr] <= data_i;
    end
    
    generate if (READ_OLD)
        assign data_o = words[addr];
    else
        assign data_o = write_en ? data_i : words[addr];
    endgenerate
endmodule

module generic_ram_dp #(
	parameter WIDTH = 8,
	parameter DEPTH = 32,
    parameter BURST = 1,
    parameter DATAFILE = "",
    parameter READ_OLD = 1
)(
	input clock,
	input write_en,
	input [$clog2(DEPTH) - 1:0] addr_w,
    input [$clog2(DEPTH) - 1:0] addr_r1,
    input [$clog2(DEPTH) - 1:0] addr_r2,
	input [WIDTH * BURST - 1:0] data_i,
	output [WIDTH * BURST - 1:0] data_o1,
    output [WIDTH * BURST - 1:0] data_o2
);
    reg [WIDTH - 1:0] words[DEPTH - 1:0];

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    else
        initial begin: init
            integer i;
            for (i = 0; i < DEPTH; i = i + 1)
                words[i] = 0;
        end
    endgenerate

    reg [WIDTH * BURST - 1:0] old_data1, old_data2;
    generate if (BURST > 1) begin
        integer i;
        always @ (posedge clock) if (write_en)
            for (i = 0; i < BURST; i = i + 1)
                words[addr_w + i] <= data_i[i * WIDTH +: WIDTH];

        always @(*) for (i = 0; i < BURST; i = i + 1) begin
            old_data1[i * WIDTH +: WIDTH] = words[addr_r1 + i];
            old_data2[i * WIDTH +: WIDTH] = words[addr_r2 + i];
        end
    end else begin
        always @ (posedge clock) if (write_en)
                words[addr_w] <= data_i;
        
        always @(*) begin
            old_data1 = words[addr_r1];
            old_data2 = words[addr_r2];
        end
    end endgenerate

    generate if (READ_OLD) begin
        assign data_o1 = old_data1;
        assign data_o2 = old_data2;
    end else begin
        assign data_o1 = (write_en && addr_w == addr_r1) ? data_i : old_data1;
        assign data_o2 = (write_en && addr_w == addr_r2) ? data_i : old_data2;
    end endgenerate
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

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    else
        initial begin: init
            integer i;
            for (i = 0; i < DEPTH; i = i + 1)
                words[i] = 0;
        end
    endgenerate

    assign data_o = words[addr_r];
endmodule
