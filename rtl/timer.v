module timer #(
	parameter CLOCK = 25000000
)(
	input clock,
	input reset,
	input wren,
	input addr,
	input [63:0] data_i,
	output [63:0] data_o,
	output [63:0] mtime_out,
	output intr
);

wire [63:0] mtimecmp_out;

timer_core #(
	.CLOCK(CLOCK)
) timer_core_inst (
	.clock(clock),
	.reset(reset),
	.mtime_in(data_i),
	.mtimecmp_in(data_i),
	.wtime(wren & ~addr),
	.wtimecmp(wren & addr),
	.mtime_out(mtime_out),
	.mtimecmp_out(mtimecmp_out),
	.intr(intr)
);

assign data_o = addr ? mtimecmp_out : mtime_out;

endmodule

module timer_core #(
	parameter CLOCK = 25000000
)(
	input clock,
	input reset,
	input [63:0] mtime_in,
	input [63:0] mtimecmp_in,
	input wtime,
	input wtimecmp,
	output [63:0] mtime_out,
	output [63:0] mtimecmp_out,
	output intr
);

reg [63:0] mtime, mtimecmp;

always @(posedge clock or negedge reset)
	if (~reset)
		mtime <= 0;
	else if (wtime)
		mtime <= mtime_in;
	else
		mtime <= mtime + 1000000000 / CLOCK;

always @(posedge clock or negedge reset)
	if (~reset)
		mtimecmp <= 0;
	else if (wtimecmp)
		mtimecmp <= mtimecmp_in;
	else
		mtimecmp <= mtimecmp;

assign mtime_out = mtime;
assign mtimecmp_out = mtimecmp;
assign intr = (mtimecmp >= mtime);

endmodule
