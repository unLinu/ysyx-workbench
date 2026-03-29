module dpi_probe_csr import ctrl_pkg::*; (
  input   isa_pkg::csr_file_t     csr_i
);

  export "DPI-C" function dpi_get_csr     ;

  function automatic int dpi_get_csr(input int csr_addr);
    logic [11:0] addr = csr_addr[11:0];
    isa_pkg::word_t ret_csr_val;
    unique case (addr)
      MSTATUS: ret_csr_val = csr_i.mstatus;
      MEPC   : ret_csr_val = csr_i.mepc;
      MCAUSE : ret_csr_val = csr_i.mcause;
      MTVEC  : ret_csr_val = csr_i.mtvec;
      default: assert(0) else $fatal("CSR addr: %d is out of bounds!");
    endcase

    return ret_csr_val;
  endfunction

endmodule
