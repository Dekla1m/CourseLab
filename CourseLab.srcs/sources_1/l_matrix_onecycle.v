`timescale 1ns/1ps

module l_matrix_onecycle (
    input wire clk,
    input wire rst,
    input wire data_input_r,
    input wire [127:0] data_input,
    output reg [127:0] data_output,
    output reg data_output_r
);
    wire [127:0] linear_result;
    l_matrix_comb l_transform (.data_input(data_input), .data_output(linear_result));

    always @(posedge clk) begin
        if (rst) begin
            data_output <= 128'b0;
            data_output_r <= 1'b0;
        end else begin
            data_output_r <= data_input_r;
            if (data_input_r)
                data_output <= linear_result;
        end
    end
endmodule
