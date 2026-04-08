module npc_top (
  // System signals
  input   logic               clk             ,
  input   logic               rst_n
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // Core <-> DPI_Halt
  logic                       c2halt_ebreak       ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */


/* ==================================================================== */
/* =========================== Instantiation ========================== */
/* ==================================================================== */

  mem_if           mem_bus  (.*);
  ifetch_bus_if    if_imem_if();
  axi4_lite_if     if_imem_axi_if( .aclk(clk), .aresetn(rst_n) );

  dpi_sim_imem u_sim_imem (
    // Interfaces
    .s_axi_if      ( if_imem_axi_if.slave    )
  );

  axi4_lite_master u_axi_master (
    // Interfaces
    .s_bus_if      ( if_imem_if.slave        ),
    .m_axi_if      ( if_imem_axi_if.master   )
  );

  npc_core u_core (
    // Interfaces
    .if_imem_if    ( if_imem_if.master ),
    .m_mem_if      ( mem_bus.master    ),
    // Outputs
    .ebreak_o      ( c2halt_ebreak     ),
    // Inputs
    .clk           ( clk               ),
    .rst_n         ( rst_n             )
  );

  dpi_sim_mem u_sim_mem (
    // Interfaces
    .s_mem_if    ( mem_bus.slave   ),
    // Inputs
    .clk         ( clk             )
  );

  dpi_halt u_dpi_halt (
    // Inputs
    .ebreak_i    ( c2halt_ebreak  )
  );

endmodule
// Local Variables:
// verilog-library-flags:("-F ../filelist.f")
// End:
