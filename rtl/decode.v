`include "defines.vh"

module inst_type (
    input [6:0] opcode,
    output reg [2:0] itype
);
    always @(*) case (opcode)
        `LUI,
        `AUIPC:     itype = `TYPE_U;
        `JAL:       itype = `TYPE_J;
        `BRANCH:    itype = `TYPE_B;
        `LOAD,
        `OP_IMM,
        `OP_IMM_32,
        `JALR,
        `MISC_MEM,
        `SYSTEM:    itype = `TYPE_I;
        `STORE:     itype = `TYPE_S;
        `OP,
        `OP_32:     itype = `TYPE_R;
        default:    itype = 0;
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
        `TYPE_I: imm = $signed(inst[31:20]);
        `TYPE_S: imm = $signed({inst[31:25], inst[11:7]});
        `TYPE_B: imm = $signed({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0});
        `TYPE_U: imm = $signed({inst[31:12], 12'b0});
        `TYPE_J: imm = $signed({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0});
        default: imm = 0;
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
    output [2:0] itype,
    output [2:0] funct3,
    output [6:0] funct7,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [XLEN - 1:0] imm,
    output reg [4:0] alu_op,
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
    output s_csrw,
    output s_32,
    output s_flush,
    output s_ecall,
    output s_ebreak,
    output s_illegal
);
    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign rs1 = (itype == `TYPE_U || itype == `TYPE_J) ? 0 : inst[19:15];
    assign rs2 = (itype == `TYPE_I || itype == `TYPE_U || itype == `TYPE_J) ? 0 : inst[24:20];
    assign rd = (itype == `TYPE_S || itype == `TYPE_B) ? 0 : inst[11:7];

    assign s_jalr = opcode == `JALR && funct3 == `FUNC3_JALR;
    assign s_jump = opcode == `JAL || s_jalr;
    assign s_pc = opcode == `AUIPC || opcode == `JAL;

    assign s_imm = !(opcode == `OP || opcode == `OP_32 || opcode == `BRANCH || s_csr);
    assign s_branch = opcode == `BRANCH && (funct3 == `BEQ || funct3 == `BNE || funct3 == `BLT || funct3 == `BGE || funct3 == `BLTU || funct3 == `BGEU);
    assign s_branch_zero = opcode == `BRANCH && (funct3 == `BEQ || funct3 == `BGE || funct3 == `BGEU);

    assign s_load = opcode == `LOAD && (funct3 == `LB || funct3 == `LH || funct3 == `LW || funct3 == `LD || funct3 == `LBU || funct3 == `LHU || funct3 == `LWU);
    assign s_store = opcode == `STORE && (funct3 == `SB || funct3 == `SH || funct3 == `SW || funct3 == `SD);

    assign s_csr = opcode == `SYSTEM && (funct3 == `CSRRW || funct3 == `CSRRS || funct3 == `CSRRC || funct3 == `CSRRWI || funct3 == `CSRRSI || funct3 == `CSRRCI);
    assign s_csri = opcode == `SYSTEM && (funct3 == `CSRRWI || funct3 == `CSRRSI || funct3 == `CSRRCI);
    assign s_csrw = s_csr && (funct3 == `CSRRW || funct3 == `CSRRWI || |rs1);

    assign s_32 = opcode == `OP_32 || opcode == `OP_IMM_32;
    assign s_flush = opcode == `MISC_MEM && funct3 == `FENCE_I;
    assign s_ecall = inst == 32'h0000_0073;
    assign s_ebreak = inst == 32'h0010_0073;

    wire s_fence_tso = inst == 32'h8330_000f;
    wire s_fence = opcode == `MISC_MEM && funct3 == `FENCE && inst[31:28] == 4'b0000;
    assign s_illegal = alu_op == 5'b00000 && !s_flush && !s_ecall && !s_ebreak && !s_fence_tso && !s_fence;

    inst_type inst_type_inst (
        .opcode(opcode),
        .itype(itype)
    );

    imm_gen #(
        .XLEN(XLEN)
    )imm_gen_inst (
        .inst(inst),
        .itype(itype),
        .imm(imm)
    );

    always @(*) case (opcode)
        `LUI:       alu_op = `ALU_ADD;
        `OP_IMM: case (funct3)
            `ADDI:	alu_op = `ALU_ADD;
            `SLTI: 	alu_op = `ALU_CMP;
            `SLTIU:	alu_op = `ALU_UCMP;
            `ANDI: 	alu_op = `ALU_AND;
            `ORI:	alu_op = `ALU_OR;
            `XORI:	alu_op = `ALU_XOR;
            `SLLI:	alu_op = imm[11:6] == 6'b000000 ? `ALU_SLL : 0;
            `SRLI:	alu_op = imm[11:6] == 6'b000000 ? `ALU_SRL : imm[11:6] == 6'b010000 ? `ALU_SRA : 0;
            default:alu_op = 0;
        endcase
        `OP_IMM_32: case(funct3)
            `ADDIW:	alu_op = `ALU_ADD;
            `SLLIW: alu_op = imm[11:6] == 6'b000000 ? `ALU_SLL : 0;
            `SRLIW:	alu_op = imm[11:6] == 6'b000000 ? `ALU_SRL : imm[11:6] == 6'b010000 ? `ALU_SRA : 0;
            default:alu_op = 0;
        endcase
        `OP: case (funct7)
            7'b0000000: case (funct3)
                `ADD:	alu_op = `ALU_ADD;
                `SLT:	alu_op = `ALU_CMP;
                `SLTU:	alu_op = `ALU_UCMP;
                `AND:	alu_op = `ALU_AND;
                `OR:	alu_op = `ALU_OR;
                `XOR:	alu_op = `ALU_XOR;
                `SLL:	alu_op = `ALU_SLL;
                `SRL:	alu_op = `ALU_SRL;
                default:alu_op = 0;
            endcase
            7'b0100000: case (funct3)
                `SUB:   alu_op = `ALU_SUB;
                `SRA:   alu_op = `ALU_SRA;
                default:alu_op = 0;
            endcase
            7'b0000001: case (funct3)
                `MUL:   alu_op = `ALU_MUL;
                `MULH:  alu_op = `ALU_MULH;
                `MULHSU:alu_op = `ALU_MULHSU;
                `MULHU: alu_op = `ALU_MULHU;
                `DIV:   alu_op = `ALU_DIV;
                `DIVU:  alu_op = `ALU_DIVU;
                `REM:   alu_op = `ALU_REM;
                `REMU:  alu_op = `ALU_REMU;
                default:alu_op = 0;
            endcase
            default:alu_op = 0;
        endcase
        `OP_32: case (funct7)
            7'b0000000: case (funct3)
                `ADDW:	alu_op = `ALU_ADD;
                `SLLW:	alu_op = `ALU_SLL;
                `SRLW:	alu_op = `ALU_SRL;
                default:alu_op = 0;
            endcase
            7'b0100000: case (funct3)
                `SUBW:   alu_op = `ALU_SUB;
                `SRAW:   alu_op = `ALU_SRA;
                default:alu_op = 0;
            endcase
            7'b0000001: case (funct3)
                `MULW:   alu_op = `ALU_MUL;
                `DIVW:   alu_op = `ALU_DIV;
                `DIVUW:  alu_op = `ALU_DIVU;
                `REMW:   alu_op = `ALU_REM;
                `REMUW:  alu_op = `ALU_REMU;
                default:alu_op = 0;
            endcase
            default:alu_op = 0;
        endcase
        `BRANCH: case (funct3)
            `BEQ,
            `BNE:   alu_op = `ALU_SUB;
            `BLT,
            `BGE:   alu_op = `ALU_CMP;
            `BLTU,
            `BGEU:  alu_op = `ALU_UCMP;
            default:alu_op = 0;
        endcase
        default:    alu_op = (s_load || s_store || s_pc || s_jalr) ? `ALU_ADD : 0;
    endcase
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
            `SLLI:	if (imm[11:6] == 6'b000000) $display("decode: %x: SLLI", pc); else $display("error: %x: SLLI but unknown funct7 %b", pc, funct7);
            `SRLI:	if (imm[11:6] == 6'b000000) $display("decode: %x: SRLI", pc); else
                        if (imm[11:6] == 6'b010000) $display("decode: %x: SRAI", pc); else $display("error: %x: SRLI but unknown funct7 %b", pc, funct7);
            default:$display("error: %x: OP_IMM but unknown funct3 %b", pc, funct3);
        endcase
        `OP_IMM_32: case(funct3)
            `ADDIW:	$display("decode: %x: ADDIW", pc);
            `SLLIW: if (imm[11:6] == 6'b000000) $display("decode: %x: SLLIW", pc); else $display("error: %x: SLLIW but unknown funct7 %b", pc, funct7);
            `SRLIW:	if (imm[11:6] == 6'b000000) $display("decode: %x: SRLIW", pc); else
                        if (imm[11:6] == 6'b010000) $display("decode: %x: SRAIW", pc); else $display("error: %x: SRLIW but unknown funct7 %b", pc, funct7);
            default:$display("error: %x: OP_IMM_32 but unknown funct3 %b", pc, funct3);
        endcase 
        `OP: case (funct7)
            7'b0000000: case (funct3)
                `ADD:	$display("decode: %x: ADD", pc);
                `SLT:	$display("decode: %x: SLT", pc);
                `SLTU:	$display("decode: %x: SLTU", pc);
                `AND:	$display("decode: %x: AND", pc);
                `OR:	$display("decode: %x: OR", pc);
                `XOR:	$display("decode: %x: XOR", pc);
                `SLL:	$display("decode: %x: SLL", pc);
                `SRL:	$display("decode: %x: SRL", pc);
                default:$display("error: %x: OP funct7=0000000, but unknown funct3 %b", pc, funct3);
            endcase
            7'b0100000: case (funct3)
                `SUB:   $display("decode: %x: SUB", pc);
                `SRA:   $display("decode: %x: SRA", pc);
                default:$display("error: %x: OP funct7=0100000, but unknown funct3 %b", pc, funct3);
            endcase
            7'b0000001: case (funct3)
                `MUL:   $display("decode: %x: MUL", pc);
                `MULH:  $display("decode: %x: MULH", pc);
                `MULHSU:$display("decode: %x: MULHSU", pc);
                `MULHU: $display("decode: %x: MULHU", pc);
                `DIV:   $display("decode: %x: DIV", pc);
                `DIVU:  $display("decode: %x: DIVU", pc);
                `REM:   $display("decode: %x: REM", pc);
                `REMU:  $display("decode: %x: REMU", pc);
                default:$display("error: %x: OP funct7=0000001, but unknown funct3 %b", pc, funct3);
            endcase
            default:$display("error: %x: OP but unknown funct7 %b", pc, funct7);
        endcase
        `OP_32: case (funct7)
            7'b0000000: case (funct3)
                `ADDW:  $display("decode: %x: ADDW", pc);
                `SLLW:	$display("decode: %x: SLLW", pc);
                `SRLW:	$display("decode: %x: SRLW", pc);
                default:$display("error: %x: OP_32 funct7=0000000, but unknown funct3 %b", pc, funct3);
            endcase
            7'b0100000: case (funct3)
                `SUBW:  $display("decode: %x: SUBW", pc);
                `SRAW:  $display("decode: %x: SRAW", pc);
                default:$display("error: %x: OP_32 funct7=0100000, but unknown funct3 %b", pc, funct3);
            endcase
            7'b0000001: case (funct3)
                `MULW:  $display("decode: %x: MULW", pc);
                `DIVW:  $display("decode: %x: DIVW", pc);
                `DIVUW: $display("decode: %x: DIVUW", pc);
                `REMW:  $display("decode: %x: REMW", pc);
                `REMUW: $display("decode: %x: REMUW", pc);
                default:$display("error: %x: OP_32 funct7=0000001, but unknown funct3 %b", pc, funct3);
            endcase
            default:$display("error: %x: OP but unknown funct7 %b", pc, funct7);
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
            `LD:    $display("decode: %x: LD", pc);
            `LBU:   $display("decode: %x: LBU", pc);
            `LHU:   $display("decode: %x: LHU", pc);
            `LWU:   $display("decode: %x: LWU", pc);
            default:$display("error: LOAD but unknown funct3 %b", pc, funct3);
        endcase
        `STORE: case (funct3)
            `SB:    $display("decode: %x: SB", pc);
            `SH:    $display("decode: %x: SH", pc);
            `SW:    $display("decode: %x: SW", pc);
            `SD:    $display("decode: %x: SD", pc);
            default:$display("error: %x: STORE but unknown funct3 %b", pc, funct3);
        endcase
        `AUIPC:     $display("decode: %x: AUIPC", pc);
        `JAL:       $display("decode: %x: JAL", pc);
        `JALR:      $display("decode: %x: JALR", pc);
        `MISC_MEM: case (funct3)
            `FENCE: case (inst[31:28])
                4'b0000: $display("decode: %x: FENCE", pc);
                `TSO: if (s_fence_tso) $display("decode: %x: FENCE.TSO", pc); else $display("error: %x: invalid FENCE.TSO with pred %x, succ %x, rs1 %x, rd %x", pc, inst[27:24], inst[23:20], rs1, rd);
                default: $display("error: %x: FENCE but unknown fm %x", pc, inst[31:28]);
            endcase
            `FENCE_I: $display("decode: %x: FENCE_I", pc);
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
