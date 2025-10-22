module top (
        input   wire    [1:0]   Y,
        input   wire    [1:0]   X0,
        input   wire    [1:0]   X1,
        input   wire    [1:0]   X2,
        input   wire    [1:0]   X3,
        output  reg     [1:0]   F
    );


    mux4to1 u_mux4to1(
                .Y  	(Y   ),
                .X0 	(X0  ),
                .X1 	(X1  ),
                .X2 	(X2  ),
                .X3 	(X3  ),
                .F  	(F   )
            );


endmodule
