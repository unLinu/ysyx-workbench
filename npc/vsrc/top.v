module top (
        input   wire            clk     ,
        input   wire            rst         ,
        input   wire            ps2_clk     ,
        input   wire            ps2_data    ,
        output  reg     [7:0]   seg0        ,
        output  reg     [7:0]   seg1        ,
        output  reg     [7:0]   seg2        ,
        output  reg     [7:0]   seg3        ,
        output  reg     [7:0]   seg4        ,
        output  reg     [7:0]   seg5        ,
        output  wire    [7:0]   led
    );

    reg     [7:0]   key_code;
    reg     [7:0]   key_code_dly;
    reg     [7:0]   key_ascii;
    reg     [7:0]   press_cnt;
    reg     [11:0]  press_cnt_bcd;
    reg             key_pressed;
    reg             ps2_clk_dly;

    assign led = key_code;

    always @(posedge clk) begin
        if (rst)
            key_code_dly <= 8'd0;
        else
            key_code_dly <= key_code;
    end

    always @(posedge clk) begin
        if (rst)
            ps2_clk_dly <= 1'b1;
        else
            ps2_clk_dly <= ps2_clk;
    end

    // 检测到段码前缀说明松开
    always @(posedge clk) begin
        if (rst)
            key_pressed <= 1'b0;
        else if (key_code == 8'hf0)
            key_pressed <= 1'b0;
        else if (ps2_clk != ps2_clk_dly)
            key_pressed <= 1'b1;
    end

    // 检测到断码算一次按下
    always @(posedge clk) begin
        if (rst)
            press_cnt <= 8'd0;
        else if (press_cnt == 8'd99)
            press_cnt <= 8'd0;
        else if ((key_code_dly == 8'hf0) && (key_code != 8'hf0))
            press_cnt <= press_cnt + 8'd1;
    end


    always @(*) begin
        if (key_pressed) begin
            case (key_code[3:0])
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
                4'b1010:
                    seg0 = 8'h11; // A
                4'b1011:
                    seg0 = 8'hC1; // b
                4'b1100:
                    seg0 = 8'h63; // C
                4'b1101:
                    seg0 = 8'h85; // d
                4'b1110:
                    seg0 = 8'h61; // E
                4'b1111:
                    seg0 = 8'h71; // F
                default:
                    seg0 = 8'hff;
            endcase
        end
        else
            seg0 = 8'hff;
    end

    always @(*) begin
        if (key_pressed) begin
            case (key_code[7:4])
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
                4'b1010:
                    seg1 = 8'h11; // A
                4'b1011:
                    seg1 = 8'hC1; // b
                4'b1100:
                    seg1 = 8'h63; // C
                4'b1101:
                    seg1 = 8'h85; // d
                4'b1110:
                    seg1 = 8'h61; // E
                4'b1111:
                    seg1 = 8'h71; // F
                default:
                    seg1 = 8'hff;
            endcase
        end
        else
            seg1 = 8'hff;
    end

    always @(*) begin
        if (key_pressed) begin
            case (key_ascii[3:0])
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
                4'b1010:
                    seg2 = 8'h11; // A
                4'b1011:
                    seg2 = 8'hC1; // b
                4'b1100:
                    seg2 = 8'h63; // C
                4'b1101:
                    seg2 = 8'h85; // d
                4'b1110:
                    seg2 = 8'h61; // E
                4'b1111:
                    seg2 = 8'h71; // F
                default:
                    seg2 = 8'hff;
            endcase
        end
        else
            seg2 = 8'hff;
    end

    always @(*) begin
        if (key_pressed) begin
            case (key_ascii[7:4])
                4'b0000:
                    seg3 = 8'h03; // 0
                4'b0001:
                    seg3 = 8'h9f; // 1
                4'b0010:
                    seg3 = 8'h25; // 2
                4'b0011:
                    seg3 = 8'h0d; // 3
                4'b0100:
                    seg3 = 8'h99; // 4
                4'b0101:
                    seg3 = 8'h49; // 5
                4'b0110:
                    seg3 = 8'h41; // 6
                4'b0111:
                    seg3 = 8'h1f; // 7
                4'b1000:
                    seg3 = 8'h01; // 8
                4'b1001:
                    seg3 = 8'h09; // 9
                4'b1010:
                    seg3 = 8'h11; // A
                4'b1011:
                    seg3 = 8'hC1; // b
                4'b1100:
                    seg3 = 8'h63; // C
                4'b1101:
                    seg3 = 8'h85; // d
                4'b1110:
                    seg3 = 8'h61; // E
                4'b1111:
                    seg3 = 8'h71; // F
                default:
                    seg3 = 8'hff;
            endcase
        end
        else
            seg3 = 8'hff;
    end

    always @(*) begin
        case (press_cnt_bcd[3:0])
            4'b0000:
                seg4 = 8'h03; // 0
            4'b0001:
                seg4 = 8'h9f; // 1
            4'b0010:
                seg4 = 8'h25; // 2
            4'b0011:
                seg4 = 8'h0d; // 3
            4'b0100:
                seg4 = 8'h99; // 4
            4'b0101:
                seg4 = 8'h49; // 5
            4'b0110:
                seg4 = 8'h41; // 6
            4'b0111:
                seg4 = 8'h1f; // 7
            4'b1000:
                seg4 = 8'h01; // 8
            4'b1001:
                seg4 = 8'h09; // 9
            4'b1010:
                seg4 = 8'h11; // A
            4'b1011:
                seg4 = 8'hC1; // b
            4'b1100:
                seg4 = 8'h63; // C
            4'b1101:
                seg4 = 8'h85; // d
            4'b1110:
                seg4 = 8'h61; // E
            4'b1111:
                seg4 = 8'h71; // F
            default:
                seg4 = 8'hff;
        endcase
    end

    always @(*) begin
        case (press_cnt_bcd[7:4])
            4'b0000:
                seg5 = 8'h03; // 0
            4'b0001:
                seg5 = 8'h9f; // 1
            4'b0010:
                seg5 = 8'h25; // 2
            4'b0011:
                seg5 = 8'h0d; // 3
            4'b0100:
                seg5 = 8'h99; // 4
            4'b0101:
                seg5 = 8'h49; // 5
            4'b0110:
                seg5 = 8'h41; // 6
            4'b0111:
                seg5 = 8'h1f; // 7
            4'b1000:
                seg5 = 8'h01; // 8
            4'b1001:
                seg5 = 8'h09; // 9
            4'b1010:
                seg5 = 8'h11; // A
            4'b1011:
                seg5 = 8'hC1; // b
            4'b1100:
                seg5 = 8'h63; // C
            4'b1101:
                seg5 = 8'h85; // d
            4'b1110:
                seg5 = 8'h61; // E
            4'b1111:
                seg5 = 8'h71; // F
            default:
                seg5 = 8'hff;
        endcase
    end

    keyboard u_keyboard(
                 .clk           (clk        ),
                 .ps2_clk   	(ps2_clk    ),
                 .ps2_data  	(ps2_data   ),
                 .srst      	(rst        ),
                 .key_code  	(key_code   )
             );

    key_code_rom u_key_code_rom(
                     .key_code  	(key_code   ),
                     .key_ascii 	(key_ascii  )
                 );

    bin_to_bcd u_bin_to_bcd(
                   .bin 	(press_cnt      ),
                   .bcd 	(press_cnt_bcd  )
               );


endmodule
