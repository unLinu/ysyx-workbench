module top (
        input   wire    [7:0]   in,
        output  wire            valid,  // 是否有输入
        output  reg     [2:0]   led,
        output  reg     [7:0]   seg
    );

    encoder u_encoder(
                .in    	(in     ),
                .valid 	(valid  ),
                .led   	(led    ),
                .seg   	(seg    )
            );

endmodule
