`include "npc_defines.svh"
module csr import npc_pkg::*; (
    input   logic                       clk         ,
    input   logic                       rst_n       ,
    
    input   npc_pkg::word_t             pc_i        ,
    input   npc_pkg::csr_addr_t         csr_addr_i  ,
    input   npc_pkg::word_t             rs1_data_i  ,

    input   logic                       wr_en_i     ,
    input   npc_pkg::csr_op_t           csr_op_i    ,
    
    input   logic                       ecall_i     ,
    input   logic                       mret_i      ,

    output  npc_pkg::word_t             csr_data_o  ,
    output  npc_pkg::word_t             mepc_o      ,
    output  npc_pkg::word_t             mtvec_o     
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

    npc_pkg::word_t                     mstatus  /* verilator public */ ;
    npc_pkg::word_t                     mepc     /* verilator public */ ;
    npc_pkg::word_t                     mcause   /* verilator public */ ;
    npc_pkg::word_t                     mtvec    /* verilator public */ ;
    
    npc_pkg::word_t                     csr_data    ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

    assign mepc_o   = mepc  ;
    assign mtvec_o  = mtvec ;

    // Read CSR
    always_comb begin
        unique case (csr_addr_i)
            MSTATUS: csr_data_o = mstatus   ;
            MEPC:    csr_data_o = mepc      ;
            MCAUSE:  csr_data_o = mcause    ;
            MTVEC:   csr_data_o = mtvec     ;
            default: csr_data_o = `XLEN'd0  ;
        endcase
    end
    
    always_comb begin
        unique case (csr_op_i)
            CSR_W:   csr_data = rs1_data_i                  ;
            CSR_S:   csr_data = rs1_data_i | csr_data_o     ;
            default: csr_data = `XLEN'd0                    ;
        endcase
    end

    // Write CSR
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            mstatus <= `XLEN'd0;
            mepc    <= `XLEN'd0;
            mcause  <= `XLEN'd0;
            mtvec   <= `XLEN'd0;
        end
        else if (ecall_i) begin
            mepc <= pc_i;
            mcause <= `XLEN'd11;        // ecall from M-mode
            mstatus <= `XLEN'h1800;     // for difftest
        end
        else if (mret_i) begin
            mstatus <= `XLEN'h80  ;     // for difftest
        end
        else if (wr_en_i) begin
            unique case (csr_addr_i)
                MSTATUS: mstatus <= csr_data   ;
                MEPC:    mepc    <= csr_data   ;
                MCAUSE:  mcause  <= csr_data   ;
                MTVEC:   mtvec   <= csr_data   ;
                default:                       ;
            endcase
        end
    end
 
endmodule
