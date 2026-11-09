`timescale 1ns / 1ps

// Дешифрование 128-битных блоков с готовым набором ключей.
// Внутри сообщения конвейер принимает по одному блоку за такт.

module Decrypt_TOP (
    input           clk,
    input           rst,

    input  [127:0]  data_input,
    input           data_input_valid,
    input           data_input_last,
    output          data_input_ready,

    input  [1279:0] round_keys,

    output [127:0]  data_output,
    output          data_output_valid,
    output          data_output_last,
    output          busy_all_message
);

    kuz_round_pipeline #(
        .DECRYPT(1'b1)
    ) pipeline (
        .clk(clk),
        .rst(rst),

        .data_input(data_input),
        .data_input_valid(data_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(data_input_ready),

        .round_keys(round_keys),

        .data_output(data_output),
        .data_output_valid(data_output_valid),
        .data_output_last(data_output_last),
        .busy_all_message(busy_all_message)
    );

endmodule
