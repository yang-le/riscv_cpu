
module pc #(
    parameter XLEN = 32,
    parameter [XLEN - 1:0] RESET = 0
)(
    input clock,
    input reset,
    input pause,
    input [XLEN - 1:0] npc,
    output reg [XLEN - 1:0] pc
);
	initial begin
		pc = 0;
	end

    always @(posedge clock) begin
        if (reset)
            pc <= RESET;
        else if (!pause)
            pc <= npc;
    end
endmodule

module addr_gen #(
    parameter XLEN = 32
)(
    input alu_z,
    input s_jump,
    input s_jalr,
    input s_branch,
    input s_branch_zero,
    input s_rvc,
    input [XLEN - 1:0] pc,
    input [XLEN - 1:0] ex_pc,
    input [XLEN - 1:0] imm,
    input [XLEN - 1:0] alu_o,
    output branch_take,
    output [XLEN - 1:0] npc
);
    assign branch_take = s_branch && (s_branch_zero ~^ alu_z);
    assign npc = s_jump ? (alu_o & ~s_jalr) : ((branch_take ? ex_pc : pc) + (branch_take ? imm : s_rvc ? 2 : 4));
endmodule
