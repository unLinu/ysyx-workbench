`include "npc_defines.svh"
module npc_lsu import ctrl_pkg::*; (
  // System signals
  input   logic             clk           ,
  input   logic             rst_n         ,
  // mem access
  core_mem_if.master        m_mem_if      ,
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

  // handshake success
  logic                         req_done      ;
  logic                         rsp_done      ;

  // FSM state
  typedef enum logic [0:0] {
    LS_IDLE, LS_WAIT_RESP
  } ls_state_e;

  ls_state_e                    state         ;
  ls_state_e                    next_state    ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  ///////////////////////////////
  /* pipeline control and data */
  ///////////////////////////////
  assign tx_if.valid = rx_if.valid && ((state == LS_IDLE && ~m_mem_if.req_valid) || rsp_done);   // 不是访存指令或者访存指令已经拿到响应了
  assign rx_if.ready = tx_if.valid                                          ;

  assign  rx_data             = pipeline_pkg::ex2ls_data_t'(rx_if.data_pkg) ;   // unpacking
  assign  tx_if.data_pkg      = tx_data                                     ;   // packing

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

  /////////////////
  /* core_mem_if */
  /////////////////
  // Request Channel
  assign  req_done = m_mem_if.req_valid & m_mem_if.req_ready                ;
  assign  m_mem_if.req_addr  = rx_data.alu_res                              ;
  assign  m_mem_if.req_is_write = rx_data.mem_wr_en & rx_if.valid           ;
  assign  m_mem_if.req_valid = rx_if.valid &
                               (rx_data.mem_wr_en | rx_data.mem_rd_en)      ;

  always_comb begin
    m_mem_if.req_size = `AXI_SIZE_WORD;
    if (m_mem_if.req_is_write) begin
      unique case (rx_data.st_type)
        ST_TYPE_B: m_mem_if.req_size = `AXI_SIZE_BYTE;
        ST_TYPE_H: m_mem_if.req_size = `AXI_SIZE_HWORD;
        ST_TYPE_W: m_mem_if.req_size = `AXI_SIZE_WORD;
      endcase
    end
    else if (~m_mem_if.req_is_write) begin
      unique case (rx_data.ld_type)
        LD_TYPE_B, LD_TYPE_BU: m_mem_if.req_size = `AXI_SIZE_BYTE;
        LD_TYPE_H, LD_TYPE_HU: m_mem_if.req_size = `AXI_SIZE_HWORD;
        LD_TYPE_W: m_mem_if.req_size = `AXI_SIZE_WORD;
        default: req_size_ld_type_err: assert(0) else $fatal(1, "Invalid ld_type!");
      endcase
    end
  end

  always_comb begin
    m_mem_if.req_wstrb = '0;
    if (rx_data.mem_wr_en & rx_if.valid) begin
      unique case (rx_data.st_type)
        ST_TYPE_B: m_mem_if.req_wstrb = 4'b0001 << rx_data.alu_res[1:0]      ;
        ST_TYPE_H: m_mem_if.req_wstrb = 4'b0011 << {rx_data.alu_res[1], 1'b0};
        ST_TYPE_W: m_mem_if.req_wstrb = 4'b1111                              ;
      endcase
    end
  end

  always_comb begin
    m_mem_if.req_data = '0;
    unique case (rx_data.st_type)
      ST_TYPE_B: begin
        unique case (rx_data.alu_res[1:0])
          2'b00: m_mem_if.req_data = {24'd0, rx_data.rs2_data[7:0]       }  ;
          2'b01: m_mem_if.req_data = {16'd0, rx_data.rs2_data[7:0],  8'd0}  ;
          2'b10: m_mem_if.req_data = { 8'd0, rx_data.rs2_data[7:0], 16'd0}  ;
          2'b11: m_mem_if.req_data = {       rx_data.rs2_data[7:0], 24'd0}  ;
        endcase
      end
      ST_TYPE_H: begin
        unique case (rx_data.alu_res[1])
          1'b0: m_mem_if.req_data = {16'd0, rx_data.rs2_data[15:0]}          ;
          1'b1: m_mem_if.req_data = {rx_data.rs2_data[15:0], 16'd0}          ;
        endcase
      end
      ST_TYPE_W: m_mem_if.req_data = rx_data.rs2_data                         ;
    endcase
  end

  // Response Channel
  assign  rsp_done = m_mem_if.rsp_valid & m_mem_if.rsp_ready                 ;
  assign  m_mem_if.rsp_ready = (state == LS_WAIT_RESP)                       ;

  ///////////////////////////
  /* ----- FSM Start ----- */
  ///////////////////////////
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      state <= LS_IDLE    ;
    else
      state <= next_state ;
  end

  always_comb begin
    unique case (state)
      LS_IDLE     : next_state = req_done ? LS_WAIT_RESP : LS_IDLE       ;
      LS_WAIT_RESP: next_state = rsp_done ? LS_IDLE      : LS_WAIT_RESP  ;
      default     : next_state = LS_IDLE                                 ;
    endcase
  end

  //////////////
  /* Load Mux */
  //////////////
  always_comb begin
    mem_rdata = `XLEN'd0                                                              ;
    unique case (rx_data.ld_type)
      LD_TYPE_B: begin
        unique case (rx_data.alu_res[1:0])
          2'b00: mem_rdata = {{24{m_mem_if.rsp_data[7]}}, m_mem_if.rsp_data[7:0]}     ;
          2'b01: mem_rdata = {{24{m_mem_if.rsp_data[15]}}, m_mem_if.rsp_data[15:8]}   ;
          2'b10: mem_rdata = {{24{m_mem_if.rsp_data[23]}}, m_mem_if.rsp_data[23:16]}  ;
          2'b11: mem_rdata = {{24{m_mem_if.rsp_data[31]}}, m_mem_if.rsp_data[31:24]}  ;
        endcase
      end
      LD_TYPE_H: begin
        unique case (rx_data.alu_res[1])
          1'b0: mem_rdata = {{16{m_mem_if.rsp_data[15]}}, m_mem_if.rsp_data[15:0]}    ;
          1'b1: mem_rdata = {{16{m_mem_if.rsp_data[31]}}, m_mem_if.rsp_data[31:16]}   ;
        endcase
      end
      LD_TYPE_W:  mem_rdata = m_mem_if.rsp_data                                       ;
      LD_TYPE_BU: begin
        unique case (rx_data.alu_res[1:0])
          2'b00: mem_rdata = {24'd0, m_mem_if.rsp_data[7:0]}                          ;
          2'b01: mem_rdata = {24'd0, m_mem_if.rsp_data[15:8]}                         ;
          2'b10: mem_rdata = {24'd0, m_mem_if.rsp_data[23:16]}                        ;
          2'b11: mem_rdata = {24'd0, m_mem_if.rsp_data[31:24]}                        ;
        endcase
      end
      LD_TYPE_HU: begin
        unique case (rx_data.alu_res[1])
          1'b0: mem_rdata = {16'd0, m_mem_if.rsp_data[15:0]}                          ;
          1'b1: mem_rdata = {16'd0, m_mem_if.rsp_data[31:16]}                         ;
        endcase
      end
      default: ld_type_err: assert(0) else $fatal(1, "Invalid ld_type!")              ;
    endcase
  end

endmodule
