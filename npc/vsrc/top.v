module top (
        input   wire    [3:0]   A           ,
        input   wire    [3:0]   B           ,
        input   wire    [2:0]   sel         ,
        output  wire    [3:0]   result      ,
        output  reg     [7:0]   seg0        ,
        output  wire    [7:0]   seg1        ,
        output  wire            is_zero     ,
        output  wire            overflow    ,
        output  wire            carry_out       // 为 1 时产生进位或借位
    );

    assign  seg1[1] = ~result[3];
    assign  {seg1[7:2], seg1[0]} = 7'b1111111;

    always @(*) begin
        case (result)
            4'b0000:
                seg0 = 8'h03; // 0
            4'b0001:
                seg0 = 8'h9f; // 1
            4'b0010:
                seg0 = 8'h25; // 2
            4'b0011:
                seg0 = 8'h0d; // 3
            4'b0100:
                seg0 = 8'h99; // 4
            4'b0101:
                seg0 = 8'h49; // 5
            4'b0110:
                seg0 = 8'h41; // 6
            4'b0111:
                seg0 = 8'h1f; // 7
            4'b1000:
                seg0 = 8'h01; // -8
            4'b1001:
                seg0 = 8'h1f; // -7
            4'b1010:
                seg0 = 8'h41; // -6
            4'b1011:
                seg0 = 8'h49; // -5
            4'b1100:
                seg0 = 8'h99; // -4
            4'b1101:
                seg0 = 8'h0d; // -3
            4'b1110:
                seg0 = 8'h25; // -2
            4'b1111:
                seg0 = 8'h9f; // -1
            default:
                seg0 = 8'hff;
        endcase
    end

    ALU u_ALU(
            .A         	(A          ),
            .B         	(B          ),
            .sel       	(sel        ),
            .result    	(result     ),
            .is_zero   	(is_zero    ),
            .overflow  	(overflow   ),
            .carry_out 	(carry_out  )
        );


endmodule
