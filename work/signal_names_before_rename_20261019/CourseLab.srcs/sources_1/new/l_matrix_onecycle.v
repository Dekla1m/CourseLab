// Kuznyechik module. One module per source file.
`timescale 1ns/1ps
module l_matrix_onecycle (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [127:0] a,
    output reg [127:0] y,
    output reg done
);
    wire [127:0] product;
    l_matrix_comb linear (.a(a), .product(product));

    always @(posedge clk) begin
        if (rst) begin
            y <= 128'b0;
            done <= 1'b0;
        end else begin
            done <= start;
            if (start)
                y <= product;
        end
    end
endmodule
