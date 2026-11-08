`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.10.2026 23:11:07
// Design Name: 
// Module Name: testMatrix
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Multiplication in GF(2^8), p(x) = x^8 + x^7 + x^6 + x + 1.
// COEFF is fixed at elaboration/synthesis time, not a runtime input.
// Present a after clock edge N; y is updated at edge N+1.
// No reset: y is undefined until the first rising clock edge.
`timescale 1ns/1ps

module testMatrix #(
    parameter [7:0] COEFF = 8'h94
) (
    input  wire       clk,
    input  wire [7:0] a,
    output reg  [7:0] y
);

    // Build the binary multiplication matrix at elaboration time.
    // Column i is COEFF * x^i reduced modulo the field polynomial.
    // Row j specifies which input bits contribute to output bit j.
    function automatic [63:0] build_matrix(input [7:0] coefficient);
        reg [7:0] column;
        integer input_bit;
        integer output_bit;
        begin
            build_matrix = 64'b0;
            column = coefficient;
            for (input_bit = 0; input_bit < 8; input_bit = input_bit + 1) begin
                for (output_bit = 0; output_bit < 8; output_bit = output_bit + 1) begin
                    build_matrix[8 * output_bit + input_bit] = column[output_bit];
                end
                // Reduction after multiplication by x (02).
                // The old column[7] is used, before it is discarded.
                column = {column[6:0], 1'b0}
                       ^ (column[7] ? 8'hC3 : 8'h00);
            end
        end
    endfunction

    localparam [63:0] MATRIX = build_matrix(COEFF);
    wire [7:0] product;

    genvar output_bit;
    generate
        for (output_bit = 0; output_bit < 8; output_bit = output_bit + 1) begin : g_output
            localparam [7:0] ROW_MASK = MATRIX[8 * output_bit +: 8];
            // & selects contributing input bits; unary ^ XORs those bits.
            assign product[output_bit] = ^(a & ROW_MASK);
        end
    endgenerate

    // All eight product bits are computed in parallel and registered.
    always @(posedge clk) begin
        y <= product;
    end

endmodule

