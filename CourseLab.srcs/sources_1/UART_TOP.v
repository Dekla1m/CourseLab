`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.10.2026 13:47:56
// Design Name: 
// Module Name: UART_TOP
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 16:22:07
// Design Name: 
// Module Name: KM_UART
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

module UART_TOP #(
parameter FREQ = 100_000_000,
parameter BAUDRATE = 1200,
parameter RATIO = 8,
parameter DIV_VALUE = FREQ / (BAUDRATE * RATIO)
)(
input clk,
input rst,

input RXD,
output TXD,

output TX_VALID,
output [9:0] TX_DATA,

input RX_VALID,
input [7:0] RX_DATA,
output RX_READY
);

wire RXD_RG;
wire UART_CE;

wire RXCT_R;
wire RX_CE;

wire TXCT_R;
wire TX_CE;


// ==========================================
// Синхронизатор RXD
// ==========================================

KM_SYNCHR SYNCHR(
    .RXD(RXD),
    .clk(clk),
    .rst(rst),
    .RXD_RG(RXD_RG)
);


// ==========================================
// Делитель частоты
// BAUDRATE  = UART_CE / RATIO
// ==========================================

KM_CLK_DIVIDER #(
    .count_divide(DIV_VALUE)
) CLK_DIVIDER (
    .clk(clk),
    .rst(rst),
    .out_clk(UART_CE)
);


// ==========================================
// Счетчик сэмплов RX
// ==========================================

KM_COUNTER_SAMP_RX COUNTER_SAMP_RX(
    .clk(clk),
    .rst(rst),
    .UART_CE(UART_CE),
    .RXCT_R(RXCT_R),
    .RX_CE(RX_CE)
);


// ==========================================
// RX FSM
// ==========================================

KM_RX_FSM RX_FSM(
    .RXD_RG(RXD_RG),
    .clk(clk),
    .rst(rst),
    .RX_CE(RX_CE),
    .TX_VALID(TX_VALID),
    .TX_DATA(TX_DATA),
    .RXCT_R(RXCT_R)
);


// ==========================================
// Счетчик сэмплов TX
// ==========================================

KM_COUNTER_SAMP_TX COUNTER_SAMP_TX(
    .clk(clk),
    .rst(rst),
    .UART_CE(UART_CE),
    .TXCT_R(TXCT_R),
    .TX_CE(TX_CE)
);


// ==========================================
// TX FSM
// ==========================================

KM_TX_FSM TX_FSM(
    .UART_CE(UART_CE),
    .TX_CE(TX_CE),
    .RX_VALID(RX_VALID),
    .RX_DATA(RX_DATA),
    .rst(rst),
    .clk(clk),
    .TXCT_R(TXCT_R),
    .RX_READY(RX_READY),
    .TXD(TXD)
);

endmodule