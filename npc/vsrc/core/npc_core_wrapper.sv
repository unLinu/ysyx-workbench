module npc_core_wrapper (
  input   logic         clock,
  input   logic         reset,

  output  logic [ 3:0]  io_master_awid,
  output  logic [31:0]  io_master_awaddr,
  output  logic [ 7:0]  io_master_awlen,
  output  logic [ 2:0]  io_master_awsize,
  output  logic [ 1:0]  io_master_awburst,
  output  logic [ 2:0]  io_master_awprot,
  output  logic         io_master_awvalid,
  input   logic         io_master_awready,

  output  logic [31:0]  io_master_wdata,
  output  logic [ 3:0]  io_master_wstrb,
  output  logic         io_master_wlast,
  output  logic         io_master_wvalid,
  input   logic         io_master_wready,

  input   logic [ 1:0]  io_master_bresp,
  input   logic [ 3:0]  io_master_bid,
  input   logic         io_master_bvalid,
  output  logic         io_master_bready,

  output  logic [ 3:0]  io_master_arid,
  output  logic [31:0]  io_master_araddr,
  output  logic [ 7:0]  io_master_arlen,
  output  logic [ 2:0]  io_master_arsize,
  output  logic [ 1:0]  io_master_arburst,
  output  logic [ 2:0]  io_master_arprot,
  output  logic         io_master_arvalid,
  input   logic         io_master_arready,

  input   logic [31:0]  io_master_rdata,
  input   logic [ 1:0]  io_master_rresp,
  input   logic [ 3:0]  io_master_rid,
  input   logic         io_master_rlast,
  input   logic         io_master_rvalid,
  output  logic         io_master_rready,

  output  logic         ebreak_o
);

  axi4_if m_axi_if ( .aclk(clock), .aresetn (~reset));

  assign io_master_awid         = m_axi_if.awid;
  assign io_master_awaddr       = m_axi_if.awaddr;
  assign io_master_awlen        = m_axi_if.awlen;
  assign io_master_awsize       = m_axi_if.awsize;
  assign io_master_awburst      = m_axi_if.awburst;
  assign io_master_awprot       = m_axi_if.awprot;
  assign io_master_awvalid      = m_axi_if.awvalid;
  assign m_axi_if.awready       = io_master_awready;

  assign io_master_wdata        = m_axi_if.wdata;
  assign io_master_wstrb        = m_axi_if.wstrb;
  assign io_master_wlast        = m_axi_if.wlast;
  assign io_master_wvalid       = m_axi_if.wvalid;
  assign m_axi_if.wready        = io_master_wready;

  assign m_axi_if.bresp         = io_master_bresp;
  assign m_axi_if.bid           = io_master_bid;
  assign m_axi_if.bvalid        = io_master_bvalid;
  assign io_master_bready       = m_axi_if.bready;

  assign io_master_arid         = m_axi_if.arid;
  assign io_master_araddr       = m_axi_if.araddr;
  assign io_master_arlen        = m_axi_if.arlen;
  assign io_master_arsize       = m_axi_if.arsize;
  assign io_master_arburst      = m_axi_if.arburst;
  assign io_master_arprot       = m_axi_if.arprot;
  assign io_master_arvalid      = m_axi_if.arvalid;
  assign m_axi_if.arready       = io_master_arready;

  assign m_axi_if.rdata         = io_master_rdata;
  assign m_axi_if.rresp         = io_master_rresp;
  assign m_axi_if.rid           = io_master_rid;
  assign m_axi_if.rlast         = io_master_rlast;
  assign m_axi_if.rvalid        = io_master_rvalid;
  assign io_master_rready       = m_axi_if.rready;

  npc_core u_core (
    .clk          ( clock        ),
    .rst_n        ( ~reset       ),
    .m_axi_if     ( m_axi_if     ),
    .ebreak_o     ( ebreak_o     )
  );

endmodule
