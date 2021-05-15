`include "defines.vh"

module csr #(
	parameter XLEN = 32,
	parameter NUM = 2 ** 12
)(
	input clock,
	input s_csr,
    input s_csrsc,
    input [4:0] rs1,
	input [$clog2(NUM) - 1:0] addr,
    input [XLEN - 1:0] data_w,
	output [XLEN - 1:0] data_r
);
    wire write_en = s_csr && (~s_csrsc || |rs1);

    generic_ram #(
        .WIDTH(XLEN),
        .DEPTH(NUM)
    ) mem_inst (
        .clock(clock),
        .write_en(write_en),
        .addr(addr),
        .data_i(data_w),
        .data_o(data_r)
    );
endmodule
