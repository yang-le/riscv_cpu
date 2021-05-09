
module encoder #(
    parameter WIDTH = 4
)(
    input [WIDTH - 1:0] sel,
    output reg [$clog2(WIDTH) - 1:0] data_out
);
    integer i;
    always @(*) begin
        data_out = 0;
        for (i = 0; i < WIDTH; i = i + 1)
            if (sel[i]) data_out = i;
    end
endmodule
