`include "defines.vh"

module cpu #(
	parameter XLEN = 32
)(
	input clock,
	input reset,
	input [XLEN - 1:0] load_data,
	input [XLEN - 1:0] inst,
	output mem_load,
	output mem_store,
	output [XLEN - 1:0] store_data,
	output [XLEN - 1:0] address,
	output [XLEN - 1:0] pc
);

wire [2:0] itype;
wire [2:0] funct3;
wire [6:0] funct7;
wire [6:0] opcode;

// IF_ID
wire [XLEN - 1:0] id_pc, ex_pc;						// use by alu
wire [XLEN - 1:0] id_inst;							// use by decode

// ID_EX		
wire [4:0] rd, ex_rd, mem_rd, wb_rd;				// use by stage WB
wire [4:0] rs1, rs2;								// use by regs
wire [XLEN - 1:0] id_rs1, ex_rs1, id_rs2, ex_rs2;	// use by forward
wire [XLEN - 1:0] id_imm, ex_imm;					// use by alu
wire [4:0] ex_rs1_imm;								// use by alu for csr

// EX_MEM
wire [XLEN - 1:0] mem_rs2;							// store data
wire [XLEN - 1:0] mem_alu;							// store/load address

// MEM_WB
wire [XLEN - 1:0] wb_alu;							// write back to regs

// control EX	
wire [3:0] id_alu_op, ex_alu_op;					// use by alu
wire s_pc, ex_s_pc, s_imm, ex_s_imm;				// use by alu
wire s_jalr, s_jump, s_branch, s_branch_zero;		// use by addr_gen
wire ex_jalr, ex_jump, ex_branch, ex_branch_zero;	// use by addr_gen
wire s_csr, s_csri, s_csrsc;						// use by csr
wire ex_csr, ex_csri, ex_csrsc;						// use by csr

// control MEM
wire s_store, ex_store;

// control WB
wire s_load, ex_load, wb_load;

// stage IF
wire s_npc, bubble;
wire [XLEN - 1:0] npc;
pc pc_inst(
	.clock(clock),
	.reset(reset),
	.pause(bubble),
	.s_npc(s_npc),
    .npc(npc),
	.pc(pc)
);

if_id # (
	.BYPASS(0)
) if_id_inst (
	.clock(clock),
	.bubble(bubble),
	.pc_in(pc),
	.inst_in(inst),
	.pc_out(id_pc),
	.inst_out(id_inst)
);

// stage ID
hazard hazard_inst(
	.id_jump(s_jump),
    .ex_load(ex_load),
    .ex_rd(ex_rd),
    .rs1(rs1),
    .rs2(rs2),
    .bubble(bubble)
);

decoder decoder_inst (
`ifdef DEBUG
	.clock(clock),
`endif
    .inst(id_inst),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7),
    .imm(id_imm),
	.s_pc(s_pc),
    .s_imm(s_imm),
    .alu_op(id_alu_op),
	.itype(itype),
	.s_jump(s_jump),
	.s_jalr(s_jalr),
	.s_branch(s_branch),
	.s_branch_zero(s_branch_zero),
	.s_load(s_load),
	.s_store(s_store),
	.s_csr(s_csr),
	.s_csri(s_csri),
	.s_csrsc(s_csrsc)
);

id_ex # (
	.BYPASS(0)
) id_ex_inst (
	.clock(clock),
	.bubble(bubble),
	.rd_in(rd),
	.rs1_imm_in(rs1),
	.pc_in(id_pc),
	.rs1_in(id_rs1),
	.rs2_in(id_rs2),
	.imm_in(id_imm),
	.ctrl_in({id_alu_op, s_pc, s_imm, s_jalr, s_branch, s_branch_zero, s_csr, s_csri, s_csrsc, s_jump, s_store, s_load}),
	.rd_out(ex_rd),
	.rs1_imm_out(ex_rs1_imm),
	.pc_out(ex_pc),
	.rs1_out(ex_rs1),
	.rs2_out(ex_rs2),	
	.imm_out(ex_imm),
	.ctrl_out({ex_alu_op, ex_s_pc, ex_s_imm, ex_jalr, ex_branch, ex_branch_zero, ex_csr, ex_csri, ex_csrsc, ex_jump, ex_store, ex_load})
);

// stage EX
wire [XLEN - 1:0] f_rs1, f_rs2;
wire [XLEN - 1:0] wb_rd_reg = wb_load ? load_data : wb_alu;
forward forward_inst (
    .mem_rd(mem_rd),
    .wb_rd(wb_rd),
    .rs1(rs1),
    .rs2(rs2),
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    .mem_rd_reg(mem_alu),
    .wb_rd_reg(wb_rd_reg),
    .rs1_reg(f_rs1),
    .rs2_reg(f_rs2)
);

wire alu_z;
wire [XLEN - 1:0] alu_o, csr_o;
alu alu_inst(
	.rs1(ex_csri ? ex_rs1_imm : ex_s_pc? ex_pc : f_rs1),
	.rs2(ex_csr ? csr_o : ex_s_imm ? ex_imm : f_rs2),
	.opcode(ex_alu_op),
	.rd(alu_o),
	.zero(alu_z)
);

wire [XLEN - 1:0] next_pc;
addr_gen addr_gen_inst (
    .alu_z(alu_z),
    .s_jump(ex_jump),
    .s_jalr(ex_jalr),
    .s_branch(ex_branch),
    .s_branch_zero(ex_branch_zero),
    .pc(ex_pc),
    .imm(ex_imm),
    .alu_o(alu_o),
	.s_npc(s_npc),
	.npc(npc),
	.next_pc(next_pc)
);

csr csr_inst(
	.clock(clock),
	.s_csr(ex_csr),
    .s_csrsc(ex_csrsc),
    .rs1(ex_rs1_imm),
	.addr(ex_imm),
	.data_w(alu_o),
	.data_r(csr_o)
);

ex_mem # (
	.BYPASS(0)
) ex_mem_inst (
	.clock(clock),
	.bubble(bubble),
	.rd_in(ex_rd),
	.rs2_in(ex_rs2),
	.alu_in(ex_csr ? csr_o : ex_jump ? next_pc : alu_o),
	.ctrl_in({ex_store, ex_load}),
	.rd_out(mem_rd),
	.rs2_out(mem_rs2),
	.alu_out(mem_alu),
	.ctrl_out({mem_store, mem_load})
);

// stage MEM
assign store_data = mem_rs2;
assign address = mem_alu;

mem_wb #(
	.BYPASS(0)
) mem_wb_inst (
	.clock(clock),
	.bubble(bubble),
	.rd_in(mem_rd),
	.alu_in(mem_alu),
	.ctrl_in({mem_load}),
	.rd_out(wb_rd),
	.alu_out(wb_alu),
	.ctrl_out({wb_load})
);

// stage WB
regs regs_inst (
	.clock(clock),
	.addr_w(wb_rd),
	.addr_r1(rs1),
	.addr_r2(rs2),
	.data_w(wb_rd_reg),
	.data_r1(id_rs1),
	.data_r2(id_rs2)
);

endmodule
