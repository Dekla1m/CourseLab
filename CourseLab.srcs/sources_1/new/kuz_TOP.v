`timescale 1ns / 1ps
`default_nettype none

module kuz_TOP(
    input  wire         clk,
    input  wire         rst,

    input  wire         btn_pulse,

    input  wire [255:0] start_key_input,
    input  wire         key_input_valid,
    output wire         key_input_ready,
    output wire         round_keys_ready,

    input  wire [127:0] data_input,
    input  wire         data_input_valid,
    input  wire         data_input_last,
    output wire         data_input_ready,

    output wire [127:0] data_output,
    output wire         data_output_valid,
    output wire         data_output_last,
    output wire         busy_all_message,

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
    wire key_load_allowed;
    wire schedule_ready;
    wire [3:0] enc_round_key_index;
    wire [3:0] dec_round_key_index;
    wire [3:0] round_key_read_index;
    wire [127:0] round_key;

    assign enc_input_valid = data_input_valid && round_keys_ready && !switch_now && !mode_dec;
    assign dec_input_valid = data_input_valid && round_keys_ready && !switch_now &&  mode_dec;

    assign data_input_ready  = round_keys_ready && !switch_now && (mode_dec ? dec_ready : enc_ready);
    assign data_output       = mode_dec ? dec_data  : enc_data;
    assign data_output_valid = mode_dec ? dec_valid : enc_valid;
    assign data_output_last  = mode_dec ? dec_last  : enc_last;
    assign busy_all_message  = mode_dec ? dec_busy  : enc_busy;

    // Новый набор разрешён между сообщениями. Первый принимаемый блок имеет приоритет.
    assign key_load_allowed = !busy_all_message && !(data_input_valid && data_input_ready);
    assign key_input_ready  = schedule_ready && key_load_allowed;
    assign round_key_read_index = mode_dec ? dec_round_key_index : enc_round_key_index;

    kuz_key_schedule key_schedule (
        .clk(clk),
        .rst(rst),

        .start_key_input(start_key_input),
        .key_input_valid(key_input_valid && key_load_allowed),
        .key_input_ready(schedule_ready),
        .round_keys_ready(round_keys_ready),

        .round_key_read_index(round_key_read_index),
        .round_key_output(round_key)
    );


    Encrypt_TOP encrypter (
        .clk(clk),
        .rst(rst),

        .data_input(data_input),
        .data_input_valid(enc_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(enc_ready),

        .round_key_read_index(enc_round_key_index),
        .round_key_input(round_key),

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

        .round_key_read_index(dec_round_key_index),
        .round_key_input(round_key),

        .data_output(dec_data),
        .data_output_valid(dec_valid),
        .data_output_last(dec_last),
        .busy_all_message(dec_busy)
    );

    reg btn_mode;
    assign switch_now = !rst && !busy_all_message &&
                    (btn_pulse || btn_mode);

    always @(posedge clk) begin
        if (rst) begin
            mode_dec <= 1'b0;
            btn_mode <= 1'b0;
            switch_mode_pulse <= 1'b0;
        end
        else begin
            switch_mode_pulse <= switch_now;
            if (switch_now) begin // Импульс смены
                mode_dec <= !mode_dec;
                btn_mode <= 1'b0;
            end
            else if (btn_pulse) btn_mode <= 1'b1;
        end
    end

endmodule

`default_nettype wire
