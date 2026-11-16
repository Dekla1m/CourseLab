`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2026 12:05:49
// Design Name: 
// Module Name: KM_SYNCHR
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


module KM_SYNCHR(
input RXD,
input clk,
input rst,
output RXD_RG
    );

reg [1:0] synchr;    
always @(posedge clk) begin
   if (rst) synchr <= 2'b11; 
   else synchr = {RXD, synchr[1]};
end     
assign RXD_RG = synchr[0];     
endmodule
