`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 16:22:07
// Design Name: 
// Module Name: KM_TX_FSM
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


module KM_TX_FSM(
input UART_CE,
input TX_CE,
input RX_VALID,
input [7:0] RX_DATA,
input rst,
input clk,
output reg TXCT_R,
output reg RX_READY,
output reg TXD
);
    
reg [2:0] state;
reg [7:0] DATA; 
reg TX_PAR_BIT_RG;
reg [2:0] TX_DATA_CT;

localparam IDLE = 0;
localparam WCE = 1;
localparam TSTRB = 2;
localparam TDT = 3;
localparam TPARB = 4;
localparam TSTB = 5;

always @(posedge clk) begin
    if (rst) begin
        DATA <= 8'h00;
        TX_PAR_BIT_RG <= 1'b0;
        RX_READY <= 1'b1;
        TX_DATA_CT <= 3'b000;
        TXD <= 1'b1;
        TXCT_R <= 1'b1;
        state <= IDLE;
    end
    else begin
        case (state)
            IDLE: begin
                if (RX_VALID) begin
                    DATA <= RX_DATA;
                    // Even parity for the captured data byte.
                    TX_PAR_BIT_RG <= ^RX_DATA;
                    TX_DATA_CT <= 3'b000; 
                    RX_READY <= 1'b0;
                    if (UART_CE) begin
                        TXD <= 1'b0;
                        TXCT_R <= 1'b0;
                        state <= TSTRB;
                    end
                    else state <= WCE;
                end
            end
            WCE: begin
                if (UART_CE) begin
                    TXD <= 1'b0;
                    TXCT_R <= 1'b0;
                    state <= TSTRB;
                end
            end
            TSTRB: begin
                if (TX_CE) begin
                    TXD <= DATA[0];
                    DATA <= {1'b0, DATA[7:1]};
                    state <= TDT;
                end
            end
            TDT: begin
                if (TX_CE) begin
                    DATA <= {1'b0, DATA[7:1]};
                    TX_DATA_CT <= TX_DATA_CT + 1'b1;
                    if (TX_DATA_CT == 3'h7) begin
                        TXD <= TX_PAR_BIT_RG;
                        state <= TPARB;
                    end
                    else TXD <= DATA[0];
                end
            end
            TPARB: begin
                if (TX_CE) begin
                    TXD <= 1'b1;
                    state <= TSTB;
                end
            end
            TSTB: begin
                if (TX_CE) begin
                    TXD <= 1'b1;
                    RX_READY <= 1'b1;
                    TXCT_R <= 1'b1;
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