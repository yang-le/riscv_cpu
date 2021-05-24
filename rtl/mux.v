
module nmux #(
    parameter N = 4,
    parameter WIDTH = 8
)(
    input [$clog2(N) - 1:0] sel,
    input [N * WIDTH - 1:0] data_in,
    output [WIDTH - 1:0] data_out
);
    assign data_out = data_in[sel * WIDTH +: WIDTH];
endmodule

module pmux #(
    parameter N = 3,
    parameter WIDTH = 8
)(
    input [N - 1:0] sel,
    input [N * WIDTH - 1:0] data_in,
    output reg [WIDTH - 1:0] data_out
);
    integer i;
    always @(*) begin
        data_out = 0;
        for (i = 0; i < N; i = i + 1)
            if (sel[i]) data_out = data_in[i * WIDTH +: WIDTH];
    end
endmodule
