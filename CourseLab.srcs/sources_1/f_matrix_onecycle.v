`timescale 1ns / 1ps

// Один шаг развёртывания ключа F: (L(S(A XOR Ci)) XOR B, A).
// Разрешение захватывает результат на фронте. При запусках подряд done остаётся высоким.
// При паузе пара сохраняется, done снимается. Сброс синхронный.

module key_matrix_onecycle (
    input         clk,
                  rst,
                  key_step_enable,

    input [127:0] key_left_input,
                  key_right_input,
    input [127:0] iteration_constant_input,

    output reg [127:0] key_left_output,
                       key_right_output,
    output reg         key_step_done
);

    wire [127:0] round_result;

    // На вход LSX вместо раундового ключа подаётся константа шага Ci.
    kuz_lsx_matrix_comb round_transform (
        .data_input(key_left_input),
        .key_input(iteration_constant_input),
        .data_output(round_result)
    );


    always @(posedge clk) begin
        if (rst) begin
            key_left_output  <= 128'b0;
            key_right_output <= 128'b0;
            key_step_done    <= 1'b0;
        end else begin
            key_step_done <= key_step_enable;

            if (key_step_enable) begin
                key_left_output  <= round_result ^ key_right_input;
                key_right_output <= key_left_input;
            end
        end
    end

endmodule
