`include "defines.vh"

module inst_type (
    input [6:0] opcode,
    output reg [2:0] itype
);
    always @(*) case (opcode)
        `LUI,
        `AUIPC:     itype <= `TYPE_U;
        `JAL:       itype <= `TYPE_J;
        `BRANCH:    itype <= `TYPE_B;
        `LOAD,
        `OP_IMM,
        `JALR,
        `MISC_MEM,
        `SYSTEM:    itype <= `TYPE_I;
        `STORE:     itype <= `TYPE_S;
        `OP:        itype <= `TYPE_R;
        default:    itype <= 0;
	endcase
endmodule

module imm_gen #(
	parameter XLEN = 32
)(
    input [31:0] inst,
    input [2:0] itype,
    output reg [XLEN - 1:0] imm
);
    always @(*) case (itype)
        `TYPE_I: imm <= {{21{inst[31]}}, inst[30:20]};
        `TYPE_S: imm <= {{21{inst[31]}}, inst[30:25], inst[11:7]};
        `TYPE_B: imm <= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        `TYPE_U: imm <= {inst[31:12], 12'b0};
        `TYPE_J: imm <= {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
        default: imm <= 0;
    endcase
endmodule

module decoder #(
	parameter XLEN = 32
)(
`ifdef DEBUG
    input clock,
`endif
    input [31:0] inst,
    output [6:0] opcode,
    output [4:0] rd,
    output [2:0] funct3,
    output [4:0] rs1,
    output [4:0] rs2,
    output [6:0] funct7,
    output [XLEN - 1:0] imm,
    output reg [3:0] alu_op,
    output s_pc,
    output s_imm,
    output s_jalr,
    output s_jump,
    output s_branch,
    output s_branch_zero,
    output s_load,
    output s_store,
    output s_csr,
    output s_csri,
    output s_csrsc,
    output [2:0] itype
);
    assign opcode = inst[6:0];
    assign rd = (itype == `TYPE_S || itype == `TYPE_B) ? 0 : inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1 = (itype == `TYPE_U || itype == `TYPE_J) ? 0 : inst[19:15];
    assign rs2 = (itype == `TYPE_I || itype == `TYPE_U || itype == `TYPE_J) ? 0 : inst[24:20];
    assign funct7 = inst[31:25];

    assign s_jalr = opcode == `JALR && funct3 == `FUNC3_JALR;
    assign s_jump = opcode == `JAL || s_jalr;
    assign s_pc = opcode == `AUIPC || opcode == `JAL;

    assign s_imm = !(opcode == `OP || opcode == `BRANCH || s_csr);
    assign s_branch = opcode == `BRANCH && (funct3 == `BEQ || funct3 == `BNE || funct3 == `BLT || funct3 == `BGE || funct3 == `BLTU || funct3 == `BGEU);
    assign s_branch_zero = opcode == `BRANCH && (funct3 == `BEQ || funct3 == `BGE || funct3 == `BGEU);

    assign s_load = opcode == `LOAD && (funct3 == `LB || funct3 == `LH || funct3 == `LW || funct3 == `LBU || funct3 == `LHU);
    assign s_store = opcode == `STORE && (funct3 == `SB || funct3 == `SH || funct3 == `SW);

    assign s_csr = opcode == `SYSTEM && (funct3 == `CSRRW || funct3 == `CSRRS || funct3 == `CSRRC || funct3 == `CSRRWI || funct3 == `CSRRSI || funct3 == `CSRRCI);
    assign s_csrsc = opcode == `SYSTEM && (funct3 == `CSRRS || funct3 == `CSRRC || funct3 == `CSRRSI || funct3 == `CSRRCI);
    assign s_csri = opcode == `SYSTEM && (funct3 == `CSRRWI || funct3 == `CSRRSI || funct3 == `CSRRCI);

    inst_type inst_type_inst (
        .opcode(opcode),
        .itype(itype)
    );

    imm_gen imm_gen_inst (
        .inst(inst),
        .itype(itype),
        .imm(imm)
    );

    always @(*) case (opcode)
        `LUI:       alu_op <= `ALU_ADD;
        `OP_IMM: case (funct3)
            `ADDI:	alu_op <= `ALU_ADD;
            `SLTI: 	alu_op <= `ALU_CMP;
            `SLTIU:	alu_op <= `ALU_UCMP;
            `ANDI: 	alu_op <= `ALU_AND;
            `ORI:	alu_op <= `ALU_OR;
            `XORI:	alu_op <= `ALU_XOR;
            `SLLI:	alu_op <= funct7 == `FUNC7_SLLI ? `ALU_SLL : 0;
            `SRLI:	alu_op <= funct7 == `FUNC7_SRLI ? `ALU_SRL : 
                                funct7 == `FUNC7_SRAI ? `ALU_SRA : 0;
            default:alu_op <= 0;
        endcase
        `OP: case (funct3)
            `ADD:	alu_op <= funct7 == `FUNC7_ADD ? `ALU_ADD :
                                funct7 == `FUNC7_SUB ? `ALU_SUB : 0;
            `SLT:	alu_op <= funct7 == `FUNC7_SLT ? `ALU_CMP : 0;
            `SLTU:	alu_op <= funct7 == `FUNC7_SLTU ? `ALU_UCMP : 0;
            `AND:	alu_op <= funct7 == `FUNC7_AND ? `ALU_AND : 0;
            `OR:	alu_op <= funct7 == `FUNC7_OR ? `ALU_OR : 0;
            `XOR:	alu_op <= funct7 == `FUNC7_XOR ? `ALU_XOR : 0;
            `SLL:	alu_op <= funct7 == `FUNC7_SLL ? `ALU_SLL : 0;
            `SRL:	alu_op <= funct7 == `FUNC7_SRL ? `ALU_SRL :
                                funct7 == `FUNC7_SRA ? `ALU_SRA : 0;
            default:alu_op <= 0;
        endcase
        `BRANCH: case (funct3)
            `BEQ,
            `BNE:   alu_op <= `ALU_SUB;
            `BLT,
            `BGE:   alu_op <= `ALU_CMP;
            `BLTU,
            `BGEU:  alu_op <= `ALU_UCMP;
            default:alu_op <= 0;
        endcase
        `SYSTEM: case (funct3)
            `CSRRW,
            `CSRRWI,
            `CSRRS,
            `CSRRSI:alu_op <= `ALU_OR;
            `CSRRC,
            `CSRRCI:alu_op <= `ALU_AND;
            default:alu_op <= 0;
        endcase
        default:    alu_op <= (s_load || s_store || s_pc) ? `ALU_ADD : 0;
    endcase
`ifdef DEBUG
    always @(posedge clock)
        if (inst == 0 && $time > `CYCLE) $finish;

    always @(posedge clock) case (opcode)
        `LUI:       $display("decode: LUI");
        `OP_IMM: case (funct3)
            `ADDI:	$display("decode: ADDI");
            `SLTI: 	$display("decode: SLTI");
            `SLTIU:	$display("decode: SLTIU");
            `ANDI: 	$display("decode: ANDI");
            `ORI:	$display("decode: ORI");
            `XORI:	$display("decode: XORI");
            `SLLI:	if (funct7 == `FUNC7_SLLI) $display("decode: SLLI"); else $display("decode: SLLI but unknown funct7 %b", funct7);
            `SRLI:	if (funct7 == `FUNC7_SRLI) $display("decode: SRLI"); else
                        if (funct7 == `FUNC7_SRAI) $display("decode: SRAI"); else $display("decode: SRLI but unknown funct7 %b", funct7);
            default:$display("decode: OP_IMM but unknown funct3 %b", funct3);
        endcase
        `OP: case (funct3)
            `ADD:	if (funct7 == `FUNC7_ADD) $display("decode: ADD"); else
                        if (funct7 == `FUNC7_SUB) $display("decode: SUB"); else $display("decode: ADD but unknown funct7 %b", funct7);
            `SLT:	if (funct7 == `FUNC7_SLT) $display("decode: SLT"); else  $display("decode: SLT but unknown funct7 %b", funct7);
            `SLTU:	if (funct7 == `FUNC7_SLTU) $display("decode: SLTU"); else  $display("decode: SLTU but unknown funct7 %b", funct7);
            `AND:	if (funct7 == `FUNC7_AND) $display("decode: AND"); else  $display("decode: AND but unknown funct7 %b", funct7);
            `OR:	if (funct7 == `FUNC7_OR) $display("decode: OR"); else  $display("decode: OR but unknown funct7 %b", funct7);
            `XOR:	if (funct7 == `FUNC7_XOR) $display("decode: XOR"); else  $display("decode: XOR but unknown funct7 %b", funct7);
            `SLL:	if (funct7 == `FUNC7_SLL) $display("decode: SLL"); else  $display("decode: SLL but unknown funct7 %b", funct7);
            `SRL:	if (funct7 == `FUNC7_SRL) $display("decode: SRL"); else
                        if (funct7 == `FUNC7_SRA) $display("decode: SRA"); else  $display("decode: SRL but unknown funct7 %b", funct7);
            default:$display("decode: OP but unknown funct3 %b", funct3);
        endcase
        `BRANCH: case (funct3)
            `BEQ:   $display("decode: BEQ");
            `BNE:   $display("decode: BNE");
            `BLT:   $display("decode: BLT");
            `BGE:   $display("decode: BGE");
            `BLTU:  $display("decode: BLTU");
            `BGEU:  $display("decode: BGEU");
            default:$display("decode: BRANCH but unknown funct3 %b", funct3);
        endcase
        `LOAD: case (funct3)
            `LB:    $display("decode: LB");
            `LH:    $display("decode: LH");
            `LW:    $display("decode: LW");
            `LBU:   $display("decode: LBU");
            `LHU:   $display("decode: LHU");
            default:$display("decode: LOAD but unknown funct3 %b", funct3);
        endcase
        `STORE: case (funct3)
            `SB:    $display("decode: SB");
            `SH:    $display("decode: SH");
            `SW:    $display("decode: SW");
            default:$display("decode: STORE but unknown funct3 %b", funct3);
        endcase
        `AUIPC:     $display("decode: AUIPC");
        `JAL:       $display("decode: JAL");
        `JALR:      $display("decode: JALR");
        `MISC_MEM: case (funct3)
            `FENCE: case (inst[31:28])
                4'b0000: $display("decode: FENCE");
                `TSO: if (inst[27:20] == 8'b00110011) $display("decode: FENCE.TSO"); else $display("decode: FENCE.TSO but unknown pred %x, succ %x", inst[27:24], inst[23:20]);
                default: $display("decode: FENCE but unknown fm %x", inst[31:28]);
            endcase
            default:$display("decode: MISC_MEM but unknown funct3 %b", funct3);
        endcase
        `SYSTEM: case (funct3)
            `ENV: if (imm == `IMM_ECALL) $display("decode: ECALL"); else
                            if (imm == `IMM_EBREAK) $display("decode: EBREAK"); else $display("decode: SYSTEM_ENV but unknown imm %b", imm);
            `CSRRW: $display("decode: CSRRW");
            `CSRRS: $display("decode: CSRRS");
            `CSRRC: $display("decode: CSRRC");
            `CSRRWI:$display("decode: CSRRWI");
            `CSRRSI:$display("decode: CSRRSI");
            `CSRRCI:$display("decode: CSRRCI");
            default:$display("decode: SYSTEM but unknown funct3 %b", funct3);
        endcase
        default:    $display("decode: unknown opcode %b", opcode);
    endcase
`endif
endmodule
