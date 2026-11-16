`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 16:22:07
// Design Name: 
// Module Name: KM_RX_FSM
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


module KM_RX_FSM(
input RXD_RG,
input clk,
input rst,
input RX_CE,
output reg TX_VALID,
output reg [9:0] TX_DATA,
output reg RXCT_R
);
    
reg [2:0] state;
reg [2:0] RX_DATA_CT;

localparam IDLE = 0;
localparam RSTRB = 1;
localparam RDT = 2;
localparam RPARB = 3;
localparam RSTB1 = 4;
localparam WEND = 5;

always @(posedge clk) begin
    if (rst) begin
        TX_VALID <= 1'b0;
        TX_DATA <= 10'h000;
        RX_DATA_CT <= 3'b000;
        RXCT_R <= 1'b1;
        state <= IDLE;
    end
    else begin
        case (state)
            IDLE: begin
                if (!RXD_RG) begin
                    RX_DATA_CT <= 3'b000;
                    TX_VALID <= 1'b0;
                    TX_DATA[9:8] <= 2'b00;
                    RXCT_R <= 1'b0;
                    state <= RSTRB;
                end
                else TX_VALID <= 1'b0;
            end
            RSTRB: begin
                if (RX_CE) begin
                    if (RXD_RG) begin
                        RXCT_R <= 1'b1;
                        state <= IDLE;
                    end 
                    else state <= RDT;
                end
            end
            RDT: begin
                if (RX_CE) begin
                    TX_DATA[7:0] <= {RXD_RG, TX_DATA[7:1]};
                    RX_DATA_CT <= RX_DATA_CT + 1'b1;
                    
                    if (RX_DATA_CT == 3'h7) state <= RPARB;
                end
            end
            RPARB: begin
                if (RX_CE) begin
                    TX_DATA[8] <= RXD_RG ^ (^TX_DATA[7:0]);
                    state <= RSTB1;
                end
            end
            RSTB1: begin
                if (RX_CE) begin
                    if (RXD_RG) begin
                        TX_VALID <= 1'b1;
                        RXCT_R <= 1'b1;
                        state <= IDLE;
                    end
                    else begin
                        TX_DATA[9] <= 1'b1;
                        state <= WEND;
                    end 
                end
            end
            WEND: begin
                if (RXD_RG) begin
                    TX_VALID <= 1'b1;
                    RXCT_R <= 1'b1;
                    state <= IDLE;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
    


end

endmodule
