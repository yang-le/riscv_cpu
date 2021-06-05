// opcode
`define LOAD 		7'b0000011
`define LOAD_FP 	7'b0000111
`define MISC_MEM 	7'b0001111
`define OP_IMM		7'b0010011
`define AUIPC		7'b0010111
`define OP_IMM_32	7'b0011011

`define STORE		7'b0100011
`define STORE_FP	7'b0100111
`define AMO			7'b0101111
`define OP			7'b0110011
`define LUI			7'b0110111
`define OP_32		7'b0111011

`define MADD		7'b1000011
`define MSUB		7'b1000111
`define NMSUB		7'b1001011
`define NMADD		7'b1001111
`define OP_FP		7'b1010011

`define BRANCH		7'b1100011
`define JALR		7'b1100111
`define JAL			7'b1101111
`define SYSTEM		7'b1110011

`define FUNC3_JALR	3'b000

// branch
`define BEQ			3'b000
`define BNE			3'b001
`define BLT			3'b100
`define BGE			3'b101
`define BLTU		3'b110
`define BGEU		3'b111

// load
`define LB			3'b000
`define LH			3'b001
`define LW			3'b010
`define LBU			3'b100
`define LHU			3'b101

// store
`define SB			3'b000
`define SH			3'b001
`define SW			3'b010

// op
`define ADD			3'b000
`define ADDI		3'b000
`define SUB			3'b000
`define SLL			3'b001
`define SLLI		3'b001
`define SLT			3'b010
`define SLTI		3'b010
`define SLTU		3'b011
`define SLTIU		3'b011
`define XOR			3'b100
`define XORI		3'b100
`define SRL			3'b101
`define SRLI		3'b101
`define SRA			3'b101
`define SRAI		3'b101
`define OR			3'b110
`define ORI			3'b110
`define AND			3'b111
`define ANDI		3'b111

// fence
`define FENCE		3'b000
`define TSO         4'b1000

// system
`define ENV         3'b000
`define CSRRW       3'b001
`define CSRRS       3'b010
`define CSRRC       3'b011
`define CSRRWI      3'b101
`define CSRRSI      3'b110
`define CSRRCI      3'b111

`define IMM_ECALL   0
`define IMM_EBREAK  1

// muldiv
`define MUL         3'b000
`define MULH        3'b001
`define MULHSU      3'b010
`define MULHU       3'b011
`define DIV         3'b100
`define DIVU        3'b101
`define REM         3'b110
`define REMU        3'b111

// inst type
`define TYPE_R      1
`define TYPE_I      2
`define TYPE_S      3
`define TYPE_B      4
`define TYPE_U      5
`define TYPE_J      6

// alu
`define ALU_ADD     5'b00001
`define ALU_SUB     5'b00010
`define ALU_CMP     5'b00011
`define ALU_UCMP    5'b00100
`define ALU_AND     5'b00101
`define ALU_OR      5'b00110
`define ALU_XOR     5'b00111
`define ALU_SLL     5'b01000
`define ALU_SRL     5'b01001
`define ALU_SRA     5'b01010

`define ALU_MUL     5'b10000
`define ALU_MULH    5'b10001
`define ALU_MULHSU  5'b10010
`define ALU_MULHU   5'b10011

`define ALU_DIV     5'b10100
`define ALU_DIVU    5'b10101
`define ALU_REM     5'b10110
`define ALU_REMU    5'b10111

// other
`define DEBUG
`define NOP     32'h00000013
