module axi4_arbiter (
  // interface
  axi4_if.slave              s0_axi_if       ,
  axi4_if.slave              s1_axi_if       ,
  axi4_if.master             m_axi_if
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // FSM state definition
  typedef enum logic [1:0] {
    IDLE, I0_GRANT, I1_GRANT
  } arb_state_e ;

  // Internal signals
  logic           txn_is_write_q    ;
  logic           txn_done          ;
  logic           s0_req, s1_req    ;

  arb_state_e     state, next_state ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  //////////////////////
  /* FSM State Update */
  //////////////////////
  always_ff @(posedge s0_axi_if.aclk or negedge s0_axi_if.aresetn) begin
    if (~s0_axi_if.aresetn)
      state <= IDLE;
    else
      state <= next_state;
  end

  //////////////////////
  /* FSM State Switch */
  //////////////////////
  always_comb begin
    unique case (state)
      IDLE: begin
        if (s0_req)
          next_state = I0_GRANT;
        else if (s1_req)
          next_state = I1_GRANT;
        else
          next_state = IDLE;
      end
      I0_GRANT: next_state = txn_done ? IDLE : I0_GRANT;
      I1_GRANT: next_state = txn_done ? IDLE : I1_GRANT;
      default:  next_state = IDLE;
    endcase
  end

  /////////////
  /* Arbiter */
  /////////////
  assign  s0_req = s0_axi_if.awvalid | s0_axi_if.wvalid | s0_axi_if.arvalid;
  assign  s1_req = s1_axi_if.awvalid | s1_axi_if.wvalid | s1_axi_if.arvalid;
  assign  txn_done = txn_is_write_q ? (m_axi_if.bvalid & m_axi_if.bready) : (m_axi_if.rvalid & m_axi_if.rready);

  always_ff @(posedge s0_axi_if.aclk or negedge s0_axi_if.aresetn) begin
    if (~s0_axi_if.aresetn)
      txn_is_write_q <= 1'b0;
    else if (next_state == I0_GRANT && state == IDLE) begin
      txn_is_write_q <= (s0_axi_if.arvalid) ? 1'b0 : 1'b1;
    end
    else if (next_state == I1_GRANT && state == IDLE) begin
      txn_is_write_q <= (s1_axi_if.arvalid) ? 1'b0 : 1'b1;
    end
  end

  always_comb begin
    m_axi_if.awaddr  = '0;
    m_axi_if.awprot  = '0;
    m_axi_if.awid    = '0;
    m_axi_if.awlen   = '0;
    m_axi_if.awsize  = '0;
    m_axi_if.awburst = '0;
    m_axi_if.awvalid = 1'b0;
    m_axi_if.wdata   = '0;
    m_axi_if.wstrb   = '0;
    m_axi_if.wlast   = 1'b0;
    m_axi_if.wvalid  = 1'b0;
    m_axi_if.bready  = 1'b0;
    m_axi_if.araddr  = '0;
    m_axi_if.arprot  = '0;
    m_axi_if.arid    = '0;
    m_axi_if.arlen   = '0;
    m_axi_if.arsize  = '0;
    m_axi_if.arburst = '0;
    m_axi_if.arvalid = 1'b0;
    m_axi_if.rready  = 1'b0;

    s0_axi_if.awready = 1'b0;
    s0_axi_if.wready  = 1'b0;
    s0_axi_if.bresp   = '0;
    s0_axi_if.bid     = '0;
    s0_axi_if.bvalid  = 1'b0;
    s0_axi_if.arready = 1'b0;
    s0_axi_if.rdata   = '0;
    s0_axi_if.rresp   = '0;
    s0_axi_if.rid     = '0;
    s0_axi_if.rlast   = 1'b0;
    s0_axi_if.rvalid  = 1'b0;

    s1_axi_if.awready = 1'b0;
    s1_axi_if.wready  = 1'b0;
    s1_axi_if.bresp   = '0;
    s1_axi_if.bid     = '0;
    s1_axi_if.bvalid  = 1'b0;
    s1_axi_if.arready = 1'b0;
    s1_axi_if.rdata   = '0;
    s1_axi_if.rresp   = '0;
    s1_axi_if.rid     = '0;
    s1_axi_if.rlast   = 1'b0;
    s1_axi_if.rvalid  = 1'b0;

    unique case (state)
      I0_GRANT: begin
        m_axi_if.awaddr   = s0_axi_if.awaddr;
        m_axi_if.awprot   = s0_axi_if.awprot;
        m_axi_if.awid     = s0_axi_if.awid;
        m_axi_if.awlen    = s0_axi_if.awlen;
        m_axi_if.awsize   = s0_axi_if.awsize;
        m_axi_if.awburst  = s0_axi_if.awburst;
        m_axi_if.awvalid  = s0_axi_if.awvalid;
        m_axi_if.wdata    = s0_axi_if.wdata;
        m_axi_if.wstrb    = s0_axi_if.wstrb;
        m_axi_if.wlast    = s0_axi_if.wlast;
        m_axi_if.wvalid   = s0_axi_if.wvalid;
        m_axi_if.bready   = s0_axi_if.bready;
        m_axi_if.araddr   = s0_axi_if.araddr;
        m_axi_if.arprot   = s0_axi_if.arprot;
        m_axi_if.arid     = s0_axi_if.arid;
        m_axi_if.arlen    = s0_axi_if.arlen;
        m_axi_if.arsize   = s0_axi_if.arsize;
        m_axi_if.arburst  = s0_axi_if.arburst;
        m_axi_if.arvalid  = s0_axi_if.arvalid;
        m_axi_if.rready   = s0_axi_if.rready;

        s0_axi_if.awready = m_axi_if.awready;
        s0_axi_if.wready  = m_axi_if.wready;
        s0_axi_if.bresp   = m_axi_if.bresp;
        s0_axi_if.bid     = m_axi_if.bid;
        s0_axi_if.bvalid  = m_axi_if.bvalid;
        s0_axi_if.arready = m_axi_if.arready;
        s0_axi_if.rdata   = m_axi_if.rdata;
        s0_axi_if.rresp   = m_axi_if.rresp;
        s0_axi_if.rid     = m_axi_if.rid;
        s0_axi_if.rlast   = m_axi_if.rlast;
        s0_axi_if.rvalid  = m_axi_if.rvalid;
      end

      I1_GRANT: begin
        m_axi_if.awaddr   = s1_axi_if.awaddr;
        m_axi_if.awprot   = s1_axi_if.awprot;
        m_axi_if.awid     = s1_axi_if.awid;
        m_axi_if.awlen    = s1_axi_if.awlen;
        m_axi_if.awsize   = s1_axi_if.awsize;
        m_axi_if.awburst  = s1_axi_if.awburst;
        m_axi_if.awvalid  = s1_axi_if.awvalid;
        m_axi_if.wdata    = s1_axi_if.wdata;
        m_axi_if.wstrb    = s1_axi_if.wstrb;
        m_axi_if.wlast    = s1_axi_if.wlast;
        m_axi_if.wvalid   = s1_axi_if.wvalid;
        m_axi_if.bready   = s1_axi_if.bready;
        m_axi_if.araddr   = s1_axi_if.araddr;
        m_axi_if.arprot   = s1_axi_if.arprot;
        m_axi_if.arid     = s1_axi_if.arid;
        m_axi_if.arlen    = s1_axi_if.arlen;
        m_axi_if.arsize   = s1_axi_if.arsize;
        m_axi_if.arburst  = s1_axi_if.arburst;
        m_axi_if.arvalid  = s1_axi_if.arvalid;
        m_axi_if.rready   = s1_axi_if.rready;

        s1_axi_if.awready = m_axi_if.awready;
        s1_axi_if.wready  = m_axi_if.wready;
        s1_axi_if.bresp   = m_axi_if.bresp;
        s1_axi_if.bid     = m_axi_if.bid;
        s1_axi_if.bvalid  = m_axi_if.bvalid;
        s1_axi_if.arready = m_axi_if.arready;
        s1_axi_if.rdata   = m_axi_if.rdata;
        s1_axi_if.rresp   = m_axi_if.rresp;
        s1_axi_if.rid     = m_axi_if.rid;
        s1_axi_if.rlast   = m_axi_if.rlast;
        s1_axi_if.rvalid  = m_axi_if.rvalid;
      end

      default: begin
        grant_err: assert(state == IDLE) else $fatal(1, "Invalid state in AXI4 Arbiter FSM, %d", state);
      end
    endcase
  end

endmodule
