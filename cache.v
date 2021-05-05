`include "defines.vh"

module cache #(
    parameter XLEN = 32,
    parameter NWAYS =4,
    parameter NSETS = 256,
    parameter SIZE = 32 * 1024
)(
    input clock,
    input write_en,
    input [XLEN - 1:0] address,
    input [LINE_SIZE - 1:0] data_in,
    output [LINE_SIZE - 1:0] data_out,
    output hit
);
    localparam LINE_SIZE = SIZE / NWAYS / NSETS;
    localparam NOFFSET = $clog2(LINE_SIZE);
    localparam NINDEX = $clog2(NSETS);
    localparam NTAG = XLEN - NOFFSET - NINDEX;

    reg valid[NSETS - 1:0][NWAYS - 1:0];
    reg [NTAG - 1:0] tag[NSETS - 1:0][NWAYS - 1:0];
    reg [LINE_SIZE - 1:0] line[NSETS - 1:0][NWAYS - 1:0];
    reg dirty[NSETS - 1:0][NWAYS - 1:0];

    // wire [NOFFSET - 1:0] a_offset = address[NOFFSET - 1:0];
    wire [NINDEX - 1:0] a_index = address[NINDEX - 1:NOFFSET];
    wire [NTAG - 1:0] a_tag = address[NTAG - 1:NOFFSET + NINDEX];
    wire [NWAYS - 1:0] hits;
    wire [LINE_SIZE - 1:0] data_outs;

    generate
        genvar i;
        for (i = 0; i < NWAYS; i = i + 1) begin : judge
            assign hits[i] = (tag[a_index][i] == a_tag)/* && valid[a_index][0]*/;
            assign data_outs[i] = {LINE_SIZE{hits[i]}} & line[a_index][i];
        end
    endgenerate

    assign hit = |hits;
    assign data_out = |data_outs;
endmodule
