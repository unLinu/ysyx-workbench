`define ADD 3'b000
`define SUB 3'b001
`define NOT 3'b010
`define AND 3'b011
`define OR  3'b100
`define XOR 3'b101
`define LT  3'b110
`define EQ  3'b111

module ALU (
        input   wire    [3:0]   A           ,
        input   wire    [3:0]   B           ,   // 补码
        input   wire    [2:0]   sel         ,
        output  wire    [3:0]   result      ,
        output  wire            is_zero     ,
        output  wire            overflow    ,
        output  wire            carry_out       // 为 1 时产生进位或借位
    );

    wire [4:0]  sum;
    wire [4:0]  diff;
    reg  [3:0]  result_reg;

    assign  result  = result_reg;

    assign  sum     = {1'b0, A} + {1'b0, B};
    assign  diff    = {1'b0, A} + {1'b0, ~B} + 5'd1; // A-B = A+~B+1
    assign  is_zero = ~(| result_reg);
    assign  overflow = sel == `ADD ? (A[3] == B[3]) && (sum[3] != A[3]) :
            ((sel == `SUB) || (sel == `LT) ? (A[3] != B[3]) && (diff[3] != A[3]) :
             1'b0);
    assign  carry_out = (sel == `ADD) ? sum[4] :
                       ((sel == `SUB) ? ~diff[4] : 1'b0); 

    always @(*) begin
        case (sel)
            `ADD:
                result_reg = sum[3:0];
            `SUB:
                result_reg = diff[3:0];
            `NOT:
                result_reg = ~A;
            `AND:
                result_reg = A & B;
            `OR :
                result_reg = A | B;
            `XOR:
                result_reg = A ^ B;
            `LT :
                result_reg = {3'b0, diff[3] ^ overflow};
            `EQ :
                result_reg = (| diff[3:0]) ? 4'd0 : 4'd1;
            default:
                result_reg = 4'd0;
            endcase
    end


endmodule
