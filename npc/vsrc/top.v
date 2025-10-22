module top (
        input   wire            clk,
        input   wire            rst,
        output  wire    [15:0]  led
    );
    // output declaration of module light

    light u_light(
              .clk 	(clk  ),
              .rst 	(rst  ),
              .led 	(led  )
          );

endmodule
