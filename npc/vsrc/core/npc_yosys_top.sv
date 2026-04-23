module npc_yosys_top (
  input   logic         clk,
  input   logic         rst_n,

  output  logic [ 3:0]  o_mem_axi_awid,
  output  logic [31:0]  o_mem_axi_awaddr,
  output  logic [ 7:0]  o_mem_axi_awlen,
  output  logic [ 2:0]  o_mem_axi_awsize,
  output  logic [ 1:0]  o_mem_axi_awburst,
  output  logic [ 2:0]  o_mem_axi_awprot,
  output  logic         o_mem_axi_awvalid,
  input   logic         o_mem_axi_awready,

  output  logic [31:0]  o_mem_axi_wdata,
  output  logic [ 3:0]  o_mem_axi_wstrb,
  output  logic         o_mem_axi_wlast,
  output  logic         o_mem_axi_wvalid,
  input   logic         o_mem_axi_wready,

  input   logic [ 1:0]  o_mem_axi_bresp,
  input   logic [ 3:0]  o_mem_axi_bid,
  input   logic         o_mem_axi_bvalid,
  output  logic         o_mem_axi_bready,

  output  logic [ 3:0]  o_mem_axi_arid,
  output  logic [31:0]  o_mem_axi_araddr,
  output  logic [ 7:0]  o_mem_axi_arlen,
  output  logic [ 2:0]  o_mem_axi_arsize,
  output  logic [ 1:0]  o_mem_axi_arburst,
  output  logic [ 2:0]  o_mem_axi_arprot,
  output  logic         o_mem_axi_arvalid,
  input   logic         o_mem_axi_arready,

  input   logic [31:0]  o_mem_axi_rdata,
  input   logic [ 1:0]  o_mem_axi_rresp,
  input   logic [ 3:0]  o_mem_axi_rid,
  input   logic         o_mem_axi_rlast,
  input   logic         o_mem_axi_rvalid,
  output  logic         o_mem_axi_rready,

  output  logic         ebreak_o
);

  axi4_if o_mem_axi_if (
    .aclk     ( clk   ),
    .aresetn  ( rst_n )
  );

  assign o_mem_axi_awid         = o_mem_axi_if.awid;
  assign o_mem_axi_awaddr       = o_mem_axi_if.awaddr;
  assign o_mem_axi_awlen        = o_mem_axi_if.awlen;
  assign o_mem_axi_awsize       = o_mem_axi_if.awsize;
  assign o_mem_axi_awburst      = o_mem_axi_if.awburst;
  assign o_mem_axi_awprot       = o_mem_axi_if.awprot;
  assign o_mem_axi_awvalid      = o_mem_axi_if.awvalid;
  assign o_mem_axi_if.awready   = o_mem_axi_awready;

  assign o_mem_axi_wdata        = o_mem_axi_if.wdata;
  assign o_mem_axi_wstrb        = o_mem_axi_if.wstrb;
  assign o_mem_axi_wlast        = o_mem_axi_if.wlast;
  assign o_mem_axi_wvalid       = o_mem_axi_if.wvalid;
  assign o_mem_axi_if.wready    = o_mem_axi_wready;

  assign o_mem_axi_if.bresp     = o_mem_axi_bresp;
  assign o_mem_axi_if.bid       = o_mem_axi_bid;
  assign o_mem_axi_if.bvalid    = o_mem_axi_bvalid;
  assign o_mem_axi_bready       = o_mem_axi_if.bready;

  assign o_mem_axi_arid         = o_mem_axi_if.arid;
  assign o_mem_axi_araddr       = o_mem_axi_if.araddr;
  assign o_mem_axi_arlen        = o_mem_axi_if.arlen;
  assign o_mem_axi_arsize       = o_mem_axi_if.arsize;
  assign o_mem_axi_arburst      = o_mem_axi_if.arburst;
  assign o_mem_axi_arprot       = o_mem_axi_if.arprot;
  assign o_mem_axi_arvalid      = o_mem_axi_if.arvalid;
  assign o_mem_axi_if.arready   = o_mem_axi_arready;

  assign o_mem_axi_if.rdata     = o_mem_axi_rdata;
  assign o_mem_axi_if.rresp     = o_mem_axi_rresp;
  assign o_mem_axi_if.rid       = o_mem_axi_rid;
  assign o_mem_axi_if.rlast     = o_mem_axi_rlast;
  assign o_mem_axi_if.rvalid    = o_mem_axi_rvalid;
  assign o_mem_axi_rready       = o_mem_axi_if.rready;

  npc_core u_core (
    .clk          ( clk         ),
    .rst_n        ( rst_n       ),
    .o_mem_axi_if ( o_mem_axi_if ),
    .ebreak_o     ( ebreak_o    )
  );

endmodule
