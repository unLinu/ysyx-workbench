module alu (
    input        clk,
    input  [3:0]  alu_op_i,

    input  [31:0] src1_i,
    input  [31:0] src2_i,
    output reg [31:0] alu_res_o 
);

    /* ==================================================================== */
    /* ========================= Local Parameters ========================= */
    /* ==================================================================== */

    localparam [3:0] ALU_ADD = 4'd0;
    localparam [3:0] ALU_SUB = 4'd1;
    localparam [3:0] ALU_AND = 4'd2;
    localparam [3:0] ALU_OR  = 4'd3;
    localparam [3:0] ALU_XOR = 4'd4;
    localparam [3:0] ALU_EQ  = 4'd5;
    localparam [3:0] ALU_NE  = 4'd6;
    localparam [3:0] ALU_GE  = 4'd7;
    localparam [3:0] ALU_GEU = 4'd8;
    localparam [3:0] ALU_SLL = 4'd9;
    localparam [3:0] ALU_SRL = 4'd10;
    localparam [3:0] ALU_SRA = 4'd11;
    localparam [3:0] ALU_LT  = 4'd12;
    localparam [3:0] ALU_LTU = 4'd13;

    /* ==================================================================== */
    /* ======================= Internal Signals =========================== */
    /* ==================================================================== */

    wire        is_sub;
    wire        is_eq;
    wire        is_lt;
    wire        is_geu;
    
    wire [4:0]  shift; // RLEN=5
    wire        cout;
    wire        cin;
    
    wire [31:0] src2_mux;
    wire [31:0] adder_res;

    /* ==================================================================== */
    /* ============================= Main Code ============================ */
    /* ==================================================================== */

    assign shift = src2_i[4:0];

    assign is_sub = (alu_op_i == ALU_SUB) || 
                    (alu_op_i == ALU_LT)  || 
                    (alu_op_i == ALU_LTU) || 
                    (alu_op_i == ALU_EQ)  || 
                    (alu_op_i == ALU_NE)  || 
                    (alu_op_i == ALU_GE)  || 
                    (alu_op_i == ALU_GEU);

    assign is_eq  = (adder_res == 32'd0);
    
    assign is_lt  = (src1_i[31] != src2_i[31]) ? src1_i[31] : adder_res[31];
    assign is_geu = cout; 
    
    assign src2_mux = is_sub ? ~src2_i : src2_i;
    assign cin      = is_sub;     
    
    assign {cout, adder_res} = {1'b0, src1_i} + {1'b0, src2_mux} + {31'd0, cin};

    // 组合逻辑 case
    always @(*) begin
        case (alu_op_i)
            ALU_ADD, ALU_SUB: alu_res_o = adder_res; 
            ALU_AND:          alu_res_o = src1_i & src2_i;
            ALU_OR:           alu_res_o = src1_i | src2_i;
            ALU_XOR:          alu_res_o = src1_i ^ src2_i;
            ALU_SLL:          alu_res_o = src1_i << shift;
            ALU_SRL:          alu_res_o = src1_i >> shift;
            ALU_SRA:          alu_res_o = ($signed(src1_i)) >>> shift; // 算术右移
            ALU_LT:           alu_res_o = {31'd0, is_lt};
            ALU_LTU:          alu_res_o = {31'd0, ~is_geu};
            ALU_EQ:           alu_res_o = {31'd0, is_eq};
            ALU_NE:           alu_res_o = {31'd0, ~is_eq};
            ALU_GE:           alu_res_o = {31'd0, ~is_lt};
            ALU_GEU:          alu_res_o = {31'd0, is_geu};
            default:          alu_res_o = 32'd0;
        endcase
    end

endmodule