
module hazard(
    input ex_jump,
    input branch_take,
    input ex_load,
    input [4:0] ex_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    output pc_pause,
    output [7:0] pipe_ctrl
);
    localparam CTRL_LOAD = 8'b01100000;
    localparam CTRL_ADDR_GEN = 8'b10100000;

    wire load_hazard = ex_load && ((ex_rd == rs1) || (ex_rd == rs2));

    assign pc_pause = load_hazard;
    assign pipe_ctrl = load_hazard ? CTRL_LOAD :
                        (branch_take || ex_jump) ? CTRL_ADDR_GEN : 0;
endmodule
