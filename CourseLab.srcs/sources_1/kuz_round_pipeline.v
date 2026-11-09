`timescale 1ns / 1ps

// Входной регистр, девять раундов и финальный XOR.
// Банк держит K1...K10 стабильными на протяжении сообщения.

module kuz_round_pipeline #(
    parameter DECRYPT = 1'b0
)(
    input                clk,
    input                rst,

    input       [127:0]  data_input,
    input                data_input_valid,
    input                data_input_last,
    output               data_input_ready,

    input       [1279:0] round_keys,

    output reg  [127:0]  data_output,
    output reg           data_output_valid,
    output reg           data_output_last,
    output reg           busy_all_message
);

    localparam integer ROUNDS = 9;
    localparam integer FINAL_KEY_INDEX = DECRYPT ? 0 : ROUNDS;

    reg [127:0] input_data;
    reg         input_valid;
    reg [ROUNDS:0] stage_last;
    reg         draining_message; // Закрывает вход от приёма last до его выдачи.

    wire [127:0] stage_data [0:ROUNDS];
    wire [ROUNDS:0] stage_valid;
    wire data_input_accept;

    assign data_input_ready  = !rst && !draining_message;
    assign data_input_accept = data_input_valid && data_input_ready;

    assign stage_data[0]  = input_data;
    assign stage_valid[0] = input_valid;


    genvar stage;
    generate
        for (stage = 0; stage < ROUNDS; stage = stage + 1) begin : rounds
            localparam integer KEY_INDEX = DECRYPT ? ROUNDS - stage : stage;
            wire [127:0] round_key = round_keys[1279 - 128*KEY_INDEX -: 128];

            if (DECRYPT) begin : inverse
                data_inverse_matrix_onecycle transform (
                    .clk(clk),
                    .rst(rst),
                    .data_round_enable(stage_valid[stage]),
                    .data_input(stage_data[stage]),
                    .key_input(round_key),
                    .data_output(stage_data[stage+1]),
                    .data_round_done(stage_valid[stage+1])
                );
            end else begin : forward
                data_matrix_onecycle transform (
                    .clk(clk),
                    .rst(rst),
                    .data_round_enable(stage_valid[stage]),
                    .data_input(stage_data[stage]),
                    .key_input(round_key),
                    .data_output(stage_data[stage+1]),
                    .data_round_done(stage_valid[stage+1])
                );
            end
        end
    endgenerate


    always @(posedge clk) begin
        if (rst) begin
            input_data        <= 128'b0;
            input_valid       <= 1'b0;
            stage_last        <= 0;
            draining_message  <= 1'b0;
            busy_all_message  <= 1'b0;

            data_output       <= 128'b0;
            data_output_valid <= 1'b0;
            data_output_last  <= 1'b0;
        end else begin
            input_valid <= data_input_accept;

            // Метка проходит те же стадии, что и valid. Пустой слот получает last=0.
            stage_last <= {stage_last[ROUNDS-1:0], data_input_accept && data_input_last};

            if (data_input_accept) begin
                input_data       <= data_input;
                busy_all_message <= 1'b1;

                if (data_input_last)
                    draining_message <= 1'b1;
            end

            data_output_valid <= stage_valid[ROUNDS];

            if (stage_valid[ROUNDS]) begin
                data_output      <= stage_data[ROUNDS] ^ round_keys[1279 - 128*FINAL_KEY_INDEX -: 128];
                data_output_last <= stage_last[ROUNDS];

                if (stage_last[ROUNDS]) begin
                    draining_message <= 1'b0;
                    busy_all_message <= 1'b0;
                end
            end
        end
    end

endmodule
