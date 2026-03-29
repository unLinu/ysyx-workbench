interface handshake_if #(
  parameter type PKG_T = logic[31:0]
);
  // handshake
  logic   ready     ;
  logic   valid     ;
  // payload
  PKG_T   data_pkg  ;

  modport master (
    input   ready ,
    output  valid ,
    output  data_pkg
  );

  modport slave (
    output  ready ,
    input   valid ,
    input   data_pkg
  );

endinterface
