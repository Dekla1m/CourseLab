`timescale 1ns / 1ps

// Шифрование одного 128-битного блока за 35 тактов от фронта приёма
// Входные данные, ключ и last фиксируются при valid && ready
// Выходной valid длится один такт. Приёмник заранее обеспечивает место под результат
// busy_all_message охватывает и паузы между блоками, до результата с last=1

module Encrypt_TOP (
    input               clk,
    input               rst,

    input       [127:0] data_input,
    input       [255:0] start_key_input,
    input               data_input_valid,
    input               data_input_last,
    output              data_input_ready,

    output      [127:0] data_output,
    output reg          data_output_valid,
    output reg          data_output_last,
    output reg          busy_all_message
);

    // Регистры блока и последней доступной пары раундовых ключей.
    reg         busy;
    reg         operation_last;      // Метка конца сообщения, захваченная с блоком.
    reg [127:0] initial_data;
    reg [127:0] result_data;
    reg [255:0] current_keys;

    // Счётчики отражают число запусков, а не номер следующего раунда.
    reg [5:0] key_step_count;
    reg [3:0] data_round_count;
    reg [3:0] available_key_count;    // Доступные ключи: сначала два, затем до десяти.

    wire [255:0] next_key_state;      // Пара из выходных регистров F.
    wire         key_step_done;
    wire [127:0] round_data_output;   // Последний результат в выходном регистре LSX.
    wire         data_round_done;

    wire [5:0]   current_Ci_index = key_step_count + 6'd1;
    wire [127:0] current_Ci;


    // ========== Приём и расписание раундов ==========

    wire data_input_accept = data_input_valid && data_input_ready;

    // F продвигается каждый такт, LSX ждёт готовности очередного ключа.
    wire key_step_enable = !rst && busy && (key_step_count < 6'd32);
    wire data_round_enable = !rst && busy &&
                             (data_round_count < 4'd9) &&
                             (data_round_count < available_key_count);

    // После первого запуска оба тракта продолжают с собственного результата.
    wire [255:0] round_key_input = (key_step_count == 0) ? current_keys : next_key_state;
    wire [127:0] round_data_input = (data_round_count == 0) ? initial_data : round_data_output;

    // Чётный счётчик LSX выбирает левую половину пары, нечётный — правую.
    wire [127:0] current_key = data_round_count[0] ? current_keys[127:0] : current_keys[255:128];

    // Пары K3/K4 ... K9/K10 сохраняются после шагов F 8, 16, 24 и 32.
    wire capture_key_pair = busy && key_step_done &&
                            (key_step_count != 0) &&
                            (key_step_count[2:0] == 3'b000);

    assign data_input_ready = !rst && !busy;
    assign data_output      = result_data;


    // ========== Вычислительные модули ==========

    kuz_round_constant round_constant_lookup (
        .iteration_index(current_Ci_index),
        .iteration_constant(current_Ci)
    );

    data_matrix_onecycle round_data_transform (
        .clk(clk),
        .rst(rst),

        .data_round_enable(data_round_enable),
        .data_input(round_data_input),
        .key_input(current_key),

        .data_output(round_data_output),
        .data_round_done(data_round_done)
    );

    key_matrix_onecycle round_key_transform (
        .clk(clk),
        .rst(rst),

        .key_step_enable(key_step_enable),
        .key_left_input(round_key_input[255:128]),
        .key_right_input(round_key_input[127:0]),
        .iteration_constant_input(current_Ci),

        .key_left_output(next_key_state[255:128]),
        .key_right_output(next_key_state[127:0]),
        .key_step_done(key_step_done)
    );


    // ========== Приём блока и обновление регистров ==========

    always @(posedge clk) begin
        if (rst) begin
            busy             <= 1'b0;
            busy_all_message <= 1'b0;
            operation_last   <= 1'b0;

            initial_data <= 128'b0;
            result_data  <= 128'b0;
            current_keys <= 256'b0;

            key_step_count      <= 6'd0;
            data_round_count    <= 4'd0;
            available_key_count <= 4'd0;

            data_output_valid <= 1'b0;
            data_output_last  <= 1'b0;
        end else begin
            data_output_valid <= 1'b0;

            if (!busy) begin
                if (data_input_accept) begin
                    busy             <= 1'b1;
                    busy_all_message <= 1'b1;
                    operation_last   <= data_input_last;

                    initial_data <= data_input;
                    current_keys <= start_key_input;

                    key_step_count      <= 6'd0;
                    data_round_count    <= 4'd0;
                    available_key_count <= 4'd2;
                end
            end else begin
                // F, сохранение пары и LSX могут продвинуться на одном фронте.
                if (key_step_enable)
                    key_step_count <= key_step_count + 6'd1;

                if (capture_key_pair) begin
                    current_keys        <= next_key_state;
                    available_key_count <= available_key_count + 4'd2;
                end

                if (data_round_enable)
                    data_round_count <= data_round_count + 4'd1;

                // LSX9 готов на t34. На t35 фиксируются XOR с K10, last и valid.
                if (data_round_count == 4'd9 && data_round_done) begin
                    result_data       <= round_data_output ^ current_keys[127:0];
                    data_output_last  <= operation_last;
                    data_output_valid <= 1'b1;

                    busy <= 1'b0;
                    if (operation_last)
                        busy_all_message <= 1'b0;
                end
            end
        end
    end

endmodule

`default_nettype wire
