interface axi4_if #(
  parameter   ADDR_WIDTH = 32             ,
  parameter   DATA_WIDTH = 32
)(
  // Global Signals
  input   logic               aclk        ,
  input   logic               aresetn
);
  // Write Address Channel
  logic   [ADDR_WIDTH-1:0]    awaddr      ;
  logic   [ 2:0]              awprot      ;
  logic   [ 3:0]              awid        ;
  logic   [ 7:0]              awlen       ;
  logic   [ 2:0]              awsize      ;
  logic   [ 1:0]              awburst     ;
  logic                       awvalid     ;
  logic                       awready     ;
  // Write Data Channel
  logic   [DATA_WIDTH-1:0]    wdata       ;
  logic   [DATA_WIDTH/8-1:0]  wstrb       ;
  logic                       wlast       ;
  logic                       wvalid      ;
  logic                       wready      ;
  // Write Response Channel
  logic   [ 1:0]              bresp       ;
  logic   [ 3:0]              bid         ;
  logic                       bvalid      ;
  logic                       bready      ;
  // Read Address Channel
  logic   [ADDR_WIDTH-1:0]    araddr      ;
  logic   [ 2:0]              arprot      ;
  logic   [ 3:0]              arid        ;
  logic   [ 7:0]              arlen       ;
  logic   [ 2:0]              arsize      ;
  logic   [ 1:0]              arburst     ;
  logic                       arvalid     ;
  logic                       arready     ;
  // Read Data Channel
  logic   [DATA_WIDTH-1:0]    rdata       ;
  logic   [ 1:0]              rresp       ;
  logic   [ 3:0]              rid         ;
  logic                       rlast       ;
  logic                       rvalid      ;
  logic                       rready      ;

  // Modports
  modport master (
    // Global Signals
    input   aclk, aresetn,
    // Write Address Channel
    input   awready,
    output  awaddr, awprot, awid, awlen, awsize, awburst, awvalid,
    // Write Data Channel
    input   wready,
    output  wdata, wstrb, wlast, wvalid,
    // Write Response Channel
    input   bresp, bid, bvalid,
    output  bready,
    // Read Address Channel
    input   arready,
    output  araddr, arprot, arid, arlen, arsize, arburst, arvalid,
    // Read Data Channel
    input   rdata, rresp, rid, rlast, rvalid,
    output  rready
  );

  modport slave (
    // Global Signals
    input   aclk, aresetn,
    // Write Address Channel
    output  awready,
    input   awaddr, awprot, awid, awlen, awsize, awburst, awvalid,
    // Write Data Channel
    output  wready,
    input   wdata, wstrb, wlast, wvalid,
    // Write Response Channel
    output  bresp, bid, bvalid,
    input   bready,
    // Read Address Channel
    output  arready,
    input   araddr, arprot, arid, arlen, arsize, arburst, arvalid,
    // Read Data Channel
    output  rdata, rresp, rid, rlast, rvalid,
    input   rready
  );

endinterface
