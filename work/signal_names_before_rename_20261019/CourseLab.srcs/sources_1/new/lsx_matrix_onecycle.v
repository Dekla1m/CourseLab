// Registered encryption round: L(S(a XOR k)).
// Byte order: MSB on the left.
`timescale 1ns/1ps
module data_matrix_onecycle (
    input wire clk, rst, start,
    input wire [127:0] a, k,
    output reg [127:0] y,
    output reg done
);
    wire [127:0] lsx;
    kuz_lsx_matrix_comb datapath (.a(a), .k(k), .y(lsx));
    always @(posedge clk) begin
        if (rst) begin
            y <= 128'b0;
            done <= 1'b0;
        end else begin
            done <= start;
            if (start) y <= lsx;
        end
    end
endmodule
