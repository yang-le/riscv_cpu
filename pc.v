
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
    input [XLEN - 1:0] imm,
    input [XLEN - 1:0] pc,
    output s_npc,
    output [XLEN - 1:0] npc
);
    wire alu_b = s_branch_zero ~^ alu_z ;

    assign s_npc = s_jump || (s_branch && alu_b);
    assign npc = (pc + imm) & ~(s_jalr);
endmodule
