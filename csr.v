
module csr #(
	parameter WIDTH = 32,
	parameter NUM = 2 ** 12
)(
	input clock,
	input s_csr,
    input s_csrsc,
    input [4:0] rs1,
	input [4:0] rd,
	input [$clog2(NUM) - 1:0] addr,
	input [WIDTH - 1:0] data_w,
	output [WIDTH - 1:0] data_r
);
    wire write_en = s_csr && (~s_csrsc || |rs1);

    generic_ram #(
        .WIDTH(WIDTH),
        .DEPTH(NUM)
    ) mem_inst (
        .clock(clock),
        .write_en(write_en),
        .addr(addr),
        .data_i(data_w),
        .data_o(data_r)
    );
endmodule
