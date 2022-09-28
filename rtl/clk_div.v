module clk_div #(
	parameter IN = 25000000,
	parameter OUT = 115200,
	parameter XLEN = 16
)(
	input in,
	output out
);

localparam STEP = ((OUT << (XLEN - 4)) + (IN >> 5)) / (IN >> 4);

reg [XLEN:0] counter;

always @(posedge in)
	counter <= counter[XLEN - 1:0] + STEP;

assign out = counter[XLEN];

endmodule
