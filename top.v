
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

cpu cpu_inst (
	.clock(clock),
	.reset(reset),
	.load_data(load_data),
    .inst(inst),
	.load(load),
	.store(store),
	.store_data(store_data),
	.address(address),
    .pc(pc)
);

ram ram_inst (
	.clock(clock),
    .write_en(store),
	.address(address),
	.data_i(store_data),
	.data_o(load_data)
);

rom #(
    .DATAFILE("data.txt")
) rom_inst (
	.clock(clock),
	.address(pc),
	.data_o(inst)
);

endmodule