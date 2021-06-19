
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
    input s_exception,
    input s_mret,
    input [XLEN - 1:0] pc,
    input [XLEN - 1:0] ex_pc,
    input [XLEN - 1:0] mtvec, mepc, mcause,
    input [XLEN - 1:0] imm,
    input [XLEN - 1:0] alu_o,
    output branch_take,
    output [XLEN - 1:0] npc,
    output [XLEN - 1:0] next_pc
);
    assign branch_take = s_branch && (s_branch_zero ~^ alu_z);
    assign npc = s_jump ? (alu_o & ~s_jalr) : s_mret ? mepc : next_pc;
    assign next_pc = ((branch_take || s_jump) ? ex_pc : s_exception ? {mtvec[XLEN - 1:2], 2'b00} : pc) +
                    (branch_take ? imm : s_exception ? ((mtvec[1:0] == 2'b01 && mcause[XLEN - 1]) ? {mcause[XLEN - 2:0], 2'b00} : 0) : 4);
endmodule
