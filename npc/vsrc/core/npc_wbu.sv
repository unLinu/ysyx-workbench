`include "npc_defines.svh"
module npc_wbu import ctrl_pkg::*; (
  // System signals
  input   logic                   clk                 ,
  input   logic                   rst_n               ,
  // forward path to regfile
  output  logic                   rf_wb_en_o          ,
  output  isa_pkg::regid_t        rd_o                ,
  output  isa_pkg::word_t         rd_data_o           ,
  // path between csr and wbu (submit)
  input   isa_pkg::word_t         csr_rdata_i         ,
  output  logic   [11:0]          csr_addr_o          ,
  output  isa_pkg::word_t         csr_wdata_o         ,
  output  ctrl_pkg::csr_op_e      csr_op_o            ,
  logic                           csr_wb_en_o         ,
  // throw exceptions
  output  logic                   ebreak_flag_o       ,
  output  logic                   wb_trap_valid_o     ,       // ecall
  output  logic                   wb_mret_valid_o     ,       // mret
  output  isa_pkg::word_t         wb_pc_o             ,
  // interface
  handshake_if.slave              rx_if                       // lsu -> wbu
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // interface
  pipeline_pkg::ls2wb_data_t    rx_data       ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  // handshake
  assign  rx_if.ready         = 1'b1                                        ;
  assign  rx_data             = pipeline_pkg::ls2wb_data_t'(rx_if.data_pkg) ;   // unpacking

  // Write back
  assign  rf_wb_en_o          = rx_data.rf_wb_en & rx_if.valid              ;
  assign  rd_o                = rx_data.rd                                  ;

  // Trap
  assign  csr_addr_o          = rx_data.csr_addr                            ;
  assign  csr_wdata_o         = rx_data.alu_res                             ;   // rs1_data
  assign  ebreak_flag_o       = rx_data.ebreak_flag & rx_if.valid           ;

  assign  wb_trap_valid_o     = rx_data.ecall_flag & rx_if.valid            ;
  assign  wb_mret_valid_o     = rx_data.mret_flag & rx_if.valid             ;
  assign  csr_op_o            = rx_data.csr_op                              ;
  assign  csr_wb_en_o         = rx_data.csr_wb_en & rx_if.valid             ;

  assign  wb_pc_o             = rx_data.pc                                  ;

  /* Write Back Mux */
  always_comb begin
    rd_data_o = `XLEN'd0                                                    ;
    unique case (rx_data.wb_sel)
      WB_SEL_ALU: rd_data_o = rx_data.alu_res                               ;
      WB_SEL_MEM: rd_data_o = rx_data.mem_rdata                             ;
      WB_SEL_IFU: rd_data_o = rx_data.pc + `XLEN'd4                         ;
      WB_SEL_CSR: rd_data_o = csr_rdata_i                                   ;
      default: wb_sel_err: assert(0) else $fatal(1, "Invalid wb_sel!")      ;
    endcase
  end

  // DPI-C read
  /* verilator lint_off UNUSED */
  logic  commit_valid_o;
  /* verilator lint_on UNUSED */
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      commit_valid_o <= 1'b0;
    else if (rx_if.valid)
      commit_valid_o <= 1'b1;
    else
      commit_valid_o <= 1'b0;
  end

endmodule
