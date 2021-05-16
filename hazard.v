
module hazard(
    input id_jump,
    input ex_load,
    input [4:0] ex_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    output bubble
);
    wire bubble_load = ex_load && ((ex_rd == rs1) || (ex_rd == rs2));

    assign bubble = id_jump || bubble_load;
endmodule
