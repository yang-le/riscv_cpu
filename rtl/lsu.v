`include "defines.vh"

module lu #(
	parameter XLEN = 32
)(
    input [$clog2(XLEN / 8) - 1:0] addr,
    input [2:0] funct3,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

always @(*) case (funct3)
    `LB:    data_out = $signed(data_in[addr * 8 +: 8]);
    `LH:    data_out = $signed(data_in[addr * 8 +: 16]);
    `LW:    data_out = $signed(data_in[addr * 8 +: 32]);
    `LD:    data_out = data_in;
    `LBU:   data_out = $unsigned(data_in[addr * 8 +: 8]);
    `LHU:   data_out = $unsigned(data_in[addr * 8 +: 16]);
    `LWU:   data_out = $unsigned(data_in[addr * 8 +: 32]);
    default:data_out = 0;
endcase

endmodule

module ilu #(
	parameter XLEN = 32
)(
    input [XLEN - 1:0] pc,
    input [XLEN - 1:0] inst_in,
    output [31:0] inst_out
);

generate if (XLEN == 32)
    assign inst_out = inst_in;
else
    assign inst_out = inst_in[pc[$clog2(XLEN / 8) - 1:2] * 32 +: 32];
endgenerate

endmodule

module su #(
	parameter XLEN = 32
)(
    input [$clog2(XLEN / 8) - 1:0] addr,
    input [2:0] funct3,
    input [XLEN - 1:0] data_l,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

always @(*) case (funct3)
    `SB:    data_out = (data_l & ~(8'hff << (addr * 8))) | ($unsigned(data_in[7:0]) << (addr * 8));
    `SH:    data_out = (data_l & ~(16'hffff << (addr * 8))) | ($unsigned(data_in[15:0]) << (addr * 8));
    `SW:    data_out = (data_l & ~(32'hffff_ffff << (addr * 8))) | ($unsigned(data_in[31:0]) << (addr * 8));
    `SD:    data_out = data_in;
    default:data_out = 0;
endcase

endmodule
