`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 16:22:07
// Design Name: 
// Module Name: KM_COUNTER_SAMP_RX
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


module KM_COUNTER_SAMP_RX (
    input clk,
    input rst,
    input UART_CE,
    input RXCT_R,
    output RX_CE
);

reg [2:0] RX_SAMP_CT;

always @(posedge clk) begin
    if (rst || RXCT_R) begin
        RX_SAMP_CT <= 3'b000;
    end else if (UART_CE) begin
        RX_SAMP_CT <= RX_SAMP_CT + 1'b1; 
    end
end

assign RX_CE = UART_CE && (~RX_SAMP_CT[2] && RX_SAMP_CT[1] && RX_SAMP_CT[0]);

endmodule