
module cache #(
    parameter XLEN = 32,
    parameter NWAYS = 8,
    parameter LINE_SIZE = 64,
    parameter SIZE = 512
)(
    input clock,
    input mem_write_en,
    input cpu_write_en,
    input [XLEN - 1:0] address,
    input [8 * LINE_SIZE - 1:0] data_in,
    output reg [8 * LINE_SIZE - 1:0] data_out,
    output hit
);
    localparam NSETS = SIZE / LINE_SIZE / NWAYS;
    localparam NOFFSET = $clog2(LINE_SIZE);
    localparam NINDEX = $clog2(NSETS);
    localparam NTAG = XLEN - NOFFSET - NINDEX;

    wire [NWAYS - 1:0] hits;
    wire [NWAYS - 1:0] valid;
    wire [NWAYS - 1:0] dirty;
    wire [NWAYS * NTAG - 1:0] tag;
    wire [8 * LINE_SIZE - 1:0] line;
    wire [$clog2(NWAYS) - 1:0] v_index;
    wire [$clog2(NWAYS) - 1:0] h_index;
    wire [$clog2(NWAYS) - 1:0] d_index;
    wire [NINDEX - 1:0] s_index = address[NOFFSET +: NINDEX];
    wire [NTAG - 1:0] a_tag = address[NOFFSET + NINDEX +: NTAG];

generate if (NSETS == 1) begin
    reg [NWAYS - 1:0] valids;
    reg [NWAYS * NTAG - 1:0] tags;
    reg [NWAYS - 1:0] dirties;

    assign valid = valids;
    assign tag = tags;
    assign dirty = dirties;

    always @(posedge clock) begin
        if (mem_write_en) begin
            valids <= valid | (1 << v_index);
            tags <= tag | (a_tag << v_index * NTAG);
            dirties <= dirty & ~(1 << v_index);
        end else if (cpu_write_en) begin
            dirties <= dirty | (1 << d_index);
        end
    end
end else begin
    generic_ram #(
        .WIDTH(NWAYS),
        .DEPTH(NSETS)
    ) valids (
        .clock(clock),
        .write_en(mem_write_en),
        .addr(s_index),
        .data_i(valid | (1 << v_index)),
        .data_o(valid)
    );

    generic_ram #(
        .WIDTH(NWAYS * NTAG),
        .DEPTH(NSETS)
    ) tags (
        .clock(clock),
        .write_en(mem_write_en),
        .addr(s_index),
        .data_i(tag | (a_tag << v_index * NTAG)),
        .data_o(tag)
    );

    generic_ram #(
        .WIDTH(NWAYS),
        .DEPTH(NSETS)
    ) dirties (
        .clock(clock),
        .write_en(mem_write_en || cpu_write_en),
        .addr(s_index),
        .data_i(mem_write_en ? dirty & ~(1 << v_index) : cpu_write_en ? dirty | (1 << d_index) : dirty),
        .data_o(dirty)
    );
end endgenerate

    generic_ram #(
        .WIDTH(8 * LINE_SIZE),
        .DEPTH(NSETS * NWAYS)
    ) lines (
        .clock(clock),
        .write_en(mem_write_en || cpu_write_en),
        .addr({s_index, mem_write_en ? v_index : cpu_write_en ? d_index : h_index}),
        .data_i(data_in),
        .data_o(line)
    );

generate if (NWAYS == 1) begin
    assign v_index = ~valid;
    assign h_index = hits;
    assign d_index = ~dirty;
end else begin
    encoder #(
        .WIDTH(NWAYS)
    ) v_encoder (
        .sel(~valid),
        .data_out(v_index)
    );

    encoder #(
        .WIDTH(NWAYS)
    ) h_encoder (
        .sel(hits),
        .data_out(h_index)
    );

    encoder #(
        .WIDTH(NWAYS)
    ) d_encoder (
        .sel(~dirty),
        .data_out(d_index)
    );
end endgenerate

    always @(posedge clock) begin
        data_out <= line;
    end

    genvar i;
    generate
        for (i = 0; i < NWAYS; i = i + 1) begin: _hit
            assign hits[i] = (tag[i * NTAG +: NTAG] == a_tag) && valid[i];
        end
    endgenerate

    assign hit = |hits;
endmodule
