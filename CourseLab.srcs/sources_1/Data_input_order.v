`timescale 1ns / 1ps

module Data_input_order(
    input clk, rst, mode,
    input [9:0] TX_DATA,
    input TX_VALID,
    output TX_READY,
    input packet_accept,
    output reg [127:0] packet,
    output reg packet_valid,
    output reg packet_noerr,
    output reg packet_last
    );

    reg [127:0] packet_buffer;
    reg [4:0] counter_len_packet;
    reg [3:0] state;
    reg [7:0] exception_byte;
    reg exception_byte_ready;
    reg message_valid;

    localparam IDLE = 0, PACKET_READ_LF = 1,
        MIDDLE_STATE_EXCEPTION = 2, PACKET_PADDING = 3,
        PACKET_OUTPUT = 4;

    wire check_byte;
    assign check_byte = !TX_DATA[8] && !TX_DATA[9];
    assign TX_READY = !rst &&
                      (state == IDLE || state == PACKET_READ_LF);

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            packet <= 128'b0;
            packet_buffer <= 128'b0;
            packet_valid <= 1'b0;
            packet_noerr <= 1'b0;
            packet_last <= 1'b0;
            counter_len_packet <= 5'd0;
            exception_byte <= 8'b0;
            exception_byte_ready <= 1'b0;
            message_valid <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    if (TX_VALID && TX_READY) begin
                        message_valid <= message_valid && check_byte;

                        if (TX_DATA[7:0] == 8'h0D) begin
                            state <= PACKET_READ_LF;
                        end else if (counter_len_packet == 5'd15) begin
                            packet <= {packet_buffer[119:0], TX_DATA[7:0]};
                            packet_noerr <= message_valid && check_byte;
                            packet_last <= 1'b0;
                            packet_valid <= 1'b1;
                            packet_buffer <= 128'b0;
                            counter_len_packet <= 5'd0;
                            state <= PACKET_OUTPUT;
                        end else begin
                            packet_buffer <= {packet_buffer[119:0], TX_DATA[7:0]};
                            counter_len_packet <= counter_len_packet + 5'd1;
                        end
                    end
                end

                PACKET_READ_LF: begin
                    if (TX_VALID && TX_READY) begin
                        message_valid <= message_valid && check_byte;

                        if (TX_DATA[7:0] == 8'h0A) begin
                            if (counter_len_packet == 5'd15) begin
                                packet <= {packet_buffer[119:0], 8'h80};
                                packet_noerr <= message_valid && check_byte;
                                packet_last <= 1'b1;
                                packet_valid <= 1'b1;
                                packet_buffer <= 128'b0;
                                counter_len_packet <= 5'd0;
                                state <= PACKET_OUTPUT;
                            end else begin
                                packet_buffer <= {packet_buffer[119:0], 8'h80};
                                counter_len_packet <= counter_len_packet + 5'd1;
                                state <= PACKET_PADDING;
                            end
                        end else begin
                            exception_byte <= TX_DATA[7:0];
                            exception_byte_ready <= 1'b1;

                            if (counter_len_packet == 5'd15) begin
                                packet <= {packet_buffer[119:0], 8'h0D};
                                packet_noerr <= message_valid && check_byte;
                                packet_last <= 1'b0;
                                packet_valid <= 1'b1;
                                packet_buffer <= 128'b0;
                                counter_len_packet <= 5'd0;
                                state <= PACKET_OUTPUT;
                            end else begin
                                packet_buffer <= {packet_buffer[119:0], 8'h0D};
                                counter_len_packet <= counter_len_packet + 5'd1;
                                state <= MIDDLE_STATE_EXCEPTION;
                            end
                        end
                    end
                end

                MIDDLE_STATE_EXCEPTION: begin
                    exception_byte_ready <= 1'b0;

                    if (exception_byte == 8'h0D) begin
                        state <= PACKET_READ_LF;
                    end else if (counter_len_packet == 5'd15) begin
                        packet <= {packet_buffer[119:0], exception_byte};
                        packet_noerr <= message_valid;
                        packet_last <= 1'b0;
                        packet_valid <= 1'b1;
                        packet_buffer <= 128'b0;
                        counter_len_packet <= 5'd0;
                        state <= PACKET_OUTPUT;
                    end else begin
                        packet_buffer <= {packet_buffer[119:0], exception_byte};
                        counter_len_packet <= counter_len_packet + 5'd1;
                        state <= IDLE;
                    end
                end

                PACKET_PADDING: begin
                    if (counter_len_packet == 5'd15) begin
                        packet <= {packet_buffer[119:0], 8'h00};
                        packet_noerr <= message_valid;
                        packet_last <= 1'b1;
                        packet_valid <= 1'b1;
                        packet_buffer <= 128'b0;
                        counter_len_packet <= 5'd0;
                        state <= PACKET_OUTPUT;
                    end else begin
                        packet_buffer <= {packet_buffer[119:0], 8'h00};
                        counter_len_packet <= counter_len_packet + 5'd1;
                    end
                end

                PACKET_OUTPUT: begin
                    if (packet_accept) begin
                        packet_valid <= 1'b0;

                        if (packet_last) begin
                            message_valid <= 1'b1;
                        end

                        if (exception_byte_ready) begin
                            state <= MIDDLE_STATE_EXCEPTION;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                default: begin
                    state <= IDLE;
                    packet_buffer <= 128'b0;
                    counter_len_packet <= 5'd0;
                    exception_byte_ready <= 1'b0;
                    message_valid <= 1'b0;
                    packet_valid <= 1'b0;
                    packet_noerr <= 1'b0;
                    packet_last <= 1'b0;
                end
            endcase
        end
    end
endmodule
