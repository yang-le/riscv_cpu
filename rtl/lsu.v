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
    `LW:    data_out = data_in;
    `LBU:   data_out = $unsigned(data_in[addr * 8 +: 8]);
    `LHU:   data_out = $unsigned(data_in[addr * 8 +: 16]);
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

always @(*) case (addr)
    0:      data_out = funct3 == `SB ? {data_l[XLEN - 1:8], data_in[7:0]} :
                        funct3 == `SH ? {data_l[XLEN - 1:16], data_in[15:0]} : data_in;
    1:      data_out = funct3 == `SB ? {data_l[XLEN - 1:16], data_in[7:0], data_l[7:0]} :
                        funct3 == `SH ? {data_l[XLEN - 1:24], data_in[15:0], data_l[7:0]} : {data_in[23:0], data_l[7:0]};
    2:      data_out = funct3 == `SB ? {data_l[XLEN - 1:24], data_in[7:0], data_l[15:0]} : {data_in[15:0], data_l[15:0]};
    3:      data_out = {data_in[7:0], data_l[23:0]};
    default:data_out = 0;
endcase

endmodule
