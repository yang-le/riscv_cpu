`include "rvc_def.vh"
`include "defines.vh"

module rvc #(
    parameter XLEN = 32
)(
    input clock,
    input [XLEN - 1:0] pc,
    input [15:0] inst_in,
    output reg [31:0] inst_out
);
    wire [31:0] imm;
    wire [4:0] rs1, rs2, rd;
    rvc_decode #(
        .XLEN(XLEN)
    ) rvc_decode_inst (
        .inst(inst_in),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm)
    );
    
    wire rv32 = XLEN == 32;

    localparam [4:0] x0 = 0;
    localparam [4:0] x1 = 1;
    localparam [4:0] x2 = 2;

    always @(*) case(inst_in[1:0])
        0: case (inst_in[15:13])
            `C_LW:      inst_out = {imm[11:0], rs1, `LW, rd, `LOAD};
            `C_LD:      inst_out = {imm[11:0], rs1, `LD, rd, `LOAD};
            // `C_LQ:      inst_out = {imm[11:0], rs1, `LQ, rd, `LOAD};
            `C_SW:      inst_out = {imm[11:5], rs2, rs1, `SW, imm[4:0], `STORE};
            `C_SD:      inst_out = {imm[11:5], rs2, rs1, `SD, imm[4:0], `STORE};
            // `C_SQ:      inst_out = {imm[11:5], rs2, rs1, `SQ, imm[4:0], `STORE};
            `C_ADDI4SPN:inst_out = {imm[11:0], x2, `ADDI, rd, `OP_IMM};
            default:    inst_out = 0;
        endcase
        1: case (inst_in[15:13])
            `C_J:       inst_out = {imm[20], imm[10:1], imm[11], imm[19:12], x0, `JAL};
            `C_BEQZ:    inst_out = {imm[12], imm[10:5], x0, rs1, `BEQ, imm[4:1], imm[11], `BRANCH};
            `C_BNEZ:    inst_out = {imm[12], imm[10:5], x0, rs1, `BNE, imm[4:1], imm[11], `BRANCH};
            `C_ADDI:    inst_out = {imm[11:0], rd, `ADDI, rd, `OP_IMM};
            `C_LI:      inst_out = {imm[11:0], x0, `ADDI, rd, `OP_IMM};
            `C_LUI:     inst_out = (rs1 == 5'h2) ? {imm[11:0], x2, `ADDI, x2, `OP_IMM} : {imm[31:12], rd, `LUI};
            `C_ADDIW:   inst_out = rv32 ? {imm[20], imm[10:1], imm[11], imm[19:12], x1, `JAL} : {imm[11:0], rd, `ADDIW, rd, `OP_IMM_32};
            default: case (inst_in[11:10])
                2'b00:  inst_out = {7'b0000000, imm[4:0], rd, `SRLI, rd, `OP_IMM};
                2'b01:  inst_out = {7'b0100000, imm[4:0], rd, `SRAI, rd, `OP_IMM};
                2'b10:  inst_out = {imm[11:0], rd, `ANDI, rd, `OP_IMM};
                default: case ({inst_in[12], inst_in[6:5]})
                3'b000: inst_out = {7'b0100000, rs2, rd, `SUB, rd, `OP};
                3'b001: inst_out = {7'b0000000, rs2, rd, `XOR, rd, `OP};
                3'b010: inst_out = {7'b0000000, rs2, rd, `OR, rd, `OP};
                3'b011: inst_out = {7'b0000000, rs2, rd, `AND, rd, `OP};
                3'b100: inst_out = {7'b0100000, rs2, rd, `SUBW, rd, `OP};
                3'b101: inst_out = {7'b0000000, rs2, rd, `ADDW, rd, `OP};
                default:inst_out = 0;
                endcase
            endcase
        endcase
        2: case (inst_in[15:13])
            `C_SLLI:    inst_out = {7'b0000000, imm[4:0], rd, `SLLI, rd, `OP_IMM};
            `C_LWSP:    inst_out = {imm[11:0], x2, `LW, rd, `LOAD};
            `C_LDSP:    inst_out = {imm[11:0], x2, `LD, rd, `LOAD};
            // `C_LQSP:    inst_out = {imm[11:0], x2, `LQ, rd, `LOAD};
            `C_SWSP:    inst_out = {imm[11:5], rs2, x2, `SW, imm[4:0], `STORE};
            `C_SDSP:    inst_out = {imm[11:5], rs2, x2, `SD, imm[4:0], `STORE};
            // `C_SQSP:    inst_out = {imm[11:5], rs2, x2, `SQ, imm[4:0], `STORE};
            default: case ({inst_in[12], rs1 != 0, rs2 != 0})
                3'b010: inst_out = {12'b0, rs1, 3'b0, x0, `JALR};
                3'b011: inst_out = {7'b0000000, rs2, x0, `ADD, rd, `OP};
                3'b100: inst_out = `INST_EBREAK;
                3'b110: inst_out = {12'b0, rs1, 3'b0, x1, `JALR};
                3'b111: inst_out = {7'b0000000, rs2, rd, `ADD, rd, `OP};
                default:inst_out = 0;
            endcase
        endcase
        default:        inst_out = 0;
    endcase

    always @(posedge clock) case(inst_in[1:0])
        0: case (inst_in[15:13])
            `C_LW:      $display("rvc: %x: C.LW: lw rd, offset(rs1)", pc);
            `C_LD:      $display("rvc: %x: C.LD: ld rd, offset(rs1)", pc);
            `C_LQ:      $display("rvc: %x: C.LQ: lq rd, offset(rs1)", pc);
            `C_SW:      $display("rvc: %x: C.SW: sw rs2, offset(rs1)", pc);
            `C_SD:      $display("rvc: %x: C.SD: sd rs2, offset(rs1)", pc);
            `C_SQ:      $display("rvc: %x: C.SQ: sq rs2, offset(rs1)", pc);
            `C_ADDI4SPN:$display("rvc: %x: C.ADDI4SPN: addi rd, x2, nzimm", pc);
            default:    $display("error: %x: C0 but unknown funct3 %b", pc, inst_in[15:13]);
        endcase
        1: case (inst_in[15:13])
            `C_J:       $display("rvc: %x: C.J: jal x0, offset", pc);
            `C_BEQZ:    $display("rvc: %x: C.BEQZ: beq rs1, x0, offset", pc);
            `C_BNEZ:    $display("rvc: %x: C.BNEZ: bne rs1, x0, offset", pc);
            `C_ADDI:    $display("rvc: %x: C.ADDI: addi rd, rd, nzimm", pc);
            `C_LI:      $display("rvc: %x: C.LI: addi rd, x0, imm", pc);
            `C_LUI:     if (rs1 == 5'h2) $display("rvc: %x: C.ADDI16SP: addi x2, x2, nzimm", pc); else $display("rvc: %x: C.LUI: lui rd, nzimm", pc);
            `C_ADDIW:   if (rv32) $display("rvc: %x: C.JAL: jal x1, offset", pc); else $display("rvc: %x: C.ADDIW: addiw rd, rd, imm", pc);
            default: case (inst_in[11:10])
                2'b00:  $display("rvc: %x: C.SRLI: srli rd, rd, shamt", pc);
                2'b01:  $display("rvc: %x: C.SRAI: srai rd, rd, shamt", pc);
                2'b10:  $display("rvc: %x: C.ANDI: andi rd, rd, imm", pc);
                default: case ({inst_in[12], inst_in[6:5]})
                3'b000: $display("rvc: %x: C.SUB: sub rd, rd, rs2", pc);
                3'b001: $display("rvc: %x: C.XOR: xor rd, rd, rs2", pc);
                3'b010: $display("rvc: %x: C.OR: or rd, rd, rs2", pc);
                3'b011: $display("rvc: %x: C.AND: and rd, rd, rs2", pc);
                3'b100: $display("rvc: %x: C.SUBW: subw rd, rd, rs2", pc);
                3'b101: $display("rvc: %x: C.ADDW: addw rd, rd, rs2", pc);
                default:$display("error: %x: C1 but unknown inst %b", pc, inst_in);
                endcase
            endcase
        endcase
        2: case (inst_in[15:13])
            `C_SLLI:    $display("rvc: %x: C.SLLI: slli rd, rd, shamt", pc);
            `C_LWSP:    $display("rvc: %x: C.LWSP: lw rd, offset(x2)", pc);
            `C_LDSP:    $display("rvc: %x: C.LDSP: ld rd, offset(x2)", pc);
            `C_LQSP:    $display("rvc: %x: C.LQSP: lq rd, offset(x2)", pc);
            `C_SWSP:    $display("rvc: %x: C.SWSP: sw rs2, offset(x2)", pc);
            `C_SDSP:    $display("rvc: %x: C.SDSP: sd rs2, offset(x2)", pc);
            `C_SQSP:    $display("rvc: %x: C.SQSP: sq rs2, offset(x2)", pc);
            default: case ({inst_in[12], rs1 != 0, rs2 != 0})
                3'b010: $display("rvc: %x: C.JR: jalr x0, 0(rs1)", pc);
                3'b011: $display("rvc: %x: C.MV: add rd, x0, rs2", pc);
                3'b100: $display("rvc: %x: C.EBREAK: ebreak", pc);
                3'b110: $display("rvc: %x: C.JALR: jalr, x1, 0(rs1)", pc);
                3'b111: $display("rvc: %x: C.ADD: add rd, rd, rs2", pc);
                default:$display("error: %x: C2 but unknown inst %b", pc, inst_in);
            endcase
        endcase
    endcase
endmodule

module rvc_decode #(
    parameter XLEN = 32
)(
    input [15:0] inst,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [31:0] imm
);
    wire [3:0] itype;
    rvc_inst_type #(
        .XLEN(XLEN)
    ) rvc_inst_type_inst (
        .inst(inst),
        .itype(itype)
    );

    rvc_imm_gen #(
        .XLEN(XLEN)
    ) rvc_imm_gen_inst (
        .inst(inst),
        .imm(imm)
    );

    assign rs1 = (itype == `TYPE_CR || itype == `TYPE_CI) ? inst[11:7] : {2'b01, inst[9:7]};
    assign rs2 = (itype == `TYPE_CR || itype == `TYPE_CSS) ? inst[6:2] : {2'b01, inst[4:2]};
    assign rd = (itype == `TYPE_CIW || itype == `TYPE_CL) ? rs2 : rs1;
endmodule

module rvc_inst_type #(
	parameter XLEN = 32
)(
    input [15:0] inst,
    output reg [3:0] itype
);
    wire rv32 = XLEN == 32;

    always @(*) case(inst[1:0])
        0: case (inst[15:13])
            `C_LW,
            `C_LD,
            `C_LQ:      itype = `TYPE_CL;
            `C_SW,
            `C_SD,
            `C_SQ:      itype = `TYPE_CS;
            `C_ADDI4SPN:itype = `TYPE_CIW;
            default:    itype = 0;
        endcase
        1: case (inst[15:13])
            `C_J:       itype = `TYPE_CJ;
            `C_BEQZ,
            `C_BNEZ:    itype = `TYPE_CB;
            `C_ADDI,
            `C_LI,
            `C_LUI:     itype = `TYPE_CI;
            `C_ADDIW:   itype = rv32 ? `TYPE_CJ : `TYPE_CI;
            default:    itype = (inst[11:10] == 2'b11) ? `TYPE_CR : `TYPE_CB;
        endcase
        2: case (inst[15:13])
            `C_SLLI,
            `C_LWSP,
            `C_LDSP,
            `C_LQSP:    itype = `TYPE_CI;
            `C_SWSP,
            `C_SDSP,
            `C_SQSP:    itype = `TYPE_CSS;
            default:    itype = `TYPE_CR;
        endcase
        default:        itype = 0;
    endcase
endmodule

module rvc_imm_gen #(
	parameter XLEN = 32
)(
    input [15:0] inst,
    output reg [31:0] imm
);
    wire [31:0] uimm0_q = $unsigned({inst[10], inst[6:5], inst[12:11], 4'b0});
    wire [31:0] uimm0_d = $unsigned({inst[6:5], inst[12:10], 3'b0});
    wire [31:0] uimm0_w = $unsigned({inst[5], inst[12:10], inst[6], 2'b0});
    
    wire [31:0] uimm0_qd;
generate if (XLEN == 128)
    assign uimm0_qd = uimm0_q;
else
    assign uimm0_qd = uimm0_d;
endgenerate

    wire [31:0] uimm0_dw;
generate if (XLEN == 32)
    assign uimm0_dw = uimm0_w;
else
    assign uimm0_dw = uimm0_d;
endgenerate

    wire [31:0] imm1 = $signed({inst[12], inst[6:2]});
    wire [31:0] imm1_sp = $signed({inst[12], inst[4:3], inst[5], inst[2], inst[6], 4'b0});
    wire [31:0] imm1_lui = $signed({inst[12], inst[6:2], 12'b0});
    wire [31:0] imm1_b = $signed({inst[12], inst[6:5], inst[2], inst[11:10], inst[4:3], 1'b0});
    wire [31:0] imm1_j = $signed({inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3], 1'b0});

    wire [31:0] imm1_xj;
generate if (XLEN == 32)
    assign imm1_xj = imm1_j;
else
    assign imm1_xj = imm1;
endgenerate

    wire [31:0] uimm2_lq = $unsigned({inst[5:2], inst[12], inst[6], 4'b0});
    wire [31:0] uimm2_ld = $unsigned({inst[4:2], inst[12], inst[6:5], 3'b0});
    wire [31:0] uimm2_lw = $unsigned({inst[3:2], inst[12], inst[6:4], 2'b0});
    
    wire [31:0] uimm2_sq = $unsigned({inst[10:7], inst[12:11], 4'b0});
    wire [31:0] uimm2_sd = $unsigned({inst[9:7], inst[12:10], 3'b0});
    wire [31:0] uimm2_sw = $unsigned({inst[8:7], inst[12:9], 2'b0});

    wire [31:0] uimm2_lqd, uimm2_sqd;
generate if (XLEN == 128) begin
    assign uimm2_lqd = uimm2_lq;
    assign uimm2_sqd = uimm2_sq;
end else begin
    assign uimm2_lqd = uimm2_ld;
    assign uimm2_sqd = uimm2_sd;
end endgenerate

    wire [31:0] uimm2_ldw, uimm2_sdw;
generate if (XLEN == 32) begin
    assign uimm2_ldw = uimm2_lw;
    assign uimm2_sdw = uimm2_sw;
end else begin
    assign uimm2_ldw = uimm2_ld;
    assign uimm2_sdw = uimm2_sd;
end endgenerate

    always @(*) case (inst[1:0])
        0: case (inst[15:13])
            `C_ADDI4SPN:    imm = $unsigned({inst[10:7], inst[12:11], inst[5], inst[6], 2'b0});
            `C_LQ,
            `C_SQ:          imm = uimm0_qd;
            `C_LD,
            `C_SD:          imm = uimm0_dw;
            `C_LW,
            `C_SW:          imm = uimm0_w;
            default:        imm = 0;
        endcase
        1: case (inst[15:13])
            `C_ADDIW:       imm = imm1_xj;
            `C_J:           imm = imm1_j;
            `C_LUI:         imm = (inst[11:7] == 5'b00010) ? imm1_sp : imm1_lui;
            `C_BEQZ,
            `C_BNEZ:        imm = imm1_b;
            default:        imm = imm1;
        endcase
        2: case (inst[15:13])
            `C_SLLI:        imm = $unsigned({inst[12], inst[6:2]});
            `C_LQSP:        imm = uimm2_lqd;
            `C_LDSP:        imm = uimm2_ldw;
            `C_LWSP:        imm = uimm2_lw;
            `C_SQSP:        imm = uimm2_sqd;
            `C_SDSP:        imm = uimm2_sdw;
            `C_SWSP:        imm = uimm2_sw;
            default:        imm = 0;
        endcase
        default:            imm = 0;
    endcase
endmodule
