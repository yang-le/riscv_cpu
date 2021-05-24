
`define PACK(WIDTH, LEN, SRC, DEST) \
    generate begin \
        genvar i; \
        for (i = 0; i < LEN; i = i + 1) begin: pack \
            assign DEST[i * WIDTH +: WIDTH] = SRC[i][WIDTH - 1:0]; \
        end \
    end \
    endgenerate
