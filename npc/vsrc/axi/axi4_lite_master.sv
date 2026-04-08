module axi4_lite_master (
  // interface
  ifetch_bus_if.slave             s_bus_if      ,
  axi4_lite_if.master             m_axi_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // FSM state definition
  typedef enum logic [1:0] {
    R_IDLE, R_SEND_REQ, R_WAIT_RESP
  } r_state_e ;

  r_state_e     r_state, r_next_state ;

  // handshake success
  logic         s_req_done            ;
  logic         s_rsp_done            ;
  logic         ar_done               ;
  logic         r_done                ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  assign  s_bus_if.req_ready = (r_state == R_IDLE);
  assign  s_req_done = s_bus_if.req_valid & s_bus_if.req_ready;
  assign  s_rsp_done = s_bus_if.rsp_valid & s_bus_if.rsp_ready;

  //////////////////
  /* State Update */
  //////////////////
  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn)
      r_state <= R_IDLE;
    else
      r_state <= r_next_state;
  end

  //////////////////
  /* State Switch */
  //////////////////
  always_comb begin
    unique case (r_state)
      R_IDLE     : r_next_state = s_req_done ? R_SEND_REQ : R_IDLE;
      R_SEND_REQ : r_next_state = ar_done ? R_WAIT_RESP : R_SEND_REQ;
      R_WAIT_RESP: r_next_state = r_done ? R_IDLE : R_WAIT_RESP;
    endcase
  end

  ///////////////////////////
  /* Write Address Channel */
  ///////////////////////////
  assign  m_axi_if.awaddr = '0;
  assign  m_axi_if.awprot = '0;
  assign  m_axi_if.awvalid = 1'b0;


  ////////////////////////
  /* Write Data Channel */
  ////////////////////////
  assign  m_axi_if.wdata = '0;
  assign  m_axi_if.wstrb = '0;
  assign  m_axi_if.wvalid = 1'b0;

  ////////////////////////////
  /* Write Response Channel */
  ////////////////////////////
  assign  m_axi_if.bready = 1'b0;

  //////////////////////////
  /* Read Address Channel */
  //////////////////////////
  assign  ar_done = m_axi_if.arvalid & m_axi_if.arready ;

  always_ff @(posedge m_axi_if.aclk or negedge m_axi_if.aresetn) begin
    if (~m_axi_if.aresetn) begin
      m_axi_if.araddr  <= '0;
      m_axi_if.arprot  <= '0;
      m_axi_if.arvalid <= 1'b0;
    end
    else if (s_req_done) begin
      m_axi_if.araddr  <= s_bus_if.req_addr;
      m_axi_if.arprot  <= 3'b100;   // normal, secure, inst
      m_axi_if.arvalid <= 1'b1;
    end
    else if (ar_done) begin
      m_axi_if.arprot  <= '0;
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
      s_bus_if.rsp_data  <= '0;
      s_bus_if.rsp_error <= '0;
      s_bus_if.rsp_valid <= 1'b0;
    end
    else if (r_done) begin
      s_bus_if.rsp_data  <= m_axi_if.rdata;
      s_bus_if.rsp_error <= (m_axi_if.rresp != 2'b00);   // OKAY is 00, other values indicate error
      s_bus_if.rsp_valid <= 1'b1;
    end
    else if (s_rsp_done) begin
      s_bus_if.rsp_error <= '0;
      s_bus_if.rsp_valid <= 1'b0;
    end
  end

endmodule
