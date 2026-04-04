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
  // Core <-> iMem
  isa_pkg::word_t             c2im_pc             ;
  isa_pkg::word_t             im2c_inst           ;
  logic                       im2c_inst_valid     ;
  logic                       c2im_rd_en          ;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */


/* ==================================================================== */
/* =========================== Instantiation ========================== */
/* ==================================================================== */

  mem_if           mem_bus()        ;

  dpi_sim_imem u_sim_imem (
    // Interfaces
    .pc_i          ( c2im_pc          ),
    .inst_o        ( im2c_inst        ),
    // Outputs
    .inst_valid_o  ( im2c_inst_valid  ),
    // Inputs
    .clk           ( clk              ),
    .rst_n         ( rst_n            ),
    .rd_en_i       ( c2im_rd_en       )
  );

  npc_core u_core (
    // Interfaces
    .inst_i         ( im2c_inst       ),
    .pc_o           ( c2im_pc         ),
    .m_mem_if       ( mem_bus.master  ),
    // Outputs
    .ebreak_o       ( c2halt_ebreak   ),
    .ifetch_req_o   ( c2im_rd_en      ),
    // Inputs
    .clk            ( clk             ),
    .rst_n          ( rst_n           ),
    .inst_valid_i   ( im2c_inst_valid )
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
