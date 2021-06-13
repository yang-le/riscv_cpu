
module hazard(
    input ex_jump,
    input branch_take,
    input ex_load,
    input id_flush,
    input ex_flush,
    input mem_flush,
    input [4:0] ex_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    output pc_pause,
    output [3:0] pipe_pause,
    output [3:0] pipe_bubble
);
    localparam PAUSE_ID = 4'b1000;
    localparam BUBBLE_ID = 4'b1000;
    localparam BUBBLE_EX = 4'b0100;
    localparam BUBBLE_MEM = 4'b0010;

    wire load_hazard = ex_load && ((ex_rd == rs1) || (ex_rd == rs2));

    assign pc_pause = load_hazard || id_flush || ex_flush || mem_flush;
    assign pipe_pause = load_hazard ? PAUSE_ID : 0;
    assign pipe_bubble = id_flush ? BUBBLE_ID :
                        load_hazard ? BUBBLE_EX :
                        (ex_flush || branch_take || ex_jump) ? (BUBBLE_ID | BUBBLE_EX) :
                        mem_flush ? (BUBBLE_ID | BUBBLE_EX | BUBBLE_MEM) : 0;
endmodule
