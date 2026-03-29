`include "npc_defines.svh"
module npc_wbu import ctrl_pkg::*; #(
  parameter string ARCH = "SINGLE"
)(
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

  // handshake
  generate
    if (ARCH == "SINGLE") begin: g_single_arch
      assign rx_if.ready  = 1'b1              ;
    end
  endgenerate

  // interface
  pipeline_pkg::ls2wb_data_t    rx_data       ;

  // internal signals
  isa_pkg::word_t               pc            ;
  ctrl_pkg::wb_sel_e            wb_sel        ;
  isa_pkg::word_t               alu_res       ;
  isa_pkg::word_t               mem_rdata     ;
  ctrl_pkg::csr_op_e            csr_op        ;
  logic   [11:0]                csr_addr      ;
  logic                         ebreak_flag   ;
  logic                         ecall_flag    ;
  logic                         mret_flag     ;
  logic                         csr_wb_en     ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  assign  rx_data             = pipeline_pkg::ls2wb_data_t'(rx_if.data_pkg) ;   // unpacking

  // --------------------------- rx signals begin -------------------------
  assign  pc                  = rx_data.pc                                  ;
  assign  alu_res             = rx_data.alu_res                             ;
  assign  mem_rdata           = rx_data.mem_rdata                           ;
  assign  ebreak_flag         = rx_data.ebreak_flag                         ;
  assign  ecall_flag          = rx_data.ecall_flag                          ;
  assign  mret_flag           = rx_data.mret_flag                           ;
  assign  csr_addr            = rx_data.csr_addr                            ;
  assign  csr_op              = rx_data.csr_op                              ;
  assign  wb_sel              = rx_data.wb_sel                              ;
  assign  csr_wb_en           = rx_data.csr_wb_en                           ;
  // --------------------------- rx signals end ---------------------------

  // Write back
  assign  rf_wb_en_o          = rx_data.rf_wb_en                            ;
  assign  rd_o                = rx_data.rd                                  ;

  // Trap
  assign  csr_addr_o          = csr_addr                                    ;
  assign  csr_wdata_o         = alu_res                                     ;   // rs1_data
  assign  ebreak_flag_o       = ebreak_flag                                 ;

  assign  wb_trap_valid_o     = ecall_flag                                  ;
  assign  wb_mret_valid_o     = mret_flag                                   ;
  assign  csr_op_o            = csr_op                                      ;
  assign  csr_wb_en_o         = csr_wb_en                                   ;

  assign  wb_pc_o             = pc                                          ;

  /* Write Back Mux */
  always_comb begin
    rd_data_o = `XLEN'd0                                                    ;
    unique case (wb_sel)
      WB_SEL_ALU: rd_data_o = alu_res                                       ;
      WB_SEL_MEM: rd_data_o = mem_rdata                                     ;
      WB_SEL_IFU: rd_data_o = pc + `XLEN'd4                                 ;
      WB_SEL_CSR: rd_data_o = csr_rdata_i                                   ;
      default: wb_sel_err: assert(0) else $fatal(1, "Invalid wb_sel!")      ;
    endcase
  end

endmodule
