
module pc #(
    parameter XLEN = 32,
    parameter [XLEN - 1:0] RESET = 0
)(
    input clock,
    input reset,
    input pause,
    input s_npc,
    input [XLEN - 1:0] npc,
    output reg [XLEN - 1:0] pc
);
	initial begin
		pc = 0;
	end

    always @(posedge clock, posedge reset) begin
        if (reset)
            pc <= RESET;
        else if (!pause)
            pc <= s_npc ? npc : pc + 4;
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
    input [XLEN - 1:0] pc,
    input [XLEN - 1:0] imm,
    input [XLEN - 1:0] alu_o,
    output s_npc,
    output [XLEN - 1:0] npc,
    output [XLEN - 1:0] next_pc
);
    wire branch = s_branch && (s_branch_zero ~^ alu_z);

    assign s_npc = s_jump || branch;
    assign npc = s_jump ? (alu_o & ~s_jalr) : next_pc;
    assign next_pc = pc + (branch ? imm : 4);
endmodule
