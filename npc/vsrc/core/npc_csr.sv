`include "npc_defines.svh"
module npc_csr import ctrl_pkg::*; (
  // System signals
  input   logic                       clk         ,
  input   logic                       rst_n       ,

  input   isa_pkg::word_t             pc_i        ,
  input   ctrl_pkg::csr_addr_e        csr_addr_i  ,
  input   isa_pkg::word_t             rs1_data_i  ,

  input   logic                       wr_en_i     ,
  input   ctrl_pkg::csr_op_e          csr_op_i    ,
  input   logic                       is_ecall_i  ,
  input   logic                       is_mret_i   ,

  output  isa_pkg::word_t             csr_data_o  ,
  output  isa_pkg::word_t             mepc_o      ,
  output  isa_pkg::word_t             mtvec_o
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // CSR
  isa_pkg::csr_file_t                 csr         ;

  isa_pkg::word_t                     csr_data    ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  assign  mepc_o    = csr.mepc                    ;
  assign  mtvec_o   = csr.mtvec                   ;

  // Read CSR
  always_comb begin
    unique case (csr_addr_i)
      MVENDORID: csr_data_o = 32'h79737978        ;   // ASCII: ysyx
      MARCHID:   csr_data_o = 32'd25110273        ;
      MSTATUS:   csr_data_o = csr.mstatus         ;
      MEPC   :   csr_data_o = csr.mepc            ;
      MCAUSE :   csr_data_o = csr.mcause          ;
      MTVEC  :   csr_data_o = csr.mtvec           ;
      default:   csr_data_o = `XLEN'd0            ;
    endcase
  end

  always_comb begin
    csr_data = 'd0                                ;
    unique case (csr_op_i)
      CSR_OP_W: csr_data = rs1_data_i             ;
      CSR_OP_S: csr_data = rs1_data_i | csr_data_o;
      default: csr_op_err: assert(0) else $fatal(1, "Unsupported CSR inst");
    endcase
  end

  // Write CSR
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      csr.mstatus <= '0          ;
      csr.mepc    <= '0          ;
      csr.mcause  <= '0          ;
      csr.mtvec   <= '0          ;
    end
    else if (is_ecall_i) begin
      csr.mepc    <= pc_i        ;
      csr.mcause  <= 'd11        ;   // ecall from M-mode
      csr.mstatus <= 'h1800      ;   // for difftest
    end
    else if (is_mret_i)
      csr.mstatus <= 'h80        ;   // for difftest
    else if (wr_en_i) begin
      unique case (csr_addr_i)
        MSTATUS: csr.mstatus <= csr_data  ;
        MEPC   : csr.mepc    <= csr_data  ;
        MCAUSE : csr.mcause  <= csr_data  ;
        MTVEC  : csr.mtvec   <= csr_data  ;
        default: csr_addr_wr_err: assert(csr_addr_i == MVENDORID || csr_addr_i == MARCHID)
                                  else $fatal(1, "Unsupported CSR access!");
      endcase
    end
  end

endmodule
