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

  axi4_if     o_mem_axi_if   ( .aclk(clk), .aresetn(rst_n) );
  axi4_if     sram_axi_if    ( .aclk(clk), .aresetn(rst_n) );
  axi4_if     uart_axi_if    ( .aclk(clk), .aresetn(rst_n) );
  axi4_if     clint_axi_if   ( .aclk(clk), .aresetn(rst_n) );

  npc_core u_core (
    // Interfaces
    .m_axi_if      ( o_mem_axi_if      ),
    // Outputs
    .ebreak_o      ( c2halt_ebreak     ),
    // Inputs
    .clk           ( clk               ),
    .rst_n         ( rst_n             )
  );

  axi4_xbar u_axi_xbar (
    // Interfaces
    .s_axi_if        ( o_mem_axi_if    ),
    .m_uart_axi_if   ( uart_axi_if     ),
    .m_clint_axi_if  ( clint_axi_if    ),
    .m_sram_axi_if   ( sram_axi_if     )
  );

  dpi_sim_sram u_sim_sram (
    // Interfaces
    .s_axi_if    ( sram_axi_if  )
  );

  sim_uart u_sim_uart (
		// Interfaces
    .s_axi_if    ( uart_axi_if    )
  );

  clint u_clint (
		// Interfaces
    .s_axi_if    ( clint_axi_if   )
  );

  dpi_halt u_dpi_halt (
    // Inputs
    .ebreak_i    ( c2halt_ebreak  )
  );

endmodule
// Local Variables:
// verilog-library-flags:("-F ../filelist.f")
// End:
