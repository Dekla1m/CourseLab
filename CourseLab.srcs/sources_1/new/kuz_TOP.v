`timescale 1ns / 1ps

module kuz_TOP(
    input          clk,
    input          rst,

    input          btn_pulse,

    input  [1279:0] round_keys_input,
    input           round_keys_input_valid,
    output          round_keys_input_ready,
    input           key_update_pending,
    output          key_update_allowed,
    output          round_keys_ready,

    input  [127:0] data_input,
    input          data_input_valid,
    input          data_input_last,
    output         data_input_ready,

    output [127:0] data_output,
    output         data_output_valid,
    output         data_output_last,
    output         busy_all_message,

    output reg switch_mode_pulse // Импульс при смене ENC/DEC.
    );

    reg mode_dec;
    wire dec_ready, dec_valid, dec_last, dec_busy;
    wire enc_ready, enc_valid, enc_last, enc_busy;
    wire [127:0] dec_data;
    wire [127:0] enc_data;

    wire switch_now;
    wire enc_input_valid;
    wire dec_input_valid;
    reg [1279:0] active_round_keys;
    reg          keys_loaded;
    reg          btn_mode;

    assign round_keys_ready = !rst && keys_loaded && !key_update_pending;
    assign round_keys_input_ready = !rst && key_update_pending && !busy_all_message;

    assign enc_input_valid = data_input_valid && round_keys_ready && !switch_now && !mode_dec;
    assign dec_input_valid = data_input_valid && round_keys_ready && !switch_now &&  mode_dec;

    assign data_input_ready  = round_keys_ready && !switch_now && (mode_dec ? dec_ready : enc_ready);
    assign data_output       = mode_dec ? dec_data  : enc_data;
    assign data_output_valid = mode_dec ? dec_valid : enc_valid;
    assign data_output_last  = mode_dec ? dec_last  : enc_last;
    assign busy_all_message  = mode_dec ? dec_busy  : enc_busy;

    // Если первый блок уже принимается, обновление ждёт конца сообщения.
    assign key_update_allowed = !rst && !key_update_pending && !busy_all_message &&
                                !(data_input_valid && data_input_ready);

    // Активный набор обновляется целиком. После сброса он закрыт флагом keys_loaded.
    always @(posedge clk) begin
        if (rst)
            keys_loaded <= 1'b0;
        else if (round_keys_input_valid && round_keys_input_ready) begin
            active_round_keys <= round_keys_input;
            keys_loaded       <= 1'b1;
        end
    end


    Encrypt_TOP encrypter (
        .clk(clk),
        .rst(rst),

        .data_input(data_input),
        .data_input_valid(enc_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(enc_ready),

        .round_keys(active_round_keys),

        .data_output(enc_data),
        .data_output_valid(enc_valid),
        .data_output_last(enc_last),
        .busy_all_message(enc_busy)
    );


    Decrypt_TOP decrypter (
        .clk(clk),
        .rst(rst),

        .data_input(data_input),
        .data_input_valid(dec_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(dec_ready),

        .round_keys(active_round_keys),

        .data_output(dec_data),
        .data_output_valid(dec_valid),
        .data_output_last(dec_last),
        .busy_all_message(dec_busy)
    );

    assign switch_now = !rst && !busy_all_message && (btn_pulse || btn_mode);

    always @(posedge clk) begin
        if (rst) begin
            mode_dec <= 1'b0;
            btn_mode <= 1'b0;
            switch_mode_pulse <= 1'b0;
        end
        else begin
            switch_mode_pulse <= switch_now;
            if (switch_now) begin
                mode_dec <= !mode_dec;
                btn_mode <= 1'b0;
            end
            else if (btn_pulse) btn_mode <= 1'b1;
        end
    end

endmodule
