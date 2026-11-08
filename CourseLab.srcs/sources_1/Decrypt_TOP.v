`timescale 1ns / 1ps
`default_nettype none

// Дешифрование 128-битного блока за 10 тактов от приёма.
// Банк ключей выдаёт запрошенный ключ на фронте, начиная с фронта приёма блока.

module Decrypt_TOP (
    input  wire         clk,
    input  wire         rst,

    input  wire [127:0] data_input,
    input  wire         data_input_valid,
    input  wire         data_input_last,
    output wire         data_input_ready,

    output wire [3:0]   round_key_read_index,
    input  wire [127:0] round_key_input,

    output wire [127:0] data_output,
    output reg          data_output_valid,
    output reg          data_output_last,
    output reg          busy_all_message
);

    reg         busy;
    reg         operation_last;
    reg [3:0]   data_round_index;  // Номер ключа текущего раунда, начиная с нуля.
    reg [127:0] initial_data;
    reg [127:0] result_data;

    wire         data_input_accept;
    wire         data_round_enable;
    wire         data_round_done;
    wire [127:0] round_data_input;
    wire [127:0] round_data_output;

    assign data_input_ready  = !rst && !busy;
    assign data_input_accept = data_input_valid && data_input_ready;
    assign data_output       = result_data;

    assign data_round_enable = !rst && busy && (data_round_index != 4'd0);
    assign round_data_input  = (data_round_index == 4'd9) ? initial_data : round_data_output;

    // На фронте текущего раунда банк уже выдаёт ключ для следующего.
    assign round_key_read_index = data_round_enable ? data_round_index - 4'd1 : 4'd9;

    data_inverse_matrix_onecycle round_data_transform (
        .clk(clk),
        .rst(rst),
        .data_round_enable(data_round_enable),
        .data_input(round_data_input),
        .key_input(round_key_input),
        .data_output(round_data_output),
        .data_round_done(data_round_done)
    );


    always @(posedge clk) begin
        if (rst) begin
            busy              <= 1'b0;
            busy_all_message  <= 1'b0;
            operation_last    <= 1'b0;
            data_round_index  <= 4'd9;
            initial_data      <= 128'b0;
            result_data       <= 128'b0;
            data_output_valid <= 1'b0;
            data_output_last  <= 1'b0;
        end else begin
            data_output_valid <= 1'b0;

            if (data_input_accept) begin
                busy             <= 1'b1;
                busy_all_message <= 1'b1;
                operation_last   <= data_input_last;
                data_round_index <= 4'd9;
                initial_data     <= data_input;
            end else if (data_round_enable) begin
                data_round_index <= data_round_index - 4'd1;
            end else if (busy && data_round_done) begin
                result_data       <= round_data_output ^ round_key_input;
                data_output_last  <= operation_last;
                data_output_valid <= 1'b1;

                busy <= 1'b0;
                if (operation_last)
                    busy_all_message <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
