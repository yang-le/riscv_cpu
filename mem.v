
module generic_mem #(
	parameter WORDSIZE = 4,
	parameter MEMSIZE = 32 * 1024,
	parameter DATAFILE = ""
)(
	input clock,
	input write_en,
    input read_en,
	input [$clog2(MEMSIZE) - 1:0] address,
	input [WORDSIZE * 8 - 1:0] data_i,
	output reg [WORDSIZE * 8 - 1:0] data_o
);
	localparam NWORDS = MEMSIZE / WORDSIZE;
	wire [$clog2(NWORDS) - 1:0] addr_w = address[$clog2(MEMSIZE) - 1:$clog2(WORDSIZE)];
    reg [WORDSIZE * 8 - 1:0] words[NWORDS - 1:0];

    generate if (DATAFILE)
        initial begin
            $readmemh(DATAFILE, words);
        end
    endgenerate

    always @ (posedge clock) begin
		if (write_en)
            words[addr_w] <= data_i;
        if (read_en)
            data_o <= words[addr_w];
    end
endmodule
