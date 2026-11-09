`timescale 1ns / 1ps

// Четыре зарегистрированные стадии одного раунда.
// На первом фронте фиксируется XOR с ключом. На четвёртом появляется результат.

module kuz_round_fourcycle #(
    parameter DECRYPT = 1'b0
) (
    input               clk,
    input               rst,
    input               data_round_enable,

    input       [127:0] data_input,
    input       [127:0] key_input,

    output reg  [127:0] data_output,
    output reg          data_round_done
);

    reg [127:0] stage_x;
    reg [127:0] stage_2;
    reg [127:0] stage_3;
    reg [2:0]   stage_valid;

    wire [127:0] next_stage_2;
    wire [127:0] next_stage_3;
    wire [127:0] next_stage_4;


    generate
        if (DECRYPT) begin : inverse
            kuz_r8_matrix_comb #(
                .INVERSE(1'b1)
            ) linear_first (
                .data_input(stage_x),
                .data_output(next_stage_2)
            );

            kuz_r8_matrix_comb #(
                .INVERSE(1'b1)
            ) linear_second (
                .data_input(stage_2),
                .data_output(next_stage_3)
            );

            kuz_inverse_sbox_comb substitution (
                .data_input(stage_3),
                .data_output(next_stage_4)
            );
        end else begin : forward
            kuz_sbox_comb substitution (
                .data_input(stage_x),
                .data_output(next_stage_2)
            );

            kuz_r8_matrix_comb linear_first (
                .data_input(stage_2),
                .data_output(next_stage_3)
            );

            kuz_r8_matrix_comb linear_second (
                .data_input(stage_3),
                .data_output(next_stage_4)
            );
        end
    endgenerate


    always @(posedge clk) begin
        if (rst) begin
            stage_x         <= 128'b0;
            stage_2         <= 128'b0;
            stage_3         <= 128'b0;
            stage_valid     <= 3'b0;
            data_output     <= 128'b0;
            data_round_done <= 1'b0;
        end else begin
            stage_valid     <= {stage_valid[1:0], data_round_enable};
            data_round_done <= stage_valid[2];

            if (data_round_enable)
                stage_x <= data_input ^ key_input;

            if (stage_valid[0])
                stage_2 <= next_stage_2;

            if (stage_valid[1])
                stage_3 <= next_stage_3;

            if (stage_valid[2])
                data_output <= next_stage_4;
        end
    end

endmodule
