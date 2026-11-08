// Registered Feistel step: (L(S(a XOR k)) XOR b, a).
// Byte order: MSB on the left.
`timescale 1ns/1ps
module key_matrix_onecycle (
    input wire clk, rst, start,
    input wire [127:0] a, b, k,
    output reg [127:0] a_next, b_next,
    output reg done
);
    wire [127:0] lsx;
    kuz_lsx_matrix_comb datapath (.a(a), .k(k), .y(lsx));
    always @(posedge clk) begin
        if (rst) begin
            a_next <= 128'b0;
            b_next <= 128'b0;
            done <= 1'b0;
        end else begin
            done <= start;
            if (start) begin
                a_next <= lsx ^ b;
                b_next <= a;
            end
        end
    end
endmodule
