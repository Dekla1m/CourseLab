`timescale 1ns / 1ps

module test_impl_IO_low(
    input          clk,
    input          rst,
    
    input          btn_pulse,
    
    input  [31:0] d_input,
    input  [31:0] key_input,
    input          key_input_valid,
    output         key_input_ready,
    output         round_keys_ready,
    output         switch_mode_pulse,
    input          data_input_valid,
    input          data_input_last,
    output         data_input_ready,
    
    output [31:0]  d_output,
    output         data_output_valid,
    output         data_output_last,
    output         busy_all_message
    );
    
    wire  [127:0] data_input;
    wire  [255:0] start_key_input;
    wire [127:0] data_output;

    assign data_input      = {4{d_input}};
    assign start_key_input = {8{key_input}};
    assign d_output       = {data_output[7:0], data_output[39:32],
                             data_output[127:112]};

    wire clk200Mhz;
    wire clk100Mhz;
    wire pll_locked;
    wire reset_request = rst || !pll_locked;

    (* ASYNC_REG = "TRUE" *) reg [1:0] core_reset_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] keys_reset_sync;

    wire rst_core = core_reset_sync[1];
    wire rst_keys = keys_reset_sync[1];

    wire [1279:0] prepared_keys;
    wire prepared_keys_valid;
    wire prepared_keys_ready;
    wire key_update_pending;
    wire key_update_allowed;
    wire loader_ready;

    assign key_input_ready = key_update_allowed && loader_ready;


    clk_wiz_0 clk_generator (
        .clk_in1(clk),
        .reset(rst),
        .locked(pll_locked),
        .clk_out1(clk200Mhz),
        .clk_out2(clk100Mhz)
    );

    // Запускаем обе стороны только после захвата PLL и снятия reset в своём домене.
    always @(posedge clk200Mhz or posedge reset_request) begin
        if (reset_request)
            core_reset_sync <= 2'b11;
        else
            core_reset_sync <= {core_reset_sync[0], 1'b0};
    end

    always @(posedge clk100Mhz or posedge reset_request) begin
        if (reset_request)
            keys_reset_sync <= 2'b11;
        else
            keys_reset_sync <= {keys_reset_sync[0], 1'b0};
    end


    kuz_key_loader key_loader (
        .clk_core(clk200Mhz),
        .rst_core(rst_core),
        .clk_keys(clk100Mhz),
        .rst_keys(rst_keys),
        .start_key_input(start_key_input),
        .key_input_valid(key_input_valid && key_update_allowed),
        .key_input_ready(loader_ready),
        .key_update_pending(key_update_pending),
        .round_keys(prepared_keys),
        .round_keys_valid(prepared_keys_valid),
        .round_keys_ready(prepared_keys_ready)
    );


    kuz_TOP dut (
        .clk(clk200Mhz),
        .rst(rst_core),
        .btn_pulse(btn_pulse),

        .round_keys_input(prepared_keys),
        .round_keys_input_valid(prepared_keys_valid),
        .round_keys_input_ready(prepared_keys_ready),
        .key_update_pending(key_update_pending),
        .key_update_allowed(key_update_allowed),
        .round_keys_ready(round_keys_ready),

        .data_input(data_input),
        .data_input_valid(data_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(data_input_ready),

        .data_output(data_output),
        .data_output_valid(data_output_valid),
        .data_output_last(data_output_last),
        .busy_all_message(busy_all_message),
        .switch_mode_pulse(switch_mode_pulse)
    );

endmodule
