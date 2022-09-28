module uart #(
	parameter CLOCK = 25000000,
	parameter BAUD = 115200,
	parameter DBIT = 8,
	parameter SBIT = 1,
	parameter CHECK = 0
)(
	input clock,
	input reset,
	input wren,
    input [2:0] addr,
	input [7:0] data_i,
	output [7:0] data_o,
	input rx,
	output tx
);

localparam CTRL = 0;
localparam TXD = 1;
localparam RXD = 2;
localparam BDL = 3;
localparam BDH = 4;
localparam NUM = 5;

localparam TX_ENABLE = 0;
localparam TX_READY = 1;
localparam TX_VALID = 2;
localparam RX_ENABLE = 4;
localparam RX_READY = 5;
localparam RX_VALID = 6;

wire tx_ready;
reg [7:0] regs[NUM - 1:0];

integer i;
always @(posedge clock or negedge reset) begin
	if (~reset)
		for (i = 0; i < NUM; i = i + 1)
			regs[i] = 0;
	else begin
		if (wren)
			regs[addr] <= data_i;
		regs[CTRL][TX_READY] <= tx_ready;
	end
end

assign data_o = regs[addr];

uart_core #(
	.CLOCK(CLOCK),
	.BAUD(BAUD),
	.DBIT(DBIT),
	.SBIT(SBIT),
	.CHECK(CHECK)
) uart_inst (
	.clk(regs[CTRL][TX_ENABLE] & clock),
	.reset(reset),
	.tx_data(regs[TXD]),
	.tx_valid(regs[CTRL][TX_VALID]),
	.tx_ready(tx_ready),
	.tx(tx)
);

endmodule

module uart_core #(
	parameter CLOCK = 25000000,
	parameter BAUD = 115200,
	parameter DBIT = 8,
	parameter SBIT = 1,
	parameter CHECK = 0
)(
	input clk,
	input reset,
	input [DBIT - 1:0] tx_data,
	input tx_valid,
	output tx_ready,
	output tx,
	output [DBIT - 1:0] rx_data,
	output rx_valid,
	input rx_ready,
	input rx
);

wire baud_clk;

clk_div #(
	.IN(CLOCK),
	.OUT(BAUD)
) clk_div_inst (
	.in(clk),
	.out(baud_clk)
);

uart_tx #(
	.DBIT(DBIT),
	.SBIT(SBIT),
	.CHECK(CHECK)
) uart_tx_inst (
	.clk(baud_clk),
	.reset(reset),
	.data(tx_data),
	.valid(tx_valid),
	.ready(tx_ready),
	.tx(tx)
);

endmodule

module uart_tx #(
	parameter DBIT = 8,
	parameter SBIT = 1,
	parameter CHECK = 0
)(
	input clk,
	input reset,
	input [DBIT - 1:0] data,
	input valid,
	output reg tx,
	output reg ready
);

localparam S_START = 4'd0;
localparam S_STOP = 4'd9;
localparam S_IDEL = 4'd10;

reg [3:0] state, n_state;

always @(posedge clk)
	if (~reset)
		state <= S_IDEL;
	else
		state <= n_state;

always @(*) case (state)
	DBIT: begin
		n_state = S_STOP;
		tx = 1;
		ready = 0;
	end
	S_STOP: begin
		n_state = valid ? S_START : S_IDEL;
		tx = ~valid;
		ready = 1;
	end
	S_IDEL: begin
		n_state = valid ? S_START : S_IDEL;
		tx = ~valid;
		ready = ~valid;
	end
	default: begin
		n_state = state + 1;
		tx = data[state];
		ready = 0;
	end
endcase

endmodule
