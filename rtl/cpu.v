`include "defines.vh"

module cpu #(
	parameter XLEN = 32,
	parameter ENABLE_MUL = 0,
	parameter ENABLE_DIV = 0
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
wire [XLEN - 1:0] id_pc, ex_pc, mem_pc;				// use by alu
wire [31:0] if_inst,id_inst;						// use by decode

// ID_EX		
wire [4:0] rd, ex_rd, mem_rd, wb_rd;				// use by stage WB
wire [4:0] rs1, rs2;								// use by gpr
wire [XLEN - 1:0] id_rs1, ex_rs1, id_rs2, ex_rs2;	// use by forward
wire [XLEN - 1:0] id_imm, ex_imm, mem_imm;			// use by alu
wire [4:0] ex_rs1_fw, ex_rs2_fw;					// use by alu for csr, also used by forward

// EX_MEM
wire [XLEN - 1:0] mem_rs1, mem_rs2;					// store data
wire [XLEN - 1:0] mem_alu;							// store/load address

// MEM_WB
wire [XLEN - 1:0] wb_alu;							// write back to gpr

// control EX	
wire [4:0] id_alu_op, ex_alu_op;					// use by alu
wire s_pc, ex_s_pc, s_imm, ex_s_imm, s_32, ex_s_32; // use by alu
wire s_jalr, s_jump, s_branch, s_branch_zero;		// use by addr_gen
wire ex_jalr, ex_jump, ex_branch, ex_branch_zero;	// use by addr_gen
wire s_csr, ex_csr, mem_csr;						// use by csr
wire s_csrw, ex_csrw, mem_csrw;						// use by csr
wire s_csri, ex_csri;

// control MEM
wire s_store, ex_store, s_load, ex_load;
wire [2:0] ex_funct3, mem_funct3;

// control pipe
wire if_id_pause, id_ex_pause, ex_mem_pause, mem_wb_pause; 
wire if_id_bubble, id_ex_bubble, ex_mem_bubble, mem_wb_bubble;
wire s_flush, ex_flush, mem_flush;

// stage IF
wire pc_pause;
wire [XLEN - 1:0] npc;
pc #(
	.XLEN(XLEN)
) pc_inst(
	.clock(clock),
	.reset(reset),
	.pause(pc_pause),
    .npc(npc),
	.pc(pc)
);

ilu #(
	.XLEN(XLEN)
) ilu_inst (
    .pc(pc),
    .inst_in(inst),
    .inst_out(if_inst)
);

if_id #(
	.XLEN(XLEN)
) if_id_inst (
	.clock(clock),
	.pause(if_id_pause),
	.bubble(if_id_bubble),
	.pc_in(pc),
	.inst_in(if_inst),
	.pc_out(id_pc),
	.inst_out(id_inst)
);

// stage ID
wire branch_take;
hazard hazard_inst(
	.ex_jump(ex_jump),
	.branch_take(branch_take),
    .ex_load(ex_load),
	.id_flush(s_flush),
	.ex_flush(ex_flush),
	.mem_flush(mem_flush),
    .ex_rd(ex_rd),
    .rs1(rs1),
    .rs2(rs2),
    .pc_pause(pc_pause),
	.pipe_pause({if_id_pause, id_ex_pause, ex_mem_pause, mem_wb_pause}),
	.pipe_bubble({if_id_bubble, id_ex_bubble, ex_mem_bubble, mem_wb_bubble})
);

decoder #(
	.XLEN(XLEN)
) decoder_inst (
`ifdef DEBUG
	.clock(clock),
	.pc(id_pc),
`endif
    .inst(id_inst),
    .opcode(opcode),
	.itype(itype),
    .funct3(funct3),
    .funct7(funct7),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(id_imm),
    .alu_op(id_alu_op),
	.s_pc(s_pc),
    .s_imm(s_imm),
	.s_jump(s_jump),
	.s_jalr(s_jalr),
	.s_branch(s_branch),
	.s_branch_zero(s_branch_zero),
	.s_load(s_load),
	.s_store(s_store),
	.s_csr(s_csr),
	.s_csri(s_csri),
	.s_csrw(s_csrw),
	.s_32(s_32),
	.s_flush(s_flush)
);

id_ex #(
	.XLEN(XLEN)
) id_ex_inst (
	.clock(clock),
	.pause(id_ex_pause),
	.bubble(id_ex_bubble),
	.rd_in(rd),
	.rs1_fw_in(rs1),
	.rs2_fw_in(rs2),
	.pc_in(id_pc),
	.rs1_in(id_rs1),
	.rs2_in(id_rs2),
	.imm_in(id_imm),
	.ctrl_in({id_alu_op, s_pc, s_imm, s_32, s_jalr, s_branch, s_branch_zero, s_csr, s_csri, s_csrw, s_jump, s_store, s_load, s_flush, funct3}),
	.rd_out(ex_rd),
	.rs1_fw_out(ex_rs1_fw),
	.rs2_fw_out(ex_rs2_fw),
	.pc_out(ex_pc),
	.rs1_out(ex_rs1),
	.rs2_out(ex_rs2),	
	.imm_out(ex_imm),
	.ctrl_out({ex_alu_op, ex_s_pc, ex_s_imm, ex_s_32, ex_jalr, ex_branch, ex_branch_zero, ex_csr, ex_csri, ex_csrw, ex_jump, ex_store, ex_load, ex_flush, ex_funct3})
);

// stage EX
wire [XLEN - 1:0] f_rs1, f_rs2;
forward #(
	.XLEN(XLEN)
) forward_inst (
    .mem_rd(mem_rd),
    .wb_rd(wb_rd),
    .rs1(ex_rs1_fw),
    .rs2(ex_rs2_fw),
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    .mem_rd_reg(mem_alu),
    .wb_rd_reg(wb_alu),
    .rs1_reg(f_rs1),
    .rs2_reg(f_rs2)
);

wire alu_z;
wire [XLEN - 1:0] alu_o, csr_o;
wire [XLEN - 1:0] mul_o, div_o;

alu #(
	.XLEN(XLEN)
) alu_inst(
	.s_32(ex_s_32),
	.opcode(ex_alu_op),
	.rs1(ex_s_pc? ex_pc : f_rs1),
	.rs2(ex_s_imm ? ex_imm : f_rs2),
	.rd(alu_o),
	.zero(alu_z)
);

generate if (ENABLE_MUL || ENABLE_DIV)
mul #(
	.XLEN(XLEN)
) mul_inst(
	.opcode(ex_alu_op),
	.rs1(f_rs1),
	.rs2(f_rs2),
	.rd(mul_o)	
);
endgenerate

generate if (ENABLE_DIV)
div #(
	.XLEN(XLEN)
) div_inst(
	.s_32(ex_s_32),	
	.opcode(ex_alu_op),
	.rs1(f_rs1),
	.rs2(f_rs2),
	.rd(div_o)	
);
endgenerate

wire [XLEN - 1:0] next_pc, ex_alu, alu_mux;
generate if (ENABLE_DIV)
assign alu_mux = ex_alu_op[4:2] == 3'b101 ? div_o : ex_alu_op[4:2] == 3'b100 ? mul_o : alu_o;
else if (ENABLE_MUL)
assign alu_mux = ex_alu_op[4:2] == 3'b100 ? mul_o : alu_o;
else
assign alu_mux = alu_o;
endgenerate

generate if (XLEN == 64) begin
wire [XLEN - 1:0] alu_signed = $signed(alu_mux[31:0]);
assign ex_alu = ex_jump ? next_pc : ex_s_32 ? alu_signed : alu_mux;
end else
assign ex_alu = ex_jump ? next_pc : alu_mux;
endgenerate

addr_gen #(
	.XLEN(XLEN)
) addr_gen_inst (
    .alu_z(alu_z),
    .s_jump(ex_jump),
    .s_jalr(ex_jalr),
    .s_branch(ex_branch),
    .s_branch_zero(ex_branch_zero),
	.pc(pc),
    .ex_pc(ex_pc),
    .imm(ex_imm),
    .alu_o(alu_o),
	.branch_take(branch_take),
	.npc(npc),
	.next_pc(next_pc)
);

ex_mem #(
	.XLEN(XLEN)
) ex_mem_inst (
	.clock(clock),
	.pause(ex_mem_pause),
	.bubble(ex_mem_bubble),
	.rd_in(ex_rd),
	.pc_in(ex_pc),
	.imm_in(ex_imm),
	.rs1_in(ex_csri ? ex_rs1_fw : f_rs1),
	.rs2_in(f_rs2),
	.alu_in(ex_alu),
	.ctrl_in({ex_csr, ex_csrw, ex_store, ex_load, ex_flush, ex_funct3}),
	.rd_out(mem_rd),
	.pc_out(mem_pc),
	.imm_out(mem_imm),
	.rs1_out(mem_rs1),
	.rs2_out(mem_rs2),
	.alu_out(mem_alu),
	.ctrl_out({mem_csr, mem_csrw, mem_store, mem_load, mem_flush, mem_funct3})
);

// stage MEM
assign address = mem_alu;

wire [XLEN - 1:0] mem_data;
lu #(
	.XLEN(XLEN)
) lu_inst(
	.addr(address),
    .funct3(mem_funct3),
    .data_in(load_data),
    .data_out(mem_data)
);

su #(
	.XLEN(XLEN)
) su_inst(
	.addr(address),
    .funct3(mem_funct3),
	.data_l(load_data),
    .data_in(mem_rs2),
    .data_out(store_data)
);

csr #(
	.XLEN(XLEN)
) csr_inst(
	.clock(clock),
	.s_csr(mem_csr),
	.s_csrw(mem_csrw),
	.funct3(mem_funct3),
	.addr(mem_imm),
	.pc_in(mem_pc),
	.data_in(mem_rs1),
	.pc_out(),
	.data_out(csr_o)
);

wire [XLEN - 1:0] mem_rd_reg = mem_load ? mem_data : mem_csr ? csr_o : mem_alu;
mem_wb #(
	.XLEN(XLEN)
) mem_wb_inst (
	.clock(clock),
	.pause(mem_wb_pause),
	.bubble(mem_wb_bubble),
	.rd_in(mem_rd),
	.alu_in(mem_rd_reg),
	.rd_out(wb_rd),
	.alu_out(wb_alu)
);

// stage WB
gpr #(
	.XLEN(XLEN)
) gpr_inst (
	.clock(clock),
	.addr_w(wb_rd),
	.addr_r1(rs1),
	.addr_r2(rs2),
	.data_w(wb_alu),
	.data_r1(id_rs1),
	.data_r2(id_rs2)
);

endmodule
