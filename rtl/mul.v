`include "defines.vh"

module mul #(
	parameter XLEN = 32
)(
	input [4:0] opcode,
	input signed [XLEN - 1:0] rs1,
	input signed [XLEN - 1:0] rs2,
	output reg [XLEN - 1:0] rd
);

reg [XLEN - 1:0] xrd;
always @(*) case (opcode)
	`ALU_MUL:	{xrd, rd} = rs1 * rs2;
	`ALU_MULH:	{rd, xrd} = rs1 * rs2;
	`ALU_MULHSU:{rd, xrd} = rs1 * $signed({1'b0, rs2});
	`ALU_MULHU:	{rd, xrd} = $unsigned(rs1) * $unsigned(rs2);
	default: 	rd = 0;
endcase

endmodule
