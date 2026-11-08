`timescale 1ns / 1ps

module kuz_TOP(
    input          clk,
    input          rst,

    input          btn_pulse,

    input  [127:0] data_input,
    input  [255:0] start_key_input,
    input          data_input_valid,
    input          data_input_last,
    output         data_input_ready,

    output [127:0] data_output,
    output         data_output_valid,
    output         data_output_last,
    output         busy_all_message,
    
    output reg switch_mode_pulse // Сигнал о смене ключа
    );
    
    reg mode_dec;
    wire dec_ready, dec_valid, dec_last, dec_busy;
    wire enc_ready, enc_valid, enc_last, enc_busy;
    wire [127:0] dec_data;
    wire [127:0] enc_data;
    
    assign enc_input_valid = data_input_valid && !switch_now && !mode_dec;
    assign dec_input_valid = data_input_valid && !switch_now &&  mode_dec;
    
    assign data_input_ready = !switch_now && (mode_dec ? dec_ready : enc_ready);
    assign data_output       = mode_dec ? dec_data  : enc_data;
    assign data_output_valid = mode_dec ? dec_valid : enc_valid;
    assign data_output_last  = mode_dec ? dec_last  : enc_last;
    assign busy_all_message  = mode_dec ? dec_busy  : enc_busy;
    
    Encrypt_TOP encrypter (
        .clk(clk),
        .rst(rst),
        
        .data_input(data_input),
        .start_key_input(start_key_input),
        .data_input_valid(enc_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(enc_ready),
    
        .data_output(enc_data),
        .data_output_valid(enc_valid),
        .data_output_last(enc_last),
        .busy_all_message(enc_busy)
    );
    
    
    Decrypt_TOP decrypter (
        .clk(clk),
        .rst(rst),
        
        .data_input(data_input),
        .start_key_input(start_key_input),
        .data_input_valid(dec_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(dec_ready),
    
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
