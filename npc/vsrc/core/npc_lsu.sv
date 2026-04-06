`include "npc_defines.svh"
module npc_lsu import ctrl_pkg::*; (
  // System signals
  input   logic             clk           ,
  input   logic             rst_n         ,
  // mem access
  mem_if.master             m_mem_if      ,
  // interface
  handshake_if.slave        rx_if         ,       // exu -> lsu
  handshake_if.master       tx_if                 // lsu -> wbu
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // interface
  pipeline_pkg::ex2ls_data_t    rx_data       ;
  pipeline_pkg::ls2wb_data_t    tx_data       ;

  // internal signals
  isa_pkg::word_t               mem_rdata     ;
  logic   [ 7:0]                mem_rlen      ;
  logic   [ 7:0]                mem_wlen      ;

  // FSM state
  typedef enum logic [0:0] {
    LS_IDLE, LS_GET
  } ls_state_e;

  ls_state_e                    state         ;
  ls_state_e                    next_state    ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  // handshake
  assign tx_if.valid = rx_if.valid &&
    ((state == LS_IDLE && ~rx_data.mem_rd_en) || (state == LS_GET))         ;   // 不是访存指令或者访存指令已经拿到数据了
  assign rx_if.ready = state == LS_IDLE ? ~rx_data.mem_rd_en : 1'b1         ;

  assign  rx_data             = pipeline_pkg::ex2ls_data_t'(rx_if.data_pkg) ;   // unpacking
  assign  tx_if.data_pkg      = tx_data                                     ;   // packing

  // --------------------------- tx drive begin ---------------------------
  assign  tx_data = '{
    // PC reg
    pc                        : rx_data.pc                                  ,
    // Debug
    inst                      : rx_data.inst                                ,
    // Write back
    rf_wb_en                  : rx_data.rf_wb_en                            ,
    rd                        : rx_data.rd                                  ,
    wb_sel                    : rx_data.wb_sel                              ,
    // Execution result
    alu_res                   : rx_data.alu_res                             ,
    // Exception
    ebreak_flag               : rx_data.ebreak_flag                         ,
    ecall_flag                : rx_data.ecall_flag                          ,
    mret_flag                 : rx_data.mret_flag                           ,
    csr_wb_en                 : rx_data.csr_wb_en                           ,
    csr_addr                  : rx_data.csr_addr                            ,
    csr_op                    : rx_data.csr_op                              ,
    mem_rdata                 : mem_rdata                                   ,

    default                   : '0
  };
  // --------------------------- tx drive end -----------------------------

  // --------------------------- mem master drive -------------------------
  assign  m_mem_if.addr       = rx_data.alu_res                                     ;
  assign  m_mem_if.rd_en      = rx_data.mem_rd_en & rx_if.valid & (state != LS_GET) ;
  assign  m_mem_if.wr_en      = rx_data.mem_wr_en & rx_if.valid                     ;
  assign  m_mem_if.wr_data    = rx_data.rs2_data                                    ;
  assign  m_mem_if.rlen       = mem_rlen                                            ;
  assign  m_mem_if.wlen       = mem_wlen                                            ;
  // --------------------------- mem master end ----------------------------

  /* ----- FSM Start ----- */
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      state <= LS_IDLE    ;
    else
      state <= next_state ;
  end

  always_comb begin
    unique case (state)
      LS_IDLE: next_state = rx_data.mem_rd_en & rx_if.valid ? LS_GET : LS_IDLE      ;
      LS_GET : next_state = LS_IDLE                                                 ;
      default: next_state = LS_IDLE                                                 ;
    endcase
  end
  /* ----- FSM End ------- */

  /* Load Mux */
  always_comb begin
    mem_rdata = `XLEN'd0                                                            ;
    unique case (rx_data.ld_type)
      LD_TYPE_B:  mem_rdata = {{24{m_mem_if.rd_data[7]}}, m_mem_if.rd_data[7:0]}    ;
      LD_TYPE_H:  mem_rdata = {{16{m_mem_if.rd_data[15]}}, m_mem_if.rd_data[15:0]}  ;
      LD_TYPE_W:  mem_rdata = m_mem_if.rd_data                                      ;
      LD_TYPE_BU: mem_rdata = {24'd0, m_mem_if.rd_data[7:0]}                        ;
      LD_TYPE_HU: mem_rdata = {16'd0, m_mem_if.rd_data[15:0]}                       ;
      default: ld_type_err: assert(0) else $fatal(1, "Invalid ld_type!")            ;
    endcase
  end

  always_comb begin
    mem_rlen = 8'd0                                                         ;
    unique case (rx_data.ld_type)
      LD_TYPE_B, LD_TYPE_BU: mem_rlen = 8'd1                                ;
      LD_TYPE_H, LD_TYPE_HU: mem_rlen = 8'd2                                ;
      LD_TYPE_W            : mem_rlen = 8'd4                                ;
    endcase
  end

  /* Store Mux */
  always_comb begin
    mem_wlen = 8'd0                                                         ;
    unique case (rx_data.st_type)
      ST_TYPE_B: mem_wlen = 8'd1                                            ;
      ST_TYPE_H: mem_wlen = 8'd2                                            ;
      ST_TYPE_W: mem_wlen = 8'd4                                            ;
      default: st_type_err: assert(0) else $fatal("Invalid st_type!")       ;
    endcase
  end

endmodule
