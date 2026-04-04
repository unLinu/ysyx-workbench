module dpi_probe_wbu (
  input   logic                 wbu_commit_valid_i,
  input   isa_pkg::word_t       wbu_inst_i
);

  export "DPI-C" function dpi_get_commit  ;
  export "DPI-C" function dpi_get_inst    ;

  function automatic bit dpi_get_commit() ;
    return wbu_commit_valid_i;
  endfunction

  function automatic int dpi_get_inst() ;
    return wbu_inst_i;
  endfunction

endmodule
