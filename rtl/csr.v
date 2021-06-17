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
    input s_illegal,
	input s_load,
	input s_store,
	input [2:0] funct3,
	input [11:0] addr,
    input [XLEN - 1:0] mem_addr,
    input [XLEN - 1:0] pc_in,
    input [XLEN - 1:0] data_in,
    output s_exception,
    output [XLEN - 1:0] pc_out,
	output reg [XLEN - 1:0] data_out
);
    // User Trap Setup
    localparam USTATUS = 12'h000;   // user status register
    localparam UIE = 12'h004;       // user interrupt-enable regitser
    localparam UTVEC = 12'h005;     // user trap handler base address

    // User Trap Handling
    localparam USCRATCH = 12'h040;  // scratch register for user trap handlers
    localparam UEPC = 12'h041;      // user exception program counter
    localparam UCAUSE = 12'h042;    // uesr trap cuase
    localparam UTVAL = 12'h043;     // user bad address or instruction
    localparam UIP = 12'h044;       // user interrupt pending

    // User Fload-Point CSRs
    localparam FFLAGS = 12'h001;    // float-point accrued exceptions
    localparam FRM = 12'h002;       // float-point dynamic rounding mode
    localparam FCSR = 12'h003;      // float-point control and status registers

    // User Counter/Timers
    localparam CYCLE = 12'hC00;     // cycle counter for RDCYCLE instruction
    localparam TIME = 12'hC01;      // time for RDTIME instruction
    localparam INSTRET = 12'hC02;   // instruction-retired counter for RDINSTRET instruction
    localparam HPMCOUNTER = 12'b1100_000x_xxxx;
generate if (XLEN == 32) begin
    localparam CYCLEH = 12'hC80;
    localparam TIMEH = 12'hC81;
    localparam INSTRETH = 12'hC82;
    localparam HPMCOUNTERH = 12'b1100_100x_xxxx;   
end endgenerate

    // Supervisor Trap Setup
    localparam SSTATUS = 12'h100;   // supervisor status register
    localparam SEDELGE = 12'h102;   // supervisor exception delegation register
    localparam SIDELGE = 12'h103;   // supervisor interrupt delegation register
    localparam SIE = 12'h104;       // supervisor interrupt-enable register
    localparam STVEC = 12'h105;     // supervisor trap handler base register
    localparam SCOUNTEREN = 12'h106;// supervisor counter enable

    // Supervisor Trap Handling
    localparam SSCRATCH = 12'h140;  // scratch register for supervisor trap handlers
    localparam SEPC = 12'h141;      // supervisor exception program counter
    localparam SCAUSE = 12'h142;    // supervisor trap cause
    localparam STVAL = 12'h143;     // supervisor bad address or instruction
    localparam SIP = 12'h144;       // supervisor interrupt pending

    // Supervisor Protection and Translation
    localparam SATP = 12'h180;      // supervisor address translation and protection

    // Debug/Trace Registers
    localparam SCONTEXT = 12'h5A8;  // supervisor-mode context register

    // Hypervisor Trap Setup
    localparam HSTATUS = 12'h600;   // hypervisor status register
    localparam HEDELEG = 12'h602;   // hypervisor exception delegation register
    localparam HIDELEG = 12'h603;   // hypervisor interrupt delegation register
    localparam HIE = 12'h604;       // hypervisor interrupt-enable register
    localparam HCOUNTEREN = 12'h606;// hypervisor counter enable
    localparam HGEIE = 12'h607;     // hypervisor guest external intterupt-enable register

    // Hypervisor Trap Handling
    localparam HTVAL = 12'h643;     // hypervisor bad guest physical address
    localparam HIP = 12'h644;       // hypervisor interrupt pending
    localparam HVIP = 12'h645;      // hypervisor virtual interrupt pending
    localparam HTINST = 12'h64A;    // hypervisor trap instruction (transformed)
    localparam HGEIP = 12'hE12;     // hypervisor guest external interrupt pending

    // Hypervisor Protection and Translation
    localparam HGATP = 12'h680;     // hypervisor guest address translation and protection

    // Debug/Trace Registers
    localparam HCONTEXT = 12'h6A8;  // hypervisor-mode context register

    // Hypervisor Counter/Timer Virtualization Registers
    localparam HTIMEDELTA = 12'h605;// delta for VS/VU-mode timer
generate if (XLEN == 32)
    localparam HTIMEDELTAH = 12'h615;
endgenerate

    // Virtual Supervisor Registers
    localparam VSSTATUS = 12'h200;  // virtual supervisor status register
    localparam VSIE = 12'h204;      // virtual supervisor interrupt-enable register
    localparam VSTVEC = 12'h205;    // virtual supervisor trap handler base address
    localparam VSSCRACTCH = 12'h240;// virtual supervisor scratch register
    localparam VSEPC = 12'h241;     // virtual supervisor exception program counter
    localparam VSCAUSE = 12'h242;   // virtual supervisor trap cause
    localparam VSTVAL = 12'h243;    // virtual supervisor bad address or instruction
    localparam VSIP = 12'h244;      // virtual supervisor interrupt pending
    localparam VSATP = 12'h280;     // virtual supervisor address translation and protection

    // Machine Information Registers
    localparam MVENDORID = 12'hF11; // vendor id
    localparam MARCHID = 12'hF12;   // architecture id
    localparam MIMPID = 12'hF13;    // implementation id
    localparam MHARTID = 12'hF14;   // hardware thread id

    // Machine Trap Setup
    localparam MSTATUS = 12'h300;   // machine status register
    localparam MISA = 12'h301;      // isa and extensions
    localparam MEDELEG = 12'h302;   // machine exception delegation register
    localparam MIDELEG = 12'h303;   // machine interrupt delegation register
    localparam MIE = 12'h304;       // machine interrupt-enable register
    localparam MTVEC = 12'h305;     // machine trap-handler base address
    localparam MCOUNTEREN = 12'h306;// machine counter enable
generate if (XLEN == 32)
    localparam MSTATUSH = 12'h310;
endgenerate

    // Machine Trap Handling
    localparam MSCRATCH = 12'h340;  // scratch register for machine trap handlers
    localparam MEPC = 12'h341;      // machine exception program counter
    localparam MCAUSE = 12'h342;    // machine trap cause
    localparam MTVAL = 12'h343;     // machine bad address or instruction
    localparam MIP = 12'h344;       // machine interrupt pending
    localparam MTINST = 12'h34A;    // machine trap instruction (transformed)
    localparam MTVAL2 = 12'h34B;    // machine bad guest physical address

    // Machine Memory Protection
    localparam PMPCFG = 12'b0011_1010_xxx0;
generate if (XLEN == 32)
    localparam PMPCFGH = 12'b0011_1010_xxx1;
endgenerate
    localparam PMPADDR0 = 12'h3B0;
    localparam PMPADDR63 = 12'h3EF;

    // Machine Counter/Timers
    localparam MCYCLE = 12'hB00;    // machine cycle counter
    localparam MINSTRET = 12'hB02;  // machine instructions-retired counter
    localparam MHPMCOUNTER = 12'b1011_000x_xxxx;
generate if (XLEN == 32) begin
    localparam MCYCLEH = 12'hB80;
    localparam MINSTRETH = 12'hB82;
    localparam MHPMCOUNTERH = 12'b1011_100x_xxxx;   
end endgenerate    

    // Machine Counter Setup
    localparam MCOUNTINHIBIT = 12'h320; // machine counter-inhibit register
    localparam MHPMEVENT = 12'b0011_001x_xxxx; // machine performance-monitoring event selector

    // Debug/Trace Registers
    localparam TSELECT = 12'h7A0;   // debug/trace trigger register select
    localparam TDATA1 = 12'h7A1;    // first debug/trace trigger data register
    localparam TDATA2 = 12'h7A2;    // second debug/trace trigger data register
    localparam TDATA3 = 12'h7A3;    // third debug/trace trigger data register
    localparam MCONTEXT = 12'h7A8;  // machine-mode context register

    // Debug Mode Registers
    localparam DCSR = 12'h7B0;      // debug control and status register
    localparam DPC = 12'h7B1;       // debug pc
    localparam DSCRATCH0 = 12'h7B2; // debug scratch register 0
    localparam DSCRATCH1 = 12'h7B3; // debug sctatch register 1

    localparam READONLY = 2'b11;
    localparam USER = 2'b00;
    localparam SUPERVISOR = 2'b01;
    localparam HYPERVISOR = 2'b10;
    localparam MACHINE = 2'b11;

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

    assign pc_out = mtvec;
    assign s_exception = s_ebreak || s_ecall || l_misalign || s_misalign || i_misalign;

    reg [XLEN - 1:0] mtvec, mepc, mcause, mie, mip, mtval, mscratch, mstatus;

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

    wire [XLEN - 1:0] data_w;
    csr_op #(
        .XLEN(XLEN)
    ) csr_op_inst (
        .funct3(funct3),
        .data_in(data_in),
        .data_out(data_out),
        .data_w(data_w)
    );

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
        end else if (s_exception) begin
            mepc <= pc_in;
            mstatus[`MPIE] <= mstatus[`MIE];
            mstatus[`MIE] <= 0;
            mcause <= s_illegal ? 2 :
                    i_misalign ? 0 :
                    s_ecall ? 11 :
                    s_ebreak ? 3 :
                    s_misalign ? 6 :
                    l_misalign ? 4 : mcause;
            mtval <= (s_misalign || l_misalign) ? mem_addr : 0;
        end else if (s_csrw) case (addr)
            MTVEC:      mtvec <= data_w;
            MEPC:       mepc <= data_w;
            MCAUSE:     mcause <= data_w;
            MIE:        mie <= data_w;
            MIP:        mip <=data_w;
            MTVAL:      mtval <= data_w;
            MSCRATCH:   mscratch <= data_w;
            MSTATUS:    mstatus <= data_w;
        endcase

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
