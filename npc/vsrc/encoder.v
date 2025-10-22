module encoder (
        input   wire    [7:0]   in,
        output  wire            valid,  // 是否有输入
        output  reg     [2:0]   led,
        output  reg     [7:0]   seg
    );

    assign valid = in == 8'd0 ? 1'b0 : 1'b1;

    always @(*) begin
        casez (in)
            8'b1zzz_zzzz: led = 3'd7;
            8'b01zz_zzzz: led = 3'd6;
            8'b001z_zzzz: led = 3'd5;
            8'b0001_zzzz: led = 3'd4;
            8'b0000_1zzz: led = 3'd3;
            8'b0000_01zz: led = 3'd2;
            8'b0000_001z: led = 3'd1;
            8'b0000_0001: led = 3'd0; 
            default: led = 3'd0;
        endcase
    end

    always @(*) begin
        case (led)
            3'd7: seg = 8'h1f;
            3'd6: seg = 8'h41;
            3'd5: seg = 8'h49;
            3'd4: seg = 8'h99;
            3'd3: seg = 8'h0d;
            3'd2: seg = 8'h25;
            3'd1: seg = 8'h9f;
            3'd0: seg = 8'h03;
            default: seg = 8'h11;
        endcase
    end

endmodule
