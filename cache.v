
module cache #(
    parameter XLEN = 32,
    parameter NWAYS = 4,
    parameter LINE_SIZE = 64,
    parameter SIZE = 16 * 1024
)(
    input clock,
    input write_en,
    input [XLEN - 1:0] address,
    input [8 * LINE_SIZE - 1:0] data_in,
    output reg [8 * LINE_SIZE - 1:0] data_out,
    output hit
);
    localparam NSETS = SIZE / LINE_SIZE / NWAYS;
    localparam NOFFSET = $clog2(LINE_SIZE);
    localparam NINDEX = $clog2(NSETS);
    localparam NTAG = XLEN - NOFFSET - NINDEX;

    reg [NWAYS - 1:0] dirty[NSETS - 1:0];

    wire [NWAYS - 1:0] hits;
    wire [NWAYS - 1:0] valid;
    wire [NWAYS * NTAG - 1:0] tag;
    wire [8 * LINE_SIZE - 1:0] line;
    wire [$clog2(NWAYS) - 1:0] w_index;
    wire [$clog2(NWAYS) - 1:0] r_index;
    wire [NINDEX - 1:0] s_index = address[NOFFSET +: NINDEX];
    wire [NTAG - 1:0] a_tag = address[NOFFSET + NINDEX +: NTAG];

    generic_ram #(
        .WIDTH(NWAYS),
        .DEPTH(NSETS)
    ) valids (
        .clock(clock),
        .write_en(write_en),
        .addr(s_index),
        .data_i(valid | (1 << w_index)),
        .data_o(valid)
    );

    generic_ram #(
        .WIDTH(NWAYS * NTAG),
        .DEPTH(NSETS)
    ) tags (
        .clock(clock),
        .write_en(write_en),
        .addr(s_index),
        .data_i(tag | (a_tag << w_index * NTAG)),
        .data_o(tag)
    );

    generic_ram #(
        .WIDTH(8 * LINE_SIZE),
        .DEPTH(NSETS * NWAYS)
    ) lines (
        .clock(clock),
        .write_en(write_en),
        .addr({s_index, write_en ? w_index : r_index}),
        .data_i(data_in),
        .data_o(line)
    );

    encoder #(
        .WIDTH(NWAYS)
    ) w_encoder (
        .sel(~valid),
        .data_out(w_index)
    );

    encoder #(
        .WIDTH(NWAYS)
    ) r_encoder (
        .sel(hits),
        .data_out(r_index)
    );

    integer i;
    always @(posedge clock) begin
        if (write_en) begin
            dirty[s_index][w_index] <= 0;
        end
        data_out <= line;
    end

    genvar j;
    generate
        for (j = 0; j < NWAYS; j = j + 1) begin: _hit
            assign hits[j] = (tag[j * NTAG +: NTAG] == a_tag) && valid[j];
        end
    endgenerate

    assign hit = |hits;
endmodule
