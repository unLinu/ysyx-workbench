module axi4_lite_arbiter (
  // interface
  axi4_lite_if.slave              i0_axi_if       ,
  axi4_lite_if.slave              i1_axi_if       ,
  axi4_lite_if.master             o_axi_if
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
  logic           i0_req, i1_req    ;

  arb_state_e     state, next_state ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

  //////////////////////
  /* FSM State Update */
  //////////////////////
  always_ff @(posedge i0_axi_if.aclk or negedge i0_axi_if.aresetn) begin
    if (~i0_axi_if.aresetn)
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
        if (i0_req)
          next_state = I0_GRANT;
        else if (i1_req)
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
  assign  i0_req = i0_axi_if.awvalid | i0_axi_if.wvalid | i0_axi_if.arvalid;
  assign  i1_req = i1_axi_if.awvalid | i1_axi_if.wvalid | i1_axi_if.arvalid;
  assign  txn_done = txn_is_write_q ? (o_axi_if.bvalid & o_axi_if.bready) : (o_axi_if.rvalid & o_axi_if.rready);

  always_ff @(posedge i0_axi_if.aclk or negedge i0_axi_if.aresetn) begin
    if (~i0_axi_if.aresetn)
      txn_is_write_q <= 1'b0;
    else if (next_state == I0_GRANT && state == IDLE) begin
      txn_is_write_q <= (i0_axi_if.arvalid) ? 1'b0 : 1'b1;
    end
    else if (next_state == I1_GRANT && state == IDLE) begin
      txn_is_write_q <= (i1_axi_if.arvalid) ? 1'b0 : 1'b1;
    end
  end

  always_comb begin
    o_axi_if.awaddr  = '0;
    o_axi_if.awprot  = '0;
    o_axi_if.awvalid = 1'b0;
    o_axi_if.wdata   = '0;
    o_axi_if.wstrb   = '0;
    o_axi_if.wvalid  = 1'b0;
    o_axi_if.bready  = 1'b0;
    o_axi_if.araddr  = '0;
    o_axi_if.arprot  = '0;
    o_axi_if.arvalid = 1'b0;
    o_axi_if.rready  = 1'b0;

    i0_axi_if.awready = 1'b0;
    i0_axi_if.wready  = 1'b0;
    i0_axi_if.bresp   = '0;
    i0_axi_if.bvalid  = 1'b0;
    i0_axi_if.arready = 1'b0;
    i0_axi_if.rdata   = '0;
    i0_axi_if.rresp   = '0;
    i0_axi_if.rvalid  = 1'b0;

    i1_axi_if.awready = 1'b0;
    i1_axi_if.wready  = 1'b0;
    i1_axi_if.bresp   = '0;
    i1_axi_if.bvalid  = 1'b0;
    i1_axi_if.arready = 1'b0;
    i1_axi_if.rdata   = '0;
    i1_axi_if.rresp   = '0;
    i1_axi_if.rvalid  = 1'b0;

    unique case (state)
      I0_GRANT: begin
        o_axi_if.awaddr   = i0_axi_if.awaddr;
        o_axi_if.awprot   = i0_axi_if.awprot;
        o_axi_if.awvalid  = i0_axi_if.awvalid;
        o_axi_if.wdata    = i0_axi_if.wdata;
        o_axi_if.wstrb    = i0_axi_if.wstrb;
        o_axi_if.wvalid   = i0_axi_if.wvalid;
        o_axi_if.bready   = i0_axi_if.bready;
        o_axi_if.araddr   = i0_axi_if.araddr;
        o_axi_if.arprot   = i0_axi_if.arprot;
        o_axi_if.arvalid  = i0_axi_if.arvalid;
        o_axi_if.rready   = i0_axi_if.rready;

        i0_axi_if.awready = o_axi_if.awready;
        i0_axi_if.wready  = o_axi_if.wready;
        i0_axi_if.bresp   = o_axi_if.bresp;
        i0_axi_if.bvalid  = o_axi_if.bvalid;
        i0_axi_if.arready = o_axi_if.arready;
        i0_axi_if.rdata   = o_axi_if.rdata;
        i0_axi_if.rresp   = o_axi_if.rresp;
        i0_axi_if.rvalid  = o_axi_if.rvalid;
      end

      I1_GRANT: begin
        o_axi_if.awaddr   = i1_axi_if.awaddr;
        o_axi_if.awprot   = i1_axi_if.awprot;
        o_axi_if.awvalid  = i1_axi_if.awvalid;
        o_axi_if.wdata    = i1_axi_if.wdata;
        o_axi_if.wstrb    = i1_axi_if.wstrb;
        o_axi_if.wvalid   = i1_axi_if.wvalid;
        o_axi_if.bready   = i1_axi_if.bready;
        o_axi_if.araddr   = i1_axi_if.araddr;
        o_axi_if.arprot   = i1_axi_if.arprot;
        o_axi_if.arvalid  = i1_axi_if.arvalid;
        o_axi_if.rready   = i1_axi_if.rready;

        i1_axi_if.awready = o_axi_if.awready;
        i1_axi_if.wready  = o_axi_if.wready;
        i1_axi_if.bresp   = o_axi_if.bresp;
        i1_axi_if.bvalid  = o_axi_if.bvalid;
        i1_axi_if.arready = o_axi_if.arready;
        i1_axi_if.rdata   = o_axi_if.rdata;
        i1_axi_if.rresp   = o_axi_if.rresp;
        i1_axi_if.rvalid  = o_axi_if.rvalid;
      end

      default: begin
        grant_err: assert(state == IDLE) else $fatal(1, "Invalid state in AXI4-Lite Arbiter FSM, %d", state);
      end
    endcase
  end

endmodule
