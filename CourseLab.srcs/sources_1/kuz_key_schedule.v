`timescale 1ns / 1ps
`default_nettype none

// Общий набор раундовых ключей для ENC и DEC.
// Чтение синхронное. Индекс 0 соответствует K1, индекс 9 соответствует K10.

module kuz_key_schedule (
    input  wire         clk,
    input  wire         rst,

    input  wire [255:0] start_key_input,
    input  wire         key_input_valid,
    output wire         key_input_ready,
    output reg          round_keys_ready,

    input  wire [3:0]   round_key_read_index,
    output reg  [127:0] round_key_output
);

    reg [255:0] key_pairs [0:4];
    reg         expanding;
    reg         first_key_step;
    reg [5:0]   key_step_count;
    reg [127:0] current_Ci;
    integer pair_index;

    wire         key_update;
    wire         key_step_enable;
    wire         key_step_done;
    wire [255:0] round_key_input;
    wire [255:0] next_key_state;
    wire         capture_key_pair;
    wire [5:0]   prefetch_Ci_index;
    wire [127:0] prefetched_Ci;
    wire [255:0] selected_pair;

    assign key_input_ready = !rst && !expanding;

    // Повторная передача действующего ключа подтверждается сразу.
    assign key_update = key_input_valid && key_input_ready &&
                        (!round_keys_ready || start_key_input != key_pairs[0]);

    assign key_step_enable  = !rst && expanding && (key_step_count < 6'd32);
    assign round_key_input  = first_key_step ? key_pairs[0] : next_key_state;
    assign capture_key_pair = key_step_done && (key_step_count != 6'd0) &&
                              (key_step_count[2:0] == 3'b000);

    // C1 фиксируется вместе с исходным ключом. Далее таблица опережает F на шаг.
    assign prefetch_Ci_index = key_update ? 6'd1 : key_step_count + 6'd2;
    assign selected_pair     = key_pairs[round_key_read_index[3:1]];

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


    always @(posedge clk) begin
        if (rst) begin
            expanding        <= 1'b0;
            first_key_step   <= 1'b0;
            key_step_count   <= 6'd0;
            current_Ci       <= 128'b0;
            round_keys_ready <= 1'b0;

            for (pair_index = 0; pair_index < 5; pair_index = pair_index + 1)
                key_pairs[pair_index] <= 256'b0;
        end else if (key_update) begin
            expanding        <= 1'b1;
            first_key_step   <= 1'b1;
            key_step_count   <= 6'd0;
            current_Ci       <= prefetched_Ci;
            round_keys_ready <= 1'b0;
            key_pairs[0]     <= start_key_input;
        end else if (expanding) begin
            if (key_step_enable) begin
                first_key_step <= 1'b0;
                key_step_count <= key_step_count + 6'd1;
                current_Ci     <= prefetched_Ci;
            end

            // Публикуем набор на том же фронте, на котором сохраняются K9 и K10.
            if (capture_key_pair) begin
                key_pairs[key_step_count[5:3]] <= next_key_state;

                if (key_step_count == 6'd32) begin
                    expanding        <= 1'b0;
                    round_keys_ready <= 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst || !round_keys_ready || round_key_read_index > 4'd9)
            round_key_output <= 128'b0;
        else
            round_key_output <= round_key_read_index[0] ? selected_pair[127:0] :
                                                         selected_pair[255:128];
    end

endmodule

`default_nettype wire
