module LFSR (
        input   wire            botton_clk      ,
        input   wire            rst             ,
        output  reg     [7:0]   Q
    );

    always @(posedge botton_clk or posedge rst) begin
        if (rst)
            Q <= 8'd1;
        else 
            Q <= {Q[4] ^ Q[3] ^ Q[2] ^ Q[0], Q[7:1]};
    end

endmodule
