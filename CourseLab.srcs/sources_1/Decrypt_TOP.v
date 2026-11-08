`timescale 1ns / 1ps

// Дешифрование 128-битного блока за 43 такта от фронта приёма.
// Интерфейс блока и сообщения совпадает с Encrypt_TOP.
// Сначала разворачиваются ключи, затем идут девять обратных раундов и XOR с K1.

module Decrypt_TOP (
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

    localparam [1:0] IDLE       = 2'd0;
    localparam [1:0] EXPAND_KEY = 2'd1;
    localparam [1:0] INV_ROUNDS = 2'd2;
    localparam [1:0] FINAL_XOR  = 2'd3;

    reg [1:0] state;

    reg [127:0] initial_data;
    reg [127:0] result_data;
    reg         operation_last;

    // Каждое слово хранит соседнюю пару ключей, K1/K2 в ячейке 0.
    reg [255:0] round_key_pairs [0:4];
    reg [5:0]   key_step_count;
    reg [3:0]   round_key_index;     // Индекс K10 равен 9, индекс K2 равен 1.
    integer pair_index;

    wire [255:0] next_key_state;
    wire         key_step_done;
    reg [127:0] current_Ci;

    wire [127:0] round_data_output;
    wire         data_round_done;


    // ========== Развёртывание ключа и обратные раунды ==========

    wire data_input_accept = data_input_valid && data_input_ready;

    wire key_step_enable = !rst && (state == EXPAND_KEY) && (key_step_count < 6'd32);
    wire [255:0] round_key_input = (key_step_count == 0) ? round_key_pairs[0] : next_key_state;

    // После каждого восьмого шага сохраняется готовая пара для обратного обхода.
    wire capture_key_pair = key_step_done && (key_step_count != 0) &&
                            (key_step_count[2:0] == 3'b000);

    wire data_round_enable = !rst && (state == INV_ROUNDS);
    wire [255:0] selected_pair = round_key_pairs[round_key_index[3:1]];
    wire [127:0] current_key = round_key_index[0] ? selected_pair[127:0] : selected_pair[255:128];
    wire [127:0] round_data_input = (round_key_index == 4'd9) ? initial_data : round_data_output;

    assign data_input_ready = !rst && (state == IDLE);
    assign data_output      = result_data;


    // ========== Вычислительные модули ==========

    // При приёме блока выбираем C1, во время F выбираем константу следующего шага.
    wire [5:0] prefetch_Ci_index = data_input_accept ? 6'd1 : key_step_count + 6'd2;
    wire [127:0] prefetched_Ci;

    kuz_round_constant round_constant_lookup (
        .iteration_index(prefetch_Ci_index),
        .iteration_constant(prefetched_Ci)
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

    data_inverse_matrix_onecycle round_data_transform (
        .clk(clk),
        .rst(rst),
        .data_round_enable(data_round_enable),

        .data_input(round_data_input),
        .key_input(current_key),

        .data_output(round_data_output),
        .data_round_done(data_round_done)
    );


    // На одном фронте F фиксирует результат с текущей Ci, а регистр принимает следующую Ci.
    always @(posedge clk) begin
        if (rst)
            current_Ci <= 128'b0;
        else if (data_input_accept || key_step_enable)
            current_Ci <= prefetched_Ci;
    end


    // ========== Управление блоком ==========

    always @(posedge clk) begin
        if (rst) begin
            state             <= IDLE;
            busy_all_message  <= 1'b0;
            operation_last    <= 1'b0;
            initial_data      <= 128'b0;
            result_data       <= 128'b0;
            data_output_valid <= 1'b0;
            data_output_last  <= 1'b0;
            key_step_count    <= 6'd0;
            round_key_index   <= 4'd9;

            for (pair_index = 0; pair_index < 5; pair_index = pair_index + 1)
                round_key_pairs[pair_index] <= 256'b0;
        end else begin
            data_output_valid <= 1'b0;

            case (state)
                IDLE: begin
                    if (data_input_accept) begin
                        state              <= EXPAND_KEY;
                        busy_all_message   <= 1'b1;
                        operation_last     <= data_input_last;
                        initial_data       <= data_input;
                        round_key_pairs[0] <= start_key_input;
                        key_step_count     <= 6'd0;
                        round_key_index    <= 4'd9;
                    end
                end

                EXPAND_KEY: begin
                    if (key_step_enable)
                        key_step_count <= key_step_count + 6'd1;

                    if (capture_key_pair) begin
                        round_key_pairs[key_step_count[5:3]] <= next_key_state;

                        // На t33 сохраняются K9/K10. Обратный тракт стартует на t34.
                        if (key_step_count == 6'd32)
                            state <= INV_ROUNDS;
                    end
                end

                INV_ROUNDS: begin
                    round_key_index <= round_key_index - 4'd1;

                    if (round_key_index == 4'd1)
                        state <= FINAL_XOR;
                end

                FINAL_XOR: begin
                    if (data_round_done) begin
                        result_data       <= round_data_output ^ round_key_pairs[0][255:128];
                        data_output_last  <= operation_last;
                        data_output_valid <= 1'b1;
                        state             <= IDLE;

                        if (operation_last)
                            busy_all_message <= 1'b0;
                    end
                end

                default: begin
                    state            <= IDLE;
                    busy_all_message <= 1'b0;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
