module keyboard (
        input   wire            clk         ,
        input   wire            ps2_clk     ,
        input   wire            ps2_data    ,
        input   wire            srst        ,
        output  reg     [7:0]   key_code
    );

    localparam  IDLE = 0, GET_DATA = 1, GET_PARITY = 2, GET_STOP = 3;

    reg     [1:0]   state, next_state;
    reg     [2:0]   data_cnt;
    reg     [7:0]   packed_data;
    reg             odd_flag;
    reg             ps2_clk_dly;

    wire            ps2_clk_neg;

    assign ps2_clk_neg = ps2_clk_dly & ~ps2_clk;

    always @(posedge clk) begin
        if (srst)
            ps2_clk_dly <= 1'b1;
        else
            ps2_clk_dly <= ps2_clk;
    end

    always @(posedge clk) begin
        if (srst)
            state <= IDLE;
        else if (ps2_clk_neg)
            state <= next_state;
    end

    always @(*) begin
        case (state)
            IDLE:
                next_state = ~ps2_data ? GET_DATA : IDLE;
            GET_DATA:
                next_state = (data_cnt == 3'd7) ? GET_PARITY : GET_DATA;
            GET_PARITY:
                next_state = GET_STOP;
            GET_STOP:
                next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (srst)
            data_cnt <= 3'd0;
        else if (ps2_clk_neg) begin
            if (state == GET_DATA)
                data_cnt <= data_cnt + 3'd1;
            else
                data_cnt <= 3'd0;
        end
    end


    always @(posedge clk) begin
        if (srst)
            packed_data <= 8'd0;
        else if (ps2_clk_neg) begin
            if (state == GET_DATA)
                packed_data <= {ps2_data, packed_data[7:1]};
            else
                packed_data <= packed_data;
        end
    end

    always @(posedge clk) begin
        if (srst)
            key_code <= 8'd0;
        else if (ps2_clk_neg) begin
            if (state == GET_STOP)
                key_code <= packed_data;
        end
    end

    always @(posedge clk) begin
        if (srst)
            odd_flag <= 1'b0;
        else if (ps2_clk_neg) begin
            if (state == GET_DATA || state == GET_PARITY)
                odd_flag <= ps2_data ? ~odd_flag : odd_flag;
            else
                odd_flag <= 1'b0;
        end
    end


endmodule
