
module hazard(
    input ex_jump,
    input branch_take,
    input ex_load,
    input [4:0] ex_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    output pc_pause,
    output [3:0] pipe_pause,
    output [3:0] pipe_bubble
);
    localparam PAUSE_LOAD = 4'b1000;
    localparam BUBBLE_LOAD = 4'b0100;
    localparam BUBBLE_ADDR_GEN = 4'b1100;

    wire load_hazard = ex_load && ((ex_rd == rs1) || (ex_rd == rs2));

    assign pc_pause = load_hazard;
    assign pipe_pause = load_hazard ? PAUSE_LOAD : 0;
    assign pipe_bubble = load_hazard ? BUBBLE_LOAD :
                            (branch_take || ex_jump) ? BUBBLE_ADDR_GEN : 0;
endmodule
