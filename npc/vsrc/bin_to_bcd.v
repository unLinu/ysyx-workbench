module bin_to_bcd (
        input   wire    [ 7:0]   bin     ,
        output  wire    [11:0]   bcd
    );

    /* verilator lint_off UNOPTFLAT */wire    [3:0]   bcd_h[0:15], bcd_t[0:15], bcd_o[0:15];
    wire    [11:0]  bcd_temp[1:8];

    assign bcd = bcd_temp[8];

    // 初始化第0个元素
    assign bcd_h[0] = 4'd0;
    assign bcd_t[0] = 4'd0;
    assign bcd_o[0] = 4'd0;

    // 判断组合
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_check
            assign bcd_h[i*2+1] = (bcd_h[i*2] >= 4'd5) ? (bcd_h[i*2] + 4'd3) : bcd_h[i*2];
            assign bcd_t[i*2+1] = (bcd_t[i*2] >= 4'd5) ? (bcd_t[i*2] + 4'd3) : bcd_t[i*2];
            assign bcd_o[i*2+1] = (bcd_o[i*2] >= 4'd5) ? (bcd_o[i*2] + 4'd3) : bcd_o[i*2];
        end
    endgenerate

    // 合并组合
    genvar j;
    generate
        for (j = 1; j < 9; j = j + 1) begin : gen_merge
            assign bcd_temp[j] = {bcd_h[j*2-1][2:0], bcd_t[j*2-1], bcd_o[j*2-1], bin[8-j]};
        end
    endgenerate

    // 切片组合
    genvar k;
    generate
        for (k = 1; k < 8; k = k + 1) begin : gen_slice
            assign {bcd_h[k*2], bcd_t[k*2], bcd_o[k*2]} = bcd_temp[k];
        end
    endgenerate

endmodule
