
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
	.mtime(mtime_out),
	.mem_load(load),
	.mem_store(store),
	.store_data(store_data),
	.address(address),
    .pc(pc)
);

`ifdef VERILATOR
ram_dp #(
	.DEPTH(1024 * 1024),
	.BURST(XLEN / 16)
) mem_inst (
	.clock(clock),
    .write_en(store),
	.iaddr(pc[XLEN - 1:1]),
	.daddr(address[XLEN - 1:1]),
	.data_i(store_data),
	.data_o(load_data),
	.inst_o(inst)
);
`else
wire ram_cs;
wire [XLEN-1:0] ram_addr;
wire [XLEN-1:0] to_ram, from_ram;

ram2p mem_inst (
	.address_a(ram_addr),
	.address_b(pc[XLEN - 1:2]),
	.clock(~clock),
	.data_a(to_ram),
	//.data_b,
	.wren_a(ram_cs & store),
	//.wren_b(0),
	.q_a(from_ram),
	.q_b(inst)
);

wire uart_cs;
wire [XLEN - 1:0] uart_addr;
wire [7:0] to_uart, from_uart;

uart #(
	.CLOCK(25000000),
	.BAUD(115200)
) uart_inst (
	.clock(clock),
	.reset(reset),
	.wren(uart_cs & store),
    .addr(uart_addr),
	.data_i(to_uart),
	.data_o(from_uart),
	.rx(uart_rx),
	.tx(uart_tx)
);

wire timer_cs;
wire [XLEN - 1:0] timer_addr;
wire [63:0] to_timer, from_timer, mtime_out;

timer #(
	.CLOCK(25000000)
) timer_inst (
	.clock(clock),
	.reset(reset),
	.wren(timer_cs & store),
	.addr(timer_addr[1]),
	.data_i(to_timer),
	.data_o(from_timer),
	.mtime_out(mtime_out)
	//.output intr
);

addr_bus #(
	.XLEN(XLEN)
) addr_bus_inst (
	.address(address),
	.ram_cs(ram_cs),
	.ram_addr(ram_addr),
	.uart_cs(uart_cs),
	.uart_addr(uart_addr),
	.timer_cs(timer_cs),
	.timer_addr(timer_addr)
);

data_bus #(
	.XLEN(XLEN)
) data_bus_inst (
	.ram_cs(ram_cs),
	.ram_addr(ram_addr),
	.uart_cs(uart_cs),
	.uart_addr(uart_addr),
	.timer_cs(timer_cs),
	.timer_addr(timer_addr),
	.from_ram(from_ram),
	.from_uart(from_uart),
	.from_timer(from_timer),
	.from_cpu(store_data),
	.to_ram(to_ram),
	.to_uart(to_uart),
	.to_timer(to_timer),
	.to_cpu(load_data)
);
`endif
endmodule

module addr_bus #(
    parameter XLEN = 32,
	parameter RAM_SIZE = 32'h1000,
	parameter RAM_XLEN = 32,
	parameter UART_SIZE = 8,
	parameter UART_XLEN = 8,
	parameter TIMER_SIZE = 16,
	parameter TIMER_XLEN = XLEN
)(
    input [XLEN - 1:0] address,
	output ram_cs,
    output [XLEN - 1:$clog2(RAM_XLEN / 8)] ram_addr,
	output uart_cs,
	output [XLEN - 1:$clog2(UART_XLEN / 8)] uart_addr,
	output timer_cs,
	output [XLEN - 1:$clog2(TIMER_XLEN / 8)] timer_addr
);

localparam RAM_BASE = 0;
localparam UART_BASE = RAM_BASE + RAM_SIZE;
localparam TIMER_BASE = UART_BASE + UART_SIZE;

assign ram_cs = (RAM_BASE <= address) && (address < RAM_BASE + RAM_SIZE);
wire [XLEN - 1:0] ram_addr_b = address - RAM_BASE;
assign ram_addr = ram_addr_b[XLEN - 1:$clog2(RAM_XLEN / 8)];

assign uart_cs = (UART_BASE <= address) && (address < TIMER_BASE + UART_SIZE);
wire [XLEN - 1:0] uart_addr_b = address - UART_BASE;
assign uart_addr = uart_addr_b[XLEN - 1:$clog2(UART_XLEN / 8)];

assign timer_cs = (TIMER_BASE <= address) && (address < TIMER_BASE + TIMER_SIZE);
wire [XLEN - 1:0] timer_addr_b = address - TIMER_BASE;
assign timer_addr = timer_addr_b[XLEN - 1:$clog2(TIMER_XLEN / 8)];

endmodule

module data_bus #(
    parameter XLEN = 32,
	parameter RAM_XLEN = 32,
	parameter UART_XLEN = 8,
	parameter TIMER_XLEN = 64
)(
	input ram_cs,
	input [XLEN - 1:0] ram_addr,
	input uart_cs,
	input [XLEN - 1:0] uart_addr,
	input timer_cs,
	input [XLEN - 1:0] timer_addr,
	input [RAM_XLEN - 1:0] from_ram,
	input [UART_XLEN - 1:0] from_uart,
	input [TIMER_XLEN - 1:0] from_timer,
	input [XLEN - 1:0] from_cpu,
	output [RAM_XLEN - 1:0] to_ram,
	output [UART_XLEN - 1:0] to_uart,
	output [TIMER_XLEN - 1:0] to_timer,
	output [XLEN - 1:0] to_cpu
);

assign to_ram = from_cpu;

wire [XLEN - 1:0] uart_shift = uart_addr[$clog2(XLEN / 8) - 1:0] * 8;
assign to_uart = from_cpu >> uart_shift;

wire [XLEN - 1:0] timer_data;
generate if (XLEN == 64) begin
assign to_timer = from_cpu;
assign timer_data = from_timer;
end else
assign to_timer = timer_addr[0] ? from_cpu << 32 : from_cpu;
assign timer_data = timer_addr[0] ? from_timer[63:32] : from_timer[31:0];
endgenerate

assign to_cpu = ram_cs ? from_ram :
				uart_cs ? (from_uart << uart_shift) :
				timer_cs ? timer_data : 0;
endmodule
