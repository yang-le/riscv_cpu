
module regfile #(
	parameter WIDTH = 32,
	parameter NUM = 32
)(
	input clock,
	input reset,
	input [$clog2(NUM) - 1:0]address_w,
	input [$clog2(NUM) - 1:0]address_r1,
	input [$clog2(NUM) - 1:0]address_r2,
	input [WIDTH - 1:0] data_w,
	output [WIDTH - 1:0] data_r1,
	output [WIDTH - 1:0] data_r2
);

	wire write_en = |address_w;
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
			regfile[address_w] <= data_w;
	end

	assign data_r1 = regfile[address_r1];
	assign data_r2 = regfile[address_r2];

endmodule
