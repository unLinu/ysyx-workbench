module key_code_rom (
        input   wire    [7:0]   key_code        ,
        output  reg     [7:0]   key_ascii   
    );

    always @(*) begin
        case (key_code)
            // 数字 0-9
            8'h45: key_ascii = "0";
            8'h16: key_ascii = "1";
            8'h1E: key_ascii = "2";
            8'h26: key_ascii = "3";
            8'h25: key_ascii = "4";
            8'h2E: key_ascii = "5";
            8'h36: key_ascii = "6";
            8'h3D: key_ascii = "7";
            8'h3E: key_ascii = "8";
            8'h46: key_ascii = "9";

            // 字母 A-Z
            8'h1C: key_ascii = "A";
            8'h32: key_ascii = "B";
            8'h21: key_ascii = "C";
            8'h23: key_ascii = "D";
            8'h24: key_ascii = "E";
            8'h2B: key_ascii = "F";
            8'h34: key_ascii = "G";
            8'h33: key_ascii = "H";
            8'h43: key_ascii = "I";
            8'h3B: key_ascii = "J";
            8'h42: key_ascii = "K";
            8'h4B: key_ascii = "L";
            8'h3A: key_ascii = "M";
            8'h31: key_ascii = "N";
            8'h44: key_ascii = "O";
            8'h4D: key_ascii = "P";
            8'h15: key_ascii = "Q";
            8'h2D: key_ascii = "R";
            8'h1B: key_ascii = "S";
            8'h2C: key_ascii = "T";
            8'h3C: key_ascii = "U";
            8'h2A: key_ascii = "V";
            8'h1D: key_ascii = "W";
            8'h22: key_ascii = "X";
            8'h35: key_ascii = "Y";
            8'h1A: key_ascii = "Z";

            default: key_ascii = 8'h00;
        endcase
    end

endmodule
