`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.09.2026 13:00:54
// Design Name: 
// Module Name KM_CLK_DIVIDER
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

module KM_CLK_DIVIDER #(
parameter count_divide = 16
)(
input clk,
input rst,
output reg out_clk
);

reg [$clog2(count_divide) - 1:0] counter_divide;
always @(posedge clk) begin
    if (rst) begin
        out_clk <= 0;
        counter_divide <= 0;
    end
    else if (counter_divide == (count_divide - 1)) begin 
        out_clk <= 1;
        counter_divide <= 0;
    end
    else begin
        out_clk <= 0;
        counter_divide <= counter_divide + 1;
    end
end

endmodule
