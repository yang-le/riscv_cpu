
module top(
	input clock,
	input reset
);

wire[31:0] load_data;
wire[31:0] inst;
wire load;
wire store;
wire [31:0] store_data;
wire [31:0] address;
wire [31:0] pc;

`ifdef VERILATOR
localparam TEST_BASE = 32'h20000000;
localparam ADDR_HALT = TEST_BASE + 0;
localparam ADDR_SIG_BEGIN = TEST_BASE + 4;
localparam ADDR_SIG_END = TEST_BASE + 8;

string data_file = 0, dump_file = 0;
reg [31:0] sig_begin = 0, sig_end = 0;

initial begin
	if ($value$plusargs("data_file=%s", data_file))
		$readmemh(data_file, mem_inst.mem_inst.words);

	$value$plusargs("dump_file=%s", dump_file);
end

always @(posedge clock) begin
	if (store && address == ADDR_HALT && store_data == 1) begin
		if (dump_file != 0) begin
			$display("dump: %x - %x", sig_begin, sig_end);
			$writememh(dump_file, mem_inst.mem_inst.words, sig_begin, sig_end);
		end
		$finish;
	end

	if (store && address == ADDR_SIG_BEGIN) begin
		$display("sig_begin: %x", store_data);
		sig_begin <= store_data >> 2;
	end
	if (store && address == ADDR_SIG_END) begin
		$display("sig_end: %x", store_data);
		sig_end <= (store_data >> 2) - 1;
	end
end
`endif

cpu #(
	.ENABLE_MUL(1),
	.ENABLE_DIV(1)
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
`ifdef ROM
ram ram_inst (
	.clock(clock),
    .write_en(store),
	.addr(address[31:2]),
	.data_i(store_data),
	.data_o(load_data)
);

rom rom_inst (
	.addr(pc[31:2]),
	.data_o(inst)
);
`else
ram_dp
`ifdef VERILATOR
#(.DEPTH(1024 * 1024))
`endif
mem_inst (
	.clock(clock),
    .write_en(store),
	.iaddr(pc[31:2]),
	.daddr(address[31:2]),
	.data_i(store_data),
	.data_o(load_data),
	.inst_o(inst)
);
`endif
endmodule
