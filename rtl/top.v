
module top(
	input clock,
	input reset,
	input uart_rx,
	output uart_tx
);

`ifdef XLEN
localparam XLEN = `XLEN;
`else
localparam XLEN = 32;
`endif

wire load, store;
wire [XLEN - 1:0] load_data, store_data, inst, address, pc;
wire [XLEN - 1:0] rx_data, tx_data;

`ifdef VERILATOR
localparam ADDR_HALT = 32'h20000000;
localparam ADDR_SIG_BEGIN = ADDR_HALT + XLEN / 8;
localparam ADDR_SIG_END = ADDR_SIG_BEGIN + XLEN / 8;

string data_file = 0, dump_file = 0;
reg [XLEN - 1:0] sig_begin = 0, sig_end = 0;

initial begin
	if ($value$plusargs("data_file=%s", data_file))
		$readmemh(data_file, mem_inst.mem_inst.words);

	$value$plusargs("dump_file=%s", dump_file);
end

always @(posedge clock) begin
	if (store && address == ADDR_HALT && store_data[31:0] == 1) begin
		if (dump_file != 0) begin
			$display("dump: %x - %x", sig_begin, sig_end);
			$writememh(dump_file, mem_inst.mem_inst.words, sig_begin, sig_end);
		end
		$finish;
	end

	if (store && address == ADDR_SIG_BEGIN) begin
		$display("sig_begin: %x", store_data[31:0]);
		sig_begin <= store_data[31:0] / 2;
	end
	if (store && address == ADDR_SIG_END) begin
		$display("sig_end: %x", store_data[31:0]);
		sig_end <= (store_data[31:0] / 2) - 1;
	end
end
`endif

cpu #(
	.XLEN(XLEN),
	.ENABLE_MUL(1),
	.ENABLE_DIV(1),
	.ENABLE_RVC(1)
)cpu_inst (
	.clock(clock),
	.reset(reset),
	.load_data(load_data),
    .inst(inst),
	.mem_load(load),
	.mem_store(store),
	.store_data(store_data),
	.address(address),
    .pc(pc)
);

wire [XLEN-1:0] mem_data;
wire mem_cs = address[XLEN - 1:12] == 0;

`ifdef VERILATOR
ram_dp #(
	.DEPTH(1024 * 1024),
	.BURST(XLEN / 16)
) mem_inst (
	.clock(clock),
    .write_en(mem_cs & store),
	.iaddr(pc[XLEN - 1:1]),
	.daddr(address[XLEN - 1:2]),
	.data_i(store_data),
	.data_o(mem_data),
	.inst_o(inst)
);
`else
ram2p mem_inst (
	.address_a(address[XLEN - 1:2]),
	.address_b(pc[XLEN - 1:2]),
	.clock(~clock),
	.data_a(store_data),
	//.data_b,
	.wren_a(mem_cs & store),
	//.wren_b(0),
	.q_a(mem_data),
	.q_b(inst)
);
`endif

localparam UART_BASE = 32'h1000;
wire [7:0] uart_data;
wire [XLEN - 1:0] uart_shift = address[$clog2(XLEN / 8) - 1:0] * 8;
wire uart_cs = address[XLEN - 1:3] == (UART_BASE >> 3);

uart #(
	.CLOCK(25000000),
	.BAUD(115200)
) uart_inst (
	.clock(clock),
	.reset(reset),
	.wren(uart_cs & store),
    .addr(address),
	.data_i(store_data >> uart_shift),
	.data_o(uart_data),
	.rx(uart_rx),
	.tx(uart_tx)
);

assign load_data = mem_cs ? mem_data : uart_cs ? (uart_data << uart_shift) : 0;

endmodule
