module npc_top (
  // System signals
  input   logic               clk             ,
  input   logic               rst_n           ,
  // Fetch Instruction
  input   isa_pkg::word_t     inst_i          ,
  output  isa_pkg::word_t     pc_o
);

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

  // Core <-> Mem
  logic                       c2h_ebreak      ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */


/* ==================================================================== */
/* =========================== Instantiation ========================== */
/* ==================================================================== */

  mem_if           mem_bus()        ;

  npc_core u_core (
    // Interfaces
    .inst_i      ( inst_i          ),
    .pc_o        ( pc_o            ),
    .m_mem_if    ( mem_bus.master  ),
    // Outputs
    .ebreak_o    ( c2h_ebreak      ),
    // Inputs
    .clk         ( clk             ),
    .rst_n       ( rst_n           )
  );

  dpi_sim_mem u_sim_mem (
    // Interfaces
    .s_mem_if    ( mem_bus.slave   ),
    // Inputs
    .clk         ( clk             )
  );

  dpi_halt u_dpi_halt (
    // Inputs
    .ebreak_i    ( c2h_ebreak      )
  );

endmodule
// Local Variables:
// verilog-library-flags:("-F ../filelist.f")
// End:
