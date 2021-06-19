`include "defines.vh"

module csr #(
	parameter XLEN = 32
)(
	input clock,
    input reset,
    input s_csr,
    input s_csrw,
    input s_ecall,
    input s_ebreak,
    input s_mret,
    input s_illegal,
	input s_load,
	input s_store,
	input [2:0] funct3,
	input [11:0] addr,
    input [XLEN - 1:0] mem_addr,
    input [XLEN - 1:0] pc_in,
    input [XLEN - 1:0] data_in,
    output s_exception,
    output [XLEN - 1:0] mtvec, mepc, mcause,
	output [XLEN - 1:0] data_out
);
    `define SIE 1
    `define MIE 3
    `define MPIE 7

    wire i_misalign, l_misalign, s_misalign;
    misalign_detector #(
        .XLEN(XLEN)
    ) misalign_detector_inst (
        .s_load(s_load),
        .s_store(s_store),
        .funct3(funct3),
        .addr(mem_addr),
        .pc(pc_in),
        .i_misalign(i_misalign),
        .l_misalign(l_misalign),
        .s_misalign(s_misalign)
    );

    wire [XLEN - 1:0] /* mepc, mcause, */ mtval, mstatus;
    reg [XLEN - 1:0] mepc_next, mcause_next, mtval_next, mstatus_next;

    assign s_exception = s_ebreak || s_ecall || l_misalign || s_misalign || i_misalign;
  
    always @(*) begin
        mepc_next = mepc;
        mcause_next = mcause;
        mtval_next = mtval;
        mstatus_next = mstatus;

        if (s_exception) begin
            mepc_next = pc_in;
            mstatus_next[`MPIE] = mstatus[`MIE];
            mstatus_next[`MIE] = 0;
            mcause_next = s_illegal ? 2 :
                    i_misalign ? 0 :
                    s_ecall ? 11 :
                    s_ebreak ? 3 :
                    s_misalign ? 6 :
                    l_misalign ? 4 : mcause;
            mtval_next = (s_misalign || l_misalign) ? mem_addr : 0;
        end else if (s_mret)
            mstatus_next[`MIE] = mstatus[`MPIE];
    end

    wire [XLEN - 1:0] data_w;
    csr_op #(
        .XLEN(XLEN)
    ) csr_op_inst (
        .funct3(funct3),
        .data_in(data_in),
        .data_out(data_out),
        .data_w(data_w)
    );

    csr_regs #(
        .XLEN(XLEN)
    ) csr_reg_inst (
        .clock(clock),
        .reset(reset),
        .s_csr(s_csr),
        .s_csrw(s_csrw),
        .addr(addr),
        .pc_in(pc_in),
        .data_w(data_w),
        .mepc_next(mepc_next),
        .mcause_next(mcause_next),
        .mtval_next(mtval_next),
        .mstatus_next(mstatus_next),
        .data_out(data_out),
        .mepc(mepc),
        .mcause(mcause),
        .mtval(mtval),
        .mstatus(mstatus),
        .mtvec(mtvec)
    );
endmodule

module csr_regs #(
	parameter XLEN = 32
)(
    input clock,
    input reset,
    input s_csr,
    input s_csrw,
    input [11:0] addr,
    input [XLEN - 1:0] pc_in,
    input [XLEN - 1:0] data_w,
    input [XLEN - 1:0] mepc_next, mcause_next, mtval_next, mstatus_next,
    output reg [XLEN - 1:0] data_out,
    output reg [XLEN - 1:0] mepc, mcause, mtval, mstatus, mtvec
);
    `include "csr_def.vh"

    // inner regs
    reg [XLEN - 1:0] mie, mip, mscratch;

    initial begin
        mtvec = 0;
        mepc = 0;
        mcause = 0;
        mie = 0;
        mip = 0;
        mtval = 0;
        mscratch = 0;
        mstatus = 0;        
    end

    always @(posedge clock) begin
        if (reset) begin
            mtvec <= 0;
            mepc <= 0;
            mcause <= 0;
            mie <= 0;
            mip <= 0;
            mtval <= 0;
            mscratch <= 0;
            mstatus <= 0;
        end else if (s_csrw) case (addr)
            MTVEC:      mtvec <= data_w;
            MEPC:       mepc <= data_w;
            MCAUSE:     mcause <= data_w;
            MIE:        mie <= data_w;
            MIP:        mip <=data_w;
            MTVAL:      mtval <= data_w;
            MSCRATCH:   mscratch <= data_w;
            MSTATUS:    mstatus <= data_w;
        endcase else begin
            mepc <= mepc_next;
            mcause <= mcause_next;
            mtval <= mtval_next;
            mstatus <= mstatus_next;            
        end

        if (s_csr) case (addr)
            MTVEC:      $display("csr: %x: %s MTVEC %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            MEPC:       $display("csr: %x: %s MEPC %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            MCAUSE:     $display("csr: %x: %s MCAUSE %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            MIE:        $display("csr: %x: %s MIE %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            MIP:        $display("csr: %x: %s MIP %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            MTVAL:      $display("csr: %x: %s MTVAL %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            MSCRATCH:   $display("csr: %x: %s MSCRATCH %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            MSTATUS:    $display("csr: %x: %s MSTATUS %x", pc_in, s_csrw ? "write" : "read", s_csrw ? data_w : data_out);
            default:    $display("error: %x: try to %s unknow address %x", pc_in, s_csrw ? "write" : "read", addr);
        endcase
    end

    always @(*) case (addr)
        MTVEC:      data_out = mtvec;
        MEPC:       data_out = mepc;
        MCAUSE:     data_out = mcause;
        MIE:        data_out = mie;
        MIP:        data_out = mip;
        MTVAL:      data_out = mtval;
        MSCRATCH:   data_out = mscratch;
        MSTATUS:    data_out = mstatus;
        default:    data_out = 0;
    endcase
endmodule

module csr_op #(
	parameter XLEN = 32
)(
	input [2:0] funct3,
    input [XLEN - 1:0] data_in,
    input [XLEN - 1:0] data_out,
    output reg [XLEN - 1:0] data_w
);
    always @(*) case (funct3)
    `CSRRW,
    `CSRRWI: data_w = data_in;
    `CSRRS,
    `CSRRSI: data_w = data_out | data_in;
    `CSRRC,
    `CSRRCI: data_w = data_out & ~data_in;
    default: data_w = data_out;
    endcase
endmodule

module misalign_detector #(
	parameter XLEN = 32
)(
	input s_load,
	input s_store,
	input [2:0] funct3,
    input [2:0] addr,
    input [1:0] pc,
    output i_misalign,
    output l_misalign,
    output s_misalign
);
    assign i_misalign = pc[1:0] != 0;

    wire mis_lh = (funct3 == `LH || funct3 == `LHU) && (addr[0] != 1'b0);
    wire mis_lw = (funct3 == `LW || funct3 == `LWU) && (addr[1:0] != 2'b00);
generate if (XLEN == 64) begin
    wire mis_ld = (funct3 == `LD) && (addr[2:0] != 3'b000);
    assign l_misalign = s_load && (mis_lh || mis_lw || mis_ld);
end else
    assign l_misalign = s_load && (mis_lh || mis_lw);
endgenerate

    wire mis_sh = (funct3 == `SH) && (addr[0] != 1'b0);
    wire mis_sw = (funct3 == `SW) && (addr[1:0] != 2'b00);
generate if (XLEN == 64) begin
    wire mis_sd = (funct3 == `SD) && (addr[2:0] != 3'b000);
    assign s_misalign = s_store && (mis_sh || mis_sw || mis_sd);
end else
    assign s_misalign = s_store && (mis_sh || mis_sw);
endgenerate

endmodule
