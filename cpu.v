`include "defines.vh"

module cpu (
	input clock,
	input reset,
	input [31:0] load_data,
	input [31:0] inst,
	output load,
	output store,
	output [31:0] store_data,
	output [31:0] address,
	output [31:0] pc
);

wire [4:0] address_w;
wire [4:0] address_r1;
wire [4:0] address_r2;
wire [31:0] data_r1;
wire [31:0] data_r2;

wire [31:0] next_pc;
wire [31:0] imm;
wire [6:0] opcode;
wire [14:12] funct3;
wire [31:25] funct7;

wire s_pc;
wire s_imm;
wire [3:0] alu_op;
wire [2:0] itype;
wire s_jalr;
wire s_jump;
wire s_branch;
wire s_branch_zero;
wire s_csr;
wire s_csri;
wire s_csrsc;
wire alu_z;
wire [31:0] alu_o;
wire [31:0] csr_o;

regfile regs (
	.clock(clock),
	.address_w(address_w),
	.address_r1(address_r1),
	.address_r2(address_r2),
	.data_w(load ? load_data :
			s_jump ? next_pc :
			s_csr ? csr_o : alu_o),
	.data_r1(data_r1),
	.data_r2(data_r2)
);

csr csr_inst(
	.clock(clock),
	.s_csr(s_csr),
    .s_csrsc(s_csrsc),
    .rs1(address_r1),
	.address(imm),
	.data_w(alu_o),
	.data_r(csr_o)
);

pc pc_inst(
	.clock(clock),
	.reset(reset),
    .alu_o(alu_o),
    .alu_z(alu_z),
    .s_jump(s_jump),
    .s_jalr(s_jalr),
    .s_branch(s_branch),
    .s_branch_zero(s_branch_zero),
    .imm(imm),
    .pc(pc),
	.next_pc(next_pc)
);

decoder decoder_inst (
`ifdef DEBUG
	.clock(clock),
`endif
    .inst(inst),
    .opcode(opcode),
    .rd(address_w),
    .funct3(funct3),
    .rs1(address_r1),
    .rs2(address_r2),
    .funct7(funct7),
    .imm(imm),
    .s_pc(s_pc),
    .s_imm(s_imm),
    .alu_op(alu_op),
	.itype(itype),
	.s_jalr(s_jalr),
	.s_jump(s_jump),
	.s_branch(s_branch),
	.s_branch_zero(s_branch_zero),
	.s_load(load),
	.s_store(store),
	.s_csr(s_csr),
	.s_csri(s_csri),
	.s_csrsc(s_csrsc)
);

alu alu_inst(
	.rs1(s_pc ? pc : s_csri ? address_r1 : data_r1),
	.rs2(s_csrsc ? csr_o : s_imm ? imm : data_r2),
	.opcode(alu_op),
	.rd(alu_o),
	.zero(alu_z)
);

assign store_data = store ? data_r2 : 0;
assign address = (load || store) ? alu_o : 0;

endmodule
