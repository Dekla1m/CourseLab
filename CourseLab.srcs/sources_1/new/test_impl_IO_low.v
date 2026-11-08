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
    
    output wire  [31:0]  d_output,
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

    kuz_TOP dut (
        .clk(clk),             
        .rst(rst),             
                         
        .btn_pulse(btn_pulse),       
                         
        .data_input(data_input),      
        .start_key_input(start_key_input),
        .key_input_valid(key_input_valid),
        .key_input_ready(key_input_ready),
        .round_keys_ready(round_keys_ready),
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
