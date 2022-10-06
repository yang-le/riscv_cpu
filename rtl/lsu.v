`include "defines.vh"

`ifdef VERILATOR
module lu #(
	parameter XLEN = 32
)(
    input addr,
    input [2:0] funct3,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

always @(*) case (funct3)
    `LB:    data_out = $signed(addr ? data_in[15:8] : data_in[7:0]);
    `LH:    data_out = $signed(data_in[15:0]);
    `LW:    data_out = $signed(data_in[31:0]);
    `LD:    data_out = data_in;
    `LBU:   data_out = $unsigned(addr ? data_in[15:8] : data_in[7:0]);
    `LHU:   data_out = $unsigned(data_in[15:0]);
    `LWU:   data_out = $unsigned(data_in[31:0]);
    default:data_out = 0;
endcase

endmodule

module su #(
	parameter XLEN = 32
)(
    input addr,
    input [2:0] funct3,
    input [XLEN - 1:0] data_l,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

always @(*) case (funct3)
    `SB:    data_out = (data_l & ~(addr ? 16'hff00 : 8'hff)) | $unsigned(addr ? {data_in[7:0], 8'b0} : data_in[7:0]);
    `SH:    data_out = (data_l & ~16'hffff) | $unsigned(data_in[15:0]);
    `SW:    data_out = (data_l & ~32'hffff_ffff) | $unsigned(data_in[31:0]);
    `SD:    data_out = data_in;
    default:data_out = 0;
endcase

endmodule
`else
module lu #(
	parameter XLEN = 32
)(
    input [2:0] addr,
    input [2:0] funct3,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

localparam MSB = (XLEN == 64) ? 2 : 1;

wire [31:0] data_in_32;
generate if (XLEN == 64)
	assign data_in_32 = data_in[addr[MSB:2] * 32 +: 32];
else
    assign data_in_32 = data_in;
endgenerate

always @(*) case (funct3)
    `LB:    data_out = $signed(data_in[addr[MSB:0] * 8 +: 8]);
    `LH:    data_out = $signed(data_in[addr[MSB:1] * 16 +: 16]);
    `LW:    data_out = $signed(data_in_32);
    `LD:    data_out = data_in;
    `LBU:   data_out = $unsigned(data_in[addr[MSB:0] * 8 +: 8]);
    `LHU:   data_out = $unsigned(data_in[addr[MSB:1] * 16 +: 16]);
    `LWU:   data_out = $unsigned(data_in_32);
    default:data_out = 0;
endcase

endmodule

module su #(
	parameter XLEN = 32
)(
    input [2:0] addr,
    input [2:0] funct3,
    input [XLEN - 1:0] data_l,
    input [XLEN - 1:0] data_in,
    output reg [XLEN - 1:0] data_out
);

localparam MSB = (XLEN == 64) ? 2 : 1;

wire [31:0] data_out_32;
generate if (XLEN == 64)
	assign data_out_32 = (data_l & ~(32'hffff_ffff << (addr[MSB:2] * 32))) | ({32'b0, data_in[31:0]} << (addr[MSB:2] * 32));
else
    assign data_out_32 = data_in;
endgenerate

always @(*) case (funct3)
    `SB:    data_out = (data_l & ~(8'hff << (addr[MSB:0] * 8))) | ({{(XLEN - 8){1'b0}}, data_in[7:0]} << (addr[MSB:0] * 8));
    `SH:    data_out = (data_l & ~(16'hffff << (addr[MSB:1] * 16))) | ({{(XLEN - 15){1'b0}}, data_in[15:0]} << (addr[MSB:1] * 16));
    `SW:    data_out = data_out_32;
    `SD:    data_out = data_in;
    default:data_out = 0;
endcase

endmodule
`endif
