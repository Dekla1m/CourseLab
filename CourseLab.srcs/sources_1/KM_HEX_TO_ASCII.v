`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.09.2026 13:00:54
// Design Name: 
// Module Name: KM_HEX_TO_ASCII
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


module KM_HEX_TO_ASCII(
input [3:0] HEX,
output reg [7:0] ASCII
    );
   
always @(*) begin
    case (HEX)
    4'h0: ASCII = 8'h30;
    4'h1: ASCII = 8'h31;
    4'h2: ASCII = 8'h32;
    4'h3: ASCII = 8'h33;
    4'h4: ASCII = 8'h34;
    4'h5: ASCII = 8'h35;
    4'h6: ASCII = 8'h36;
    4'h7: ASCII = 8'h37;
    4'h8: ASCII = 8'h38;
    4'h9: ASCII = 8'h39;
    4'hA: ASCII = 8'h41;
    4'hB: ASCII = 8'h42;
    4'hC: ASCII = 8'h43;
    4'hD: ASCII = 8'h44;
    4'hE: ASCII = 8'h45;
    4'hF: ASCII = 8'h46;
    endcase
end

endmodule
