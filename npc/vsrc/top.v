module top (
        input   wire            botton_clk      ,
        input   wire            rst             ,
        output  reg     [7:0]   Q               ,
        output  wire    [7:0]   seg0            ,
        output  wire    [7:0]   seg1            ,
        output  wire    [7:0]   seg2
    );

    wire    [11:0]  bcd;

    always @(*) begin
        case (bcd[3:0])
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
                seg0 = 8'h01; // 8
            4'b1001:
                seg0 = 8'h09; // 9
            default:
                seg0 = 8'hff;
        endcase
    end

    always @(*) begin
        case (bcd[7:4])
            4'b0000:
                seg1 = 8'h03; // 0
            4'b0001:
                seg1 = 8'h9f; // 1
            4'b0010:
                seg1 = 8'h25; // 2
            4'b0011:
                seg1 = 8'h0d; // 3
            4'b0100:
                seg1 = 8'h99; // 4
            4'b0101:
                seg1 = 8'h49; // 5
            4'b0110:
                seg1 = 8'h41; // 6
            4'b0111:
                seg1 = 8'h1f; // 7
            4'b1000:
                seg1 = 8'h01; // 8
            4'b1001:
                seg1 = 8'h09; // 9
            default:
                seg1 = 8'hff;
        endcase
    end

    always @(*) begin
        case (bcd[11:8])
            4'b0000:
                seg2 = 8'h03; // 0
            4'b0001:
                seg2 = 8'h9f; // 1
            4'b0010:
                seg2 = 8'h25; // 2
            4'b0011:
                seg2 = 8'h0d; // 3
            4'b0100:
                seg2 = 8'h99; // 4
            4'b0101:
                seg2 = 8'h49; // 5
            4'b0110:
                seg2 = 8'h41; // 6
            4'b0111:
                seg2 = 8'h1f; // 7
            4'b1000:
                seg2 = 8'h01; // 8
            4'b1001:
                seg2 = 8'h09; // 9
            default:
                seg2 = 8'hff;
        endcase
    end

    LFSR u_LFSR(
             .botton_clk 	(botton_clk  ),
             .rst        	(rst         ),
             .Q          	(Q           )
         );

    bin_to_bcd u_bin_to_bcd(
                   .bin 	(Q    ),
                   .bcd 	(bcd  )
               );


endmodule
