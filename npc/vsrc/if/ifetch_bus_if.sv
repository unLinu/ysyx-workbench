interface ifetch_bus_if #(
  parameter   ADDR_WIDTH  = 32              ,
  parameter   DATA_WIDTH  = 32
);

  // +--------+                                   +--------+
  // | Master | -- req_addr, req_valid -------->  | Slave  |
  // |        | <- req_ready -------------------  |        |
  // |        | <- rsp_data, rsp_valid, rsp_error |        |
  // |        | -- rsp_ready ------------------>  |        |
  // +--------+                                   +--------+

  // Request Channel
  logic   [ADDR_WIDTH-1:0]    req_addr      ;
  logic                       req_valid     ;
  logic                       req_ready     ;
  // Response Channel
  logic   [DATA_WIDTH-1:0]    rsp_data      ;
  logic                       rsp_valid     ;
  logic                       rsp_ready     ;
  logic                       rsp_error     ;

  // Modports
  modport master (
    // Request Channel
    input   req_ready,
    output  req_addr, req_valid,
    // Response Channel
    input   rsp_data, rsp_valid, rsp_error,
    output  rsp_ready
  );

  modport slave (
    // Request Channel
    output  req_ready,
    input   req_addr, req_valid,
    // Response Channel
    output  rsp_data, rsp_valid, rsp_error,
    input   rsp_ready
  );

endinterface
