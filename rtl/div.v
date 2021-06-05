`include "defines.vh"

module div #(
	parameter XLEN = 32
)(
	input [4:0] opcode,
	input signed [XLEN - 1:0] rs1,
	input signed [XLEN - 1:0] rs2,
	output reg [XLEN - 1:0] rd
);

localparam [XLEN - 1:0] MNI = {1'b1, {(XLEN - 2){1'b0}}, 1'b1};

always @(*) case (opcode)
	`ALU_DIV:	rd = rs2 == 0 ? -1 : (rs1 == MNI && rs2 == -1) ? rs1 : rs1 / rs2;
	`ALU_DIVU:	rd = rs2 == 0 ? -1 : $unsigned(rs1) / $unsigned(rs2);
	`ALU_REM:   rd = rs2 == 0 ? rs1 : (rs1 == MNI && rs2 == 0) ? 0 : rs1 % rs2;
	`ALU_REMU:	rd = rs2 == 0 ? rs1 : $unsigned(rs1) % $unsigned(rs2);
	default: 	rd = 0;
endcase

endmodule
