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

  core_mem_if      if_imem_if();
  core_mem_if      ls_mem_if();
  axi4_lite_if     if_imem_axi_if( .aclk(clk), .aresetn(rst_n) );
  axi4_lite_if     ls_mem_axi_if( .aclk(clk), .aresetn(rst_n) );

  dpi_sim_imem u_sim_imem (
    // Interfaces
    .s_axi_if      ( if_imem_axi_if    )
  );

  axi4_lite_master u_axi_master_if (
    // Interfaces
    .s_bus_if      ( if_imem_if        ),
    .m_axi_if      ( if_imem_axi_if    )
  );

  npc_core u_core (
    // Interfaces
    .if_imem_if    ( if_imem_if        ),
    .m_mem_if      ( ls_mem_if         ),
    // Outputs
    .ebreak_o      ( c2halt_ebreak     ),
    // Inputs
    .clk           ( clk               ),
    .rst_n         ( rst_n             )
  );

  axi4_lite_master u_axi_master_ls (
    // Interfaces
    .s_bus_if      ( ls_mem_if      ),
    .m_axi_if      ( ls_mem_axi_if  )
  );

  dpi_sim_mem u_sim_mem (
    // Interfaces
    .s_axi_if    ( ls_mem_axi_if  )
  );

  dpi_halt u_dpi_halt (
    // Inputs
    .ebreak_i    ( c2halt_ebreak  )
  );

endmodule
// Local Variables:
// verilog-library-flags:("-F ../filelist.f")
// End:
