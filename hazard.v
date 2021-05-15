
module hazard(
    input ex_load,
    input [4:0] ex_rd,
    input [4:0] rs1,
    input [4:0] rs2,
    output bubble
);

    assign bubble = ex_load && ((ex_rd == rs1) || (ex_rd == rs2));

endmodule
