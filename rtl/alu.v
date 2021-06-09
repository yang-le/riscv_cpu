`include "defines.vh"

module alu #(
	parameter XLEN = 32
)(
	input [4:0] opcode,
	input signed [XLEN - 1:0] rs1,
	input signed [XLEN - 1:0] rs2,
	output reg [XLEN - 1:0] rd,
	output zero
);

always @(*) case (opcode)
	`ALU_ADD:	rd = rs1 + rs2;
	`ALU_SUB:	rd = rs1 - rs2;
	`ALU_CMP: 	rd = rs1 < rs2;
	`ALU_UCMP:	rd = $unsigned(rs1) < $unsigned(rs2);
	`ALU_AND: 	rd = rs1 & rs2;
	`ALU_OR:	rd = rs1 | rs2;
	`ALU_XOR:	rd = rs1 ^ rs2;
	`ALU_SLL:	rd = rs1 << rs2[$clog2(XLEN) - 1:0];
	`ALU_SRL:	rd = rs1 >> rs2[$clog2(XLEN) - 1:0];
	`ALU_SRA: 	rd = rs1 >>> rs2[$clog2(XLEN) - 1:0];
	default: 	rd = -1;
endcase

assign zero = (rd == 0);

endmodule
