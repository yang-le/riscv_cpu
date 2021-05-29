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
    input [XLEN - 1:0] pc,
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
`ifdef VERILATOR
    always @(*)
        if (inst == 0 && $time > 1) $finish;
`endif
`ifdef DEBUG
    always @(posedge clock) case (opcode)
        `LUI:       $display("decode: %x: LUI", pc);
        `OP_IMM: case (funct3)
            `ADDI:	$display("decode: %x: ADDI", pc);
            `SLTI: 	$display("decode: %x: SLTI", pc);
            `SLTIU:	$display("decode: %x: SLTIU", pc);
            `ANDI: 	$display("decode: %x: ANDI", pc);
            `ORI:	$display("decode: %x: ORI", pc);
            `XORI:	$display("decode: %x: XORI", pc);
            `SLLI:	if (funct7 == `FUNC7_SLLI) $display("decode: %x: SLLI", pc); else $display("error: %x: SLLI but unknown funct7 %b", pc, funct7);
            `SRLI:	if (funct7 == `FUNC7_SRLI) $display("decode: %x: SRLI", pc); else
                        if (funct7 == `FUNC7_SRAI) $display("decode: %x: SRAI", pc); else $display("error: %x: SRLI but unknown funct7 %b", pc, funct7);
            default:$display("error: %x: OP_IMM but unknown funct3 %b", pc, funct3);
        endcase
        `OP: case (funct3)
            `ADD:	if (funct7 == `FUNC7_ADD) $display("decode: %x: ADD", pc); else
                        if (funct7 == `FUNC7_SUB) $display("decode: %x: SUB", pc); else $display("error: %x: ADD but unknown funct7 %b", pc, funct7);
            `SLT:	if (funct7 == `FUNC7_SLT) $display("decode: %x: SLT", pc); else  $display("error: %x: SLT but unknown funct7 %b", pc, funct7);
            `SLTU:	if (funct7 == `FUNC7_SLTU) $display("decode: %x: SLTU", pc); else  $display("error: %x: SLTU but unknown funct7 %b", pc, funct7);
            `AND:	if (funct7 == `FUNC7_AND) $display("decode: %x: AND", pc); else  $display("error: %x: AND but unknown funct7 %b", pc, funct7);
            `OR:	if (funct7 == `FUNC7_OR) $display("decode: %x: OR", pc); else  $display("error: %x: OR but unknown funct7 %b", pc, funct7);
            `XOR:	if (funct7 == `FUNC7_XOR) $display("decode: %x: XOR", pc); else  $display("error: %x: XOR but unknown funct7 %b", pc, funct7);
            `SLL:	if (funct7 == `FUNC7_SLL) $display("decode: %x: SLL", pc); else  $display("error: %x: SLL but unknown funct7 %b", pc, funct7);
            `SRL:	if (funct7 == `FUNC7_SRL) $display("decode: %x: SRL", pc); else
                        if (funct7 == `FUNC7_SRA) $display("decode: %x: SRA", pc); else  $display("error: %x: SRL but unknown funct7 %b", pc, funct7);
            default:$display("error: %x: OP but unknown funct3 %b", pc, funct3);
        endcase
        `BRANCH: case (funct3)
            `BEQ:   $display("decode: %x: BEQ", pc);
            `BNE:   $display("decode: %x: BNE", pc);
            `BLT:   $display("decode: %x: BLT", pc);
            `BGE:   $display("decode: %x: BGE", pc);
            `BLTU:  $display("decode: %x: BLTU", pc);
            `BGEU:  $display("decode: %x: BGEU", pc);
            default:$display("error: %x: BRANCH but unknown funct3 %b", pc, funct3);
        endcase
        `LOAD: case (funct3)
            `LB:    $display("decode: %x: LB", pc);
            `LH:    $display("decode: %x: LH", pc);
            `LW:    $display("decode: %x: LW", pc);
            `LBU:   $display("decode: %x: LBU", pc);
            `LHU:   $display("decode: %x: LHU", pc);
            default:$display("error: LOAD but unknown funct3 %b", pc, funct3);
        endcase
        `STORE: case (funct3)
            `SB:    $display("decode: %x: SB", pc);
            `SH:    $display("decode: %x: SH", pc);
            `SW:    $display("decode: %x: SW", pc);
            default:$display("error: %x: STORE but unknown funct3 %b", pc, funct3);
        endcase
        `AUIPC:     $display("decode: %x: AUIPC", pc);
        `JAL:       $display("decode: %x: JAL", pc);
        `JALR:      $display("decode: %x: JALR", pc);
        `MISC_MEM: case (funct3)
            `FENCE: case (inst[31:28])
                4'b0000: $display("decode: %x: FENCE", pc);
                `TSO: if (inst[27:20] == 8'b00110011) $display("decode: %x: FENCE.TSO", pc); else $display("error: %x: FENCE.TSO but unknown pred %x, succ %x", pc, inst[27:24], inst[23:20]);
                default: $display("error: %x: FENCE but unknown fm %x", pc, inst[31:28]);
            endcase
            default:$display("error: %x: MISC_MEM but unknown funct3 %b", pc, funct3);
        endcase
        `SYSTEM: case (funct3)
            `ENV: if (imm == `IMM_ECALL) $display("decode: %x: ECALL", pc); else
                            if (imm == `IMM_EBREAK) $display("decode: %x: EBREAK", pc); else $display("error: %x: SYSTEM_ENV but unknown imm %b", pc, imm);
            `CSRRW: $display("decode: %x: CSRRW", pc);
            `CSRRS: $display("decode: %x: CSRRS", pc);
            `CSRRC: $display("decode: %x: CSRRC", pc);
            `CSRRWI:$display("decode: %x: CSRRWI", pc);
            `CSRRSI:$display("decode: %x: CSRRSI", pc);
            `CSRRCI:$display("decode: %x: CSRRCI", pc);
            default:$display("error: %x: SYSTEM but unknown funct3 %b", pc, funct3);
        endcase
        default:    $display("error: %x: unknown opcode %b", pc, opcode);
    endcase
`endif
endmodule
