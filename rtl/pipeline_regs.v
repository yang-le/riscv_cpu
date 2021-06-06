`include "defines.vh"

module if_id #(
    parameter XLEN = 32,
    parameter BYPASS = 0
)(
    input clock,
    input pause,
    input bubble,
    input [XLEN - 1:0] pc_in,
    input [31:0] inst_in,
    output [XLEN - 1:0] pc_out,
    output [31:0] inst_out
);
generate if (BYPASS) begin
    assign {pc_out, inst_out} = {pc_in, inst_in};
end else begin
    reg [XLEN - 1:0] pc_reg = 0;
    reg [31:0] inst_reg = 0;

    always @(posedge clock)
        if (~pause)
            {pc_reg, inst_reg} <= bubble ? {{XLEN{1'b0}}, `NOP} : {pc_in, inst_in};

    assign {pc_out, inst_out} = {pc_reg, inst_reg};
end endgenerate
endmodule

module id_ex #(
    parameter XLEN = 32,
    parameter BYPASS = 0
)(
    input clock,
    input pause,
    input bubble,
    input [4:0] rd_in, rs1_fw_in, rs2_fw_in,
    input [XLEN - 1:0] pc_in, rs1_in, rs2_in, imm_in,
    input [18:0] ctrl_in,
    output [4:0] rd_out, rs1_fw_out, rs2_fw_out,
    output [XLEN - 1:0] pc_out, rs1_out, rs2_out, imm_out,
    output [18:0] ctrl_out
);
generate if (BYPASS) begin
    assign {rd_out, rs1_fw_out, rs2_fw_out, pc_out, rs1_out, rs2_out, imm_out, ctrl_out} = {rd_in, rs1_fw_in, rs2_fw_in, pc_in, rs1_in, rs2_in, imm_in, ctrl_in};
end else begin
    reg [4:0] rd_reg = 0, rs1_fw_reg = 0, rs2_fw_reg = 0;
    reg [18:0] ctrl_reg = 0;
    reg [XLEN - 1:0] pc_reg = 0, rs1_reg = 0, rs2_reg = 0, imm_reg = 0;

    always @(posedge clock)
        if (~pause)
            {rd_reg, rs1_fw_reg, rs2_fw_reg, pc_reg, rs1_reg, rs2_reg, imm_reg, ctrl_reg} <= bubble ? 0 : {rd_in, rs1_fw_in, rs2_fw_in, pc_in, rs1_in, rs2_in, imm_in, ctrl_in};

    assign {rd_out, rs1_fw_out, rs2_fw_out, pc_out, rs1_out, rs2_out, imm_out, ctrl_out} = {rd_reg, rs1_fw_reg, rs2_fw_reg, pc_reg, rs1_reg, rs2_reg, imm_reg, ctrl_reg};
end endgenerate
endmodule

module ex_mem #(
    parameter XLEN = 32,
    parameter BYPASS = 0
)(
    input clock,
    input pause,
    input bubble,
    input [4:0] rd_in,
    input [XLEN - 1:0] rs2_in, alu_in,
    input [4:0] ctrl_in,
    output [4:0] rd_out,
    output [XLEN - 1:0] rs2_out, alu_out,
    output [4:0] ctrl_out
);
generate if (BYPASS) begin
    assign {rd_out, rs2_out, alu_out, ctrl_out} = {rd_in, rs2_in, alu_in, ctrl_in};
end else begin
    reg [4:0] ctrl_reg = 0;
    reg [4:0] rd_reg = 0;
    reg [XLEN - 1:0] rs2_reg = 0, alu_reg = 0;

    always @(posedge clock)
        if (~pause)
            {rd_reg, rs2_reg, alu_reg, ctrl_reg} <= bubble ? 0 : {rd_in, rs2_in, alu_in, ctrl_in};

    assign {rd_out, rs2_out, alu_out, ctrl_out} = {rd_reg, rs2_reg, alu_reg, ctrl_reg};
end endgenerate
endmodule

module mem_wb #(
    parameter XLEN = 32,
    parameter BYPASS = 0
)(
    input clock,
    input pause,
    input bubble,
    input [4:0] rd_in,
    input [XLEN - 1:0] alu_in,
    input [XLEN - 1:0] mem_in,
    input [0:0] ctrl_in,
    output [4:0] rd_out,
    output [XLEN - 1:0] alu_out,
    output [XLEN - 1:0] mem_out,
    output [0:0] ctrl_out
);
generate if (BYPASS) begin
    assign {rd_out, alu_out, mem_out, ctrl_out} = {rd_in, alu_in, mem_in, ctrl_in};
end else begin
    reg [0:0] ctrl_reg = 0;
    reg [4:0] rd_reg = 0;
    reg [XLEN - 1:0] alu_reg, mem_reg = 0;

    always @(posedge clock)
        if (~pause)
            {rd_reg, alu_reg, mem_reg, ctrl_reg} <= bubble ? 0 : {rd_in, alu_in, mem_in, ctrl_in};

    assign {rd_out, alu_out, mem_out, ctrl_out} = {rd_reg, alu_reg, mem_reg, ctrl_reg};
end endgenerate
endmodule
