`timescale 1ns / 1ps

// Стенд одного раунда для измерения внутренних путей.
// Четыре загрузки от старшего слова к младшему задают все биты данных и ключа.

module test_impl_round_fourcycle #(
    parameter DECRYPT = 1'b1
) (
    input         clk,
    input         rst,

    input  [31:0] data_word,
    input  [31:0] key_word,
    input         load_word,
    input         round_valid,

    input  [1:0]  result_word_index,
    output [31:0] result_word,
    output        result_valid
);

    reg [127:0] data_buffer;
    reg [127:0] key_buffer;
    wire [127:0] result_block;

    // Индекс 0 выбирает старшее слово. Все 128 бит результата доступны с выводов.
    assign result_word = result_block[127-32*result_word_index -: 32];

    always @(posedge clk) begin
        if (rst) begin
            data_buffer <= 128'b0;
            key_buffer  <= 128'b0;
        end else if (load_word) begin
            data_buffer <= {data_buffer[95:0], data_word};
            key_buffer  <= {key_buffer[95:0], key_word};
        end
    end

    kuz_round_fourcycle #(
        .DECRYPT(DECRYPT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_round_enable(round_valid),
        .data_input(data_buffer),
        .key_input(key_buffer),
        .data_output(result_block),
        .data_round_done(result_valid)
    );

endmodule
