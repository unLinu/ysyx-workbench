`include "npc_defines.svh"
module axi4_master (
  // interface
  core_mem_if.slave               s_bus_if      ,
  axi4_if.master                  m_axi_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // FSM state definition
  typedef enum logic [1:0] {
    R_IDLE, R_SEND_REQ, R_WAIT_RESP
  } r_state_e ;

  typedef enum logic [1:0] {
    W_IDLE, W_SEND_REQ, W_WAIT_RESP
  } w_state_e ;

  r_state_e     r_state, r_next_state ;
  w_state_e     w_state, w_next_state ;

  // slave bus
  logic         bus_req_done, bus_rsp_done            ;
  logic         w_req_done, r_req_done                ;
  logic         w_rsp_done, r_rsp_done                ;
  // global transaction
  logic         txn_busy                              ;
  logic         txn_is_write_q                        ;
  // AXI transaction
  logic         ar_done                               ;
  logic         r_done                                ;
  logic         aw_done                               ;
  logic         aw_get_q                              ;
  logic         w_done                                ;
  logic         w_get_q                               ;
  logic         aw_w_all_done                         ;
  logic         b_done                                ;
  // dispatch response channel
  logic [$bits(s_bus_if.rsp_data)-1 :0]   r_rsp_data                ;
  logic [$bits(s_bus_if.rsp_err)-1  :0]   r_rsp_err, w_rsp_err      ;
  logic [$bits(s_bus_if.rsp_valid)-1:0]   r_rsp_valid, w_rsp_valid  ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  /////////////////
  /* core_mem_if */
  /////////////////
  // Request Channel
  assign  bus_req_done = s_bus_if.req_valid & s_bus_if.req_ready;
  assign  w_req_done = bus_req_done && s_bus_if.req_is_write;
  assign  r_req_done = bus_req_done && ~s_bus_if.req_is_write;
  assign  s_bus_if.req_ready = ~txn_busy;
  // Response Channel
  assign  bus_rsp_done = s_bus_if.rsp_valid & s_bus_if.rsp_ready;
  assign  w_rsp_done = bus_rsp_done && txn_is_write_q;
  assign  r_rsp_done = bus_rsp_done && ~txn_is_write_q;
  assign  s_bus_if.rsp_data = txn_is_write_q ? '0 : r_rsp_data;
  assign  s_bus_if.rsp_err = txn_is_write_q ? w_rsp_err : r_rsp_err;
  assign  s_bus_if.rsp_valid = txn_is_write_q ? w_rsp_valid : r_rsp_valid;

  // global transaction status
  assign  txn_busy = (r_state != R_IDLE) || (w_state != W_IDLE) || s_bus_if.rsp_valid;
  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn)
      txn_is_write_q <= 1'b0;
    else if (bus_req_done)
      txn_is_write_q <= s_bus_if.req_is_write;
    else if (bus_rsp_done)
      txn_is_write_q <= 1'b0;
  end

  //////////////////
  /* State Update */
  //////////////////
  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn) begin
      r_state <= R_IDLE;
      w_state <= W_IDLE;
    end
    else begin
      r_state <= r_next_state;
      w_state <= w_next_state;
    end
  end

  //////////////////
  /* State Switch */
  //////////////////
  always_comb begin
    unique case (r_state)
      R_IDLE     : r_next_state = r_req_done ? R_SEND_REQ : R_IDLE;
      R_SEND_REQ : r_next_state = ar_done ? R_WAIT_RESP : R_SEND_REQ;
      R_WAIT_RESP: r_next_state = r_rsp_done ? R_IDLE : R_WAIT_RESP;
    endcase
  end

  always_comb begin
    unique case (w_state)
      W_IDLE     : w_next_state = w_req_done ? W_SEND_REQ : W_IDLE;
      W_SEND_REQ : w_next_state = aw_w_all_done ? W_WAIT_RESP : W_SEND_REQ;
      W_WAIT_RESP: w_next_state = w_rsp_done ? W_IDLE : W_WAIT_RESP;
    endcase
  end

  ///////////////////////////
  /* Write Address Channel */
  ///////////////////////////
  assign  aw_done = m_axi_if.awvalid & m_axi_if.awready ;
  assign  aw_w_all_done = (aw_done && w_done) || (aw_get_q && w_get_q) || (aw_done && w_get_q) || (aw_get_q && w_done);

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn)
      aw_get_q <= 1'b0;
    else if (aw_w_all_done)
      aw_get_q <= 1'b0;
    else if (aw_done)
      aw_get_q <= 1'b1;
  end

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn) begin
      m_axi_if.awaddr  <= '0;
      m_axi_if.awprot  <= '0;
      m_axi_if.awid    <= '0;
      m_axi_if.awlen   <= '0;
      m_axi_if.awsize  <= '0;
      m_axi_if.awburst <= '0;
      m_axi_if.awvalid <= 1'b0;
    end
    else if (w_req_done) begin
      m_axi_if.awaddr  <= s_bus_if.req_addr;
      m_axi_if.awprot  <= 3'b000;             // normal, secure, inst
      m_axi_if.awid    <= '0;                 // not used
      m_axi_if.awlen   <= '0;                 // single beat
      m_axi_if.awsize  <= s_bus_if.req_size;
      m_axi_if.awburst <= `AXI_BURST_INCR;    // fixed burst
      m_axi_if.awvalid <= 1'b1;
    end
    else if (aw_done) begin
      m_axi_if.awvalid <= 1'b0;
    end
  end


  ////////////////////////
  /* Write Data Channel */
  ////////////////////////
  assign  w_done = m_axi_if.wvalid & m_axi_if.wready ;

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn)
      w_get_q <= 1'b0;
    else if (aw_w_all_done)
      w_get_q <= 1'b0;
    else if (w_done)
      w_get_q <= 1'b1;
  end

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn) begin
      m_axi_if.wdata  <= '0;
      m_axi_if.wstrb  <= '0;
      m_axi_if.wlast  <= 1'b0;
      m_axi_if.wvalid <= 1'b0;
    end
    else if (w_req_done) begin
      m_axi_if.wdata  <= s_bus_if.req_data;
      m_axi_if.wstrb  <= s_bus_if.req_wstrb;
      m_axi_if.wlast  <= 1'b1;                // only one beat
      m_axi_if.wvalid <= 1'b1;
    end
    else if (w_done) begin
      m_axi_if.wvalid <= 1'b0;
    end
  end

  ////////////////////////////
  /* Write Response Channel */
  ////////////////////////////
  assign  b_done = m_axi_if.bvalid & m_axi_if.bready ;
  assign  m_axi_if.bready = (w_state == W_WAIT_RESP) ;

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn) begin
      w_rsp_err   <= '0;
      w_rsp_valid <= 1'b0;
    end
    else if (b_done) begin
      w_rsp_err   <= (m_axi_if.bresp != 2'b00);   // OKAY is 00, other values indicate error
      w_rsp_valid <= 1'b1;
    end
    else if (w_rsp_done) begin
      w_rsp_valid <= 1'b0;
    end
  end

  //////////////////////////
  /* Read Address Channel */
  //////////////////////////
  assign  ar_done = m_axi_if.arvalid & m_axi_if.arready ;

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn) begin
      m_axi_if.araddr  <= '0;
      m_axi_if.arprot  <= '0;
      m_axi_if.arid    <= '0;
      m_axi_if.arlen   <= '0;
      m_axi_if.arsize  <= '0;
      m_axi_if.arburst <= '0;
      m_axi_if.arvalid <= 1'b0;
    end
    else if (r_req_done) begin
      m_axi_if.araddr  <= s_bus_if.req_addr;
      m_axi_if.arprot  <= 3'b100;               // normal, secure, inst
      m_axi_if.arid    <= '0;                   // not used
      m_axi_if.arlen   <= '0;                   // single beat
      m_axi_if.arsize  <= s_bus_if.req_size;
      m_axi_if.arburst <= `AXI_BURST_INCR;
      m_axi_if.arvalid <= 1'b1;
    end
    else if (ar_done) begin
      m_axi_if.arvalid <= 1'b0;
    end
  end

  ///////////////////////
  /* Read Data Channel */
  ///////////////////////
  assign  r_done  = m_axi_if.rvalid  & m_axi_if.rready  ;
  assign  m_axi_if.rready = (r_state == R_WAIT_RESP)    ;

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn) begin
      r_rsp_data  <= '0;
      r_rsp_err   <= '0;
      r_rsp_valid <= 1'b0;
    end
    else if (r_done) begin
      r_rsp_data  <= m_axi_if.rdata;
      r_rsp_err   <= (m_axi_if.rresp != 2'b00);   // OKAY is 00, other values indicate error
      r_rsp_valid <= 1'b1;
    end
    else if (r_rsp_done) begin
      r_rsp_valid <= 1'b0;
    end
  end

endmodule
