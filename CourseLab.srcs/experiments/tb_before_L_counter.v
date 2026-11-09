`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.10.2026 23:12:22
// Design Name: 
// Module Name: tb
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


`timescale 1ns/1ps

module tb;
    reg clk;
    reg [7:0] a;
    wire [7:0] y [0:7];

    function automatic [7:0] coefficient_at(input integer index);
        begin
            case (index)
                0: coefficient_at = 8'd1;
                1: coefficient_at = 8'd16;
                2: coefficient_at = 8'd32;
                3: coefficient_at = 8'd133;
                4: coefficient_at = 8'd148;
                5: coefficient_at = 8'd192;
                6: coefficient_at = 8'd194;
                7: coefficient_at = 8'd251;
                default: coefficient_at = 8'd0;
            endcase
        end
    endfunction

    // Independent reference: polynomial product, then long division.
    // It does not use build_matrix, xtime or precomputed contributions.
    function automatic [7:0] reference_mult(
        input [7:0] left,
        input [7:0] right
    );
        reg [14:0] polynomial;
        integer bit_index;
        integer degree;
        begin
            polynomial = 15'b0;
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                if (right[bit_index])
                    polynomial = polynomial ^ ({7'b0, left} << bit_index);
            for (degree = 14; degree >= 8; degree = degree - 1)
                if (polynomial[degree])
                    polynomial = polynomial ^ (15'h1C3 << (degree - 8));
            reference_mult = polynomial[7:0];
        end
    endfunction

    genvar coefficient_index;
    generate
        for (coefficient_index = 0; coefficient_index < 8;
             coefficient_index = coefficient_index + 1) begin : g_dut
            testMatrix #(
                .COEFF(coefficient_at(coefficient_index))
            ) dut (
                .clk(clk),
                .a(a),
                .y(y[coefficient_index])
            );
        end
    endgenerate

    // 200 MHz clock. This is a functional simulation, not a timing proof.
    initial clk = 1'b0;
    always #2.5 clk = ~clk;

    integer value;
    integer index;
    integer checks;
    reg [7:0] expected;
    reg [7:0] previous [0:7];

    initial begin
        a = 8'h00;
        checks = 0;
        // Let the output registers initialize through a clock edge.
        @(posedge clk);
        #0.01;

        for (value = 0; value < 256; value = value + 1) begin
            @(negedge clk);
            for (index = 0; index < 8; index = index + 1)
                previous[index] = y[index];
            a = value;
            #1;

            // Changing a must not change registered outputs before posedge.
            for (index = 0; index < 8; index = index + 1)
                if (y[index] !== previous[index])
                    $fatal(1, "Output changed without posedge: coefficient=%0d",
                           coefficient_at(index));

            @(posedge clk);
            #0.01;
            for (index = 0; index < 8; index = index + 1) begin
                expected = reference_mult(a, coefficient_at(index));
                if (y[index] !== expected)
                    $fatal(1, "Mismatch: a=%02h coefficient=%0d actual=%02h expected=%02h",
                           a, coefficient_at(index), y[index], expected);
                checks = checks + 1;
            end
        end
        $display("PASS: %0d products; registered output checked.", checks);
        $finish;
    end
endmodule

