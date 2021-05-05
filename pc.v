
module pc #(
    parameter XLEN = 32,
    parameter [XLEN - 1:0] RESET = 0
)(
    input clock,
    input reset,
    input [XLEN - 1:0] alu_o,
    input alu_z,
    input s_jump,
    input s_jalr,
    input s_branch,
    input s_branch_zero,
    input [XLEN - 1:0] imm,
    output reg [XLEN - 1:0] pc,
    output [XLEN - 1:0] next_pc
);
wire alu_b = s_branch_zero ? alu_z : ~alu_z;
wire [31:0] pc_offset = (s_branch && alu_b) ? imm : 4;
wire [31:0] npc = s_jump ? (alu_o & ~s_jalr) : (pc + pc_offset);

always @(posedge clock, negedge reset)
    if (~reset)
        pc <= RESET;
    else
        pc <= npc;

assign next_pc = pc + 4;

endmodule
