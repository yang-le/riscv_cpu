`include "defines.vh"

module div #(
	parameter XLEN = 32
)(
	input s_32,
	input [4:0] opcode,
	input signed [XLEN - 1:0] rs1,
	input signed [XLEN - 1:0] rs2,
	output reg [XLEN - 1:0] rd
);

localparam [XLEN - 1:0] MNI = {1'b1, {(XLEN - 2){1'b0}}, 1'b1};
localparam [XLEN - 1:0] MNIW = $signed({1'b1, {30{1'b0}}, 1'b1});
wire [XLEN - 1:0] xmni = s_32 ? MNIW : MNI;

wire [XLEN - 1:0] rs1w = $signed(rs1[31:0]);
wire [XLEN - 1:0] rs2w = $signed(rs2[31:0]);
wire signed [XLEN - 1:0] xrs1 = s_32 ? rs1w : rs1;
wire signed [XLEN - 1:0] xrs2 = s_32 ? rs2w : rs2;

wire [XLEN - 1:0] xrs1u = s_32 ? rs1[31:0] : rs1;
wire [XLEN - 1:0] xrs2u = s_32 ? rs2[31:0] : rs2;

always @(*) case (opcode)
	`ALU_DIV:	rd = xrs2 == 0 ? -1 : (xrs1 == xmni && xrs2 == -1) ? xrs1 : xrs1 / xrs2;
	`ALU_DIVU:	rd = xrs2 == 0 ? -1 : xrs1u / xrs2u;
	`ALU_REM:   rd = xrs2 == 0 ? xrs1 : (xrs1 == xmni && xrs2 == 0) ? 0 : xrs1 % xrs2;
	`ALU_REMU:	rd = xrs2 == 0 ? xrs1 : xrs1u % xrs2u;
	default: 	rd = 0;
endcase

endmodule
