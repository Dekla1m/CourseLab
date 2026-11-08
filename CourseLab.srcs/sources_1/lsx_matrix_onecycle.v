`timescale 1ns / 1ps

// Один раунд данных: L(S(data_input XOR Ki)). Ключ Ki занимает 128 бит.
// При разрешении результат фиксируется на фронте clk. При паузе выход хранится.
// data_round_done отмечает записанный результат и может быть высоким несколько тактов подряд.

module data_matrix_onecycle (
    input wire         clk,
                       rst,
                       data_round_enable,

    input wire [127:0] data_input,
                       key_input,

    output reg [127:0] data_output,
    output reg         data_round_done
);

    wire [127:0] round_result;

    kuz_lsx_matrix_comb round_transform (
        .data_input(data_input),
        .key_input(key_input),
        .data_output(round_result)
    );


    always @(posedge clk) begin
        if (rst) begin
            data_output     <= 128'b0;
            data_round_done <= 1'b0;
        end else begin
            data_round_done <= data_round_enable;

            if (data_round_enable)
                data_output <= round_result;
        end
    end

endmodule
