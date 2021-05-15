
module forward_control (
    input [4:0] mem_rd,
    input [4:0] wb_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    output forward1_mem,
    output forward2_mem,
    output forward1_wb,
    output forward2_wb
);
    assign forward1_mem = (mem_rd != 0) && (mem_rd == rs1);
    assign forward2_mem = (mem_rd != 0) && (mem_rd == rs2);
    assign forward1_wb = (wb_rd != 0) && (wb_rd == rs1);
    assign forward2_wb = (wb_rd != 0) && (wb_rd == rs2);
endmodule

module forward #(
    parameter XLEN = 32
)(
    input [4:0] mem_rd,
    input [4:0] wb_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    input [XLEN - 1:0] ex_rs1,
    input [XLEN - 1:0] ex_rs2,
    input [XLEN - 1:0] mem_rd_reg,
    input [XLEN - 1:0] wb_rd_reg,
    output [XLEN - 1:0] rs1_reg,
    output [XLEN - 1:0] rs2_reg
);
    wire forward1_mem;
    wire forward2_mem;
    wire forward1_wb;
    wire forward2_wb;

    forward_control forward_control_inst(
        .mem_rd(mem_rd),
        .wb_rd(wb_rd),
        .rs1(rs1),
        .rs2(rs2),
        .forward1_mem(forward1_mem),
        .forward2_mem(forward2_mem),
        .forward1_wb(forward1_wb),
        .forward2_wb(forward2_wb)
    );

    assign rs1_reg = forward1_mem ? mem_rd_reg :
                        forward1_wb ? wb_rd_reg : ex_rs1;
    assign rs2_reg = forward2_mem ? mem_rd_reg :
                        forward2_wb ? wb_rd_reg : ex_rs2;
endmodule
