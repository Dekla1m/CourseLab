`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 16:22:07
// Design Name: 
// Module Name: KM_COUNTER_SAMP_TX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module KM_COUNTER_SAMP_TX (
    input clk,
    input rst,
    input UART_CE,
    input TXCT_R,
    output TX_CE
);

reg [2:0] TX_SAMP_CT;

always @(posedge clk) begin
    if (rst || TXCT_R) begin
        TX_SAMP_CT <= 3'b000;
    end else if (UART_CE) begin
        TX_SAMP_CT <= TX_SAMP_CT + 1'b1; 
    end
end

assign TX_CE = UART_CE && (TX_SAMP_CT[2] && TX_SAMP_CT[1] && TX_SAMP_CT[0]);
endmodule