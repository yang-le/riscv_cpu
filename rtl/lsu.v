`include "defines.vh"

module lu #(
	parameter XLEN = 32
)(
    input s_byte,
    input [2:0] funct3,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

always @(*) case (funct3)
    `LB:    data_out = $signed(s_byte ? data_in[15:8] : data_in[7:0]);
    `LH:    data_out = $signed(data_in[15:0]);
    `LW:    data_out = $signed(data_in[31:0]);
    `LD:    data_out = data_in;
    `LBU:   data_out = $unsigned(s_byte ? data_in[15:8] : data_in[7:0]);
    `LHU:   data_out = $unsigned(data_in[15:0]);
    `LWU:   data_out = $unsigned(data_in[31:0]);
    default:data_out = 0;
endcase

endmodule

module su #(
	parameter XLEN = 32
)(
    input s_byte,
    input [2:0] funct3,
    input [XLEN - 1:0] data_l,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

always @(*) case (funct3)
    `SB:    data_out = (data_l & ~(s_byte ? 16'hff00 : 8'hff)) | $unsigned(s_byte ? {data_in[7:0], 8'b0} : data_in[7:0]);
    `SH:    data_out = (data_l & ~16'hffff) | $unsigned(data_in[15:0]);
    `SW:    data_out = (data_l & ~32'hffff_ffff) | $unsigned(data_in[31:0]);
    `SD:    data_out = data_in;
    default:data_out = 0;
endcase

endmodule
