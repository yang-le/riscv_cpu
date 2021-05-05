`include "defines.vh"

module csr #(
	parameter WIDTH = 32,
	parameter NUM = 2 ** 12
)(
	input clock,
	input s_csr,
    input s_csrsc,
    input [4:0] rs1,
	input [$clog2(NUM) - 1:0] address,
	input [WIDTH - 1:0] data_w,
	output [WIDTH - 1:0] data_r
);

    wire write_en = s_csr && (!s_csrsc || |rs1);
	reg [WIDTH - 1:0] regfile[NUM - 1:0];

`ifdef SIM
	integer i;
	initial begin
		for (i = 0; i < NUM; i = i + 1)
			regfile[i] = 0;
	end
`endif

	always @ (posedge clock) begin
		if (write_en)
			regfile[address] <= data_w;
	end

	assign data_r = regfile[address];
endmodule
