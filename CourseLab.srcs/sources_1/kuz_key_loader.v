`timescale 1ns / 1ps

// Принимает исходный ключ на clk_core и вычисляет K1...K10 на clk_keys.
// Через границу проходят два признака транзакции. Шины удерживаются до подтверждения.
// rst_core и rst_keys сбрасывают обе стороны одной транзакции.

module kuz_key_loader (
    input          clk_core,
    input          rst_core,
    input          clk_keys,
    input          rst_keys,

    input  [255:0] start_key_input,
    input          key_input_valid,
    output         key_input_ready,
    output reg     key_update_pending,

    output [1279:0] round_keys,
    output          round_keys_valid,
    input           round_keys_ready
);

    reg [255:0] held_key;
    reg         request_toggle;
    reg         result_toggle;
    reg         submitted;

    (* ASYNC_REG = "TRUE" *) reg [1:0] request_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] result_sync;

    wire schedule_request;
    wire schedule_input_ready;
    wire schedule_keys_ready;

    assign key_input_ready  = !rst_core && !key_update_pending;
    assign round_keys_valid = !rst_core && key_update_pending &&
                              (result_sync[1] == request_toggle);

    assign schedule_request = !rst_keys && !submitted &&
                              (request_sync[1] != result_toggle);


    kuz_key_schedule key_schedule (
        .clk(clk_keys),
        .rst(rst_keys),
        .start_key_input(held_key),
        .key_input_valid(schedule_request),
        .key_input_ready(schedule_input_ready),
        .round_keys_ready(schedule_keys_ready),
        .round_keys(round_keys)
    );


    always @(posedge clk_core) begin
        if (rst_core) begin
            result_sync        <= 2'b0;
            request_toggle     <= 1'b0;
            key_update_pending <= 1'b0;
        end else begin
            result_sync <= {result_sync[0], result_toggle};

            if (key_input_valid && key_input_ready) begin
                held_key           <= start_key_input;
                request_toggle     <= !request_toggle;
                key_update_pending <= 1'b1;
            end else if (round_keys_valid && round_keys_ready) begin
                key_update_pending <= 1'b0;
            end
        end
    end


    always @(posedge clk_keys) begin
        if (rst_keys) begin
            request_sync  <= 2'b0;
            result_toggle <= 1'b0;
            submitted     <= 1'b0;
        end else begin
            request_sync <= {request_sync[0], request_toggle};

            if (schedule_request && schedule_input_ready) begin
                submitted <= 1'b1;
            end else if (submitted && schedule_keys_ready) begin
                // Проверяем готовность после приёма запроса. Для того же ключа она уже равна 1.
                result_toggle <= request_sync[1];
                submitted     <= 1'b0;
            end
        end
    end

endmodule
