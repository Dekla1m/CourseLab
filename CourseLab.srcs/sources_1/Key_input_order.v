`timescale 1ns / 1ps

// Вход подключается к read_valid/read_ready FIFO: TX_VALID означает доступное слово.
// В HOLD_RESULT вход остановлен, а key/key_noerr/key_valid хранятся до подтверждения.
// key_valid отмечает завершённый разбор, в том числе ошибочный: получатель проверяет key_noerr.
// mode пока не используется: ключ вводится как 64 HEX-символа с CRLF.

module Key_input_order(
    input clk, rst, mode,
    input [9:0] TX_DATA,
    input TX_VALID,
    input key_ready_receiver,
    output reg [255:0] key,
    output reg key_valid, 
    output reg key_noerr,
    output     TX_READY
    );

    localparam IDLE = 0, KEY_BIT_INPUT = 1,
        KEY_READ_CR = 2, KEY_READ_LF = 3, HOLD_RESULT = 4;


    reg [5:0] counter_len_key;
    reg [3:0] state;
    wire [3:0] TX_DATA_HEX;
    wire TX_DATA_HEX_valid;
    
    KM_ASCII_TO_HEX converter (
        .ASCII(TX_DATA[7:0]),
        .HEX(TX_DATA_HEX),
        .HEX_FLAG(TX_DATA_HEX_valid)
    );
    
    wire check_byte;
    assign check_byte = !TX_DATA[8] && !TX_DATA[9];
    assign TX_READY = !rst &&
                  (
                      state == IDLE         ||
                      state == KEY_BIT_INPUT ||
                      state == KEY_READ_CR  ||
                      state == KEY_READ_LF
                  );
   
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;

            key <= 256'b0;

            key_valid <= 1'b0;
            key_noerr <= 1'b1;

            counter_len_key <= 6'd0;
        end else begin

            case (state)
                IDLE: begin
                    if (TX_VALID && TX_READY) begin
                        key_valid <= 1'b0;
                        if (TX_DATA[7:0] == 8'h0D) begin
                            key <= 256'b0;
                            key_noerr <= 1'b0;
                            counter_len_key <= 6'd0;
                            state <= KEY_READ_LF;
                        end else begin
                            key <= {252'b0, TX_DATA_HEX};
                            key_noerr <= check_byte && TX_DATA_HEX_valid;
                            counter_len_key <= 6'd1;
                            state <= KEY_BIT_INPUT;
                        end
                    end
                end
                
                KEY_BIT_INPUT: begin
                    if (TX_VALID && TX_READY) begin
                        if (TX_DATA[7:0] == 8'h0D) begin
                            key_noerr <= 1'b0;
                            state <= KEY_READ_LF;
                        end else begin
                            key <= {key[251:0], TX_DATA_HEX};
                            key_noerr <= key_noerr && check_byte && TX_DATA_HEX_valid;
                            counter_len_key <= counter_len_key + 6'd1;
                
                            if (counter_len_key == 6'd63) begin
                                state <= KEY_READ_CR;
                            end
                        end
                    end
                end

                KEY_READ_CR: begin
                    if (TX_VALID && TX_READY) begin
                        key_noerr <= key_noerr && check_byte && (TX_DATA[7:0] == 8'h0D);

                        if (TX_DATA[7:0] == 8'h0D) begin
                            state <= KEY_READ_LF;
                        end
                    end
                end

                KEY_READ_LF: begin
                    if (TX_VALID && TX_READY) begin
                        if (TX_DATA[7:0] == 8'h0A) begin
                            key_noerr <= key_noerr && check_byte;
                            key_valid <= 1'b1;
                            counter_len_key <= 6'd0;
                            state <= HOLD_RESULT;
                        end else begin
                            key_noerr <= 1'b0;
                
                            if (TX_DATA[7:0] != 8'h0D) begin
                                state <= KEY_READ_CR;
                            end
                        end
                    end
                end
                
                HOLD_RESULT: begin
                    if (key_valid && key_ready_receiver) begin
                        key_valid <= 1'b0;
                        state <= IDLE;
                    end
                
                end

                default: begin
                    state <= IDLE;
                    key_noerr <= 1'b0;
                    counter_len_key <= 6'd0;
                end
            endcase
        end
    end
endmodule