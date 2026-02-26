`include "npc_defines.svh"
module regfile import npc_pkg::*; (
    input   logic                       clk         ,

    input   npc_pkg::regid_t            rs1_i       ,
    input   npc_pkg::regid_t            rs2_i       ,
    input   npc_pkg::regid_t            rd_i        ,

    input   logic                       wr_en_i     ,
    input   npc_pkg::word_t             rd_data_i   ,
    
    output  npc_pkg::word_t             rs1_data_o  ,
    output  npc_pkg::word_t             rs2_data_o 
);

`include "npc_dpi.svh"

/* ==================================================================== */
/* ============================ Parameters ============================ */
/* ==================================================================== */

    npc_pkg::word_t     gpr [0:`GPR_NUM-1] /* verilator public */;

/* ==================================================================== */
/* ============================= Main Code ============================ */
/* ==================================================================== */

    assign  rs1_data_o = (rs1_i == `RLEN'd0) ? {`XLEN{1'b0}} : gpr[rs1_i];
    assign  rs2_data_o = (rs2_i == `RLEN'd0) ? {`XLEN{1'b0}} : gpr[rs2_i];

    always_ff @(posedge clk) begin
        if (wr_en_i && (rd_i != {`RLEN{1'b0}}))
            gpr[rd_i] <= rd_data_i;
    end

endmodule
