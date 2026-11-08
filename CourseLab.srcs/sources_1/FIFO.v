`timescale 1ns/1ps
`default_nettype none

// Двухтактовый FIFO: запись по write_enable && !full, чтение по read_valid && read_ready.
// Глубина — степень двойки >= 2. Выходной регистр не добавляет место сверх FIFO_DEPTH:
// до приёма слова его адрес остаётся занятым в памяти.
//
// Память не сбрасывается. Общий reset отменяет очередь; его снятие синхронизируется
// в каждом домене отдельно. При остановленном clock соответствующий домен ждёт.
// full относится к записи; read_valid, empty и data_out — к чтению.

module FIFO #(
    parameter WORD_SIZE = 8,
    parameter FIFO_DEPTH = 64
) (
    input  wire                 reset,

    input  wire                 clk_in_write,
    input  wire [WORD_SIZE-1:0] data_in,
    input  wire                 write_enable,
    output wire                 full,

    input  wire                 clk_in_read,
    input  wire                 read_ready,
    output reg  [WORD_SIZE-1:0] data_out,
    output reg                  read_valid,
    output wire                 empty
);

    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // При расстоянии в одну полную очередь в Gray-коде инвертируются два старших бита.
    localparam [PTR_WIDTH-1:0] FULL_MASK =
        (1 << ADDR_WIDTH) | (1 << (ADDR_WIDTH - 1));

    initial begin
        if (WORD_SIZE < 1 || FIFO_DEPTH < 2 || (FIFO_DEPTH & (FIFO_DEPTH - 1)) != 0) begin
            $display("ERROR: FIFO requires WORD_SIZE >= 1 and power-of-two FIFO_DEPTH >= 2");
            $finish;
        end
    end


    // Асинхронное включение reset, снятие через две ступени своего clock.
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] wr_reset_sync, rd_reset_sync;

    always @(posedge clk_in_write or posedge reset) begin
        if (reset)
            wr_reset_sync <= 2'b11;
        else
            wr_reset_sync <= {wr_reset_sync[0], 1'b0};
    end

    always @(posedge clk_in_read or posedge reset) begin
        if (reset)
            rd_reset_sync <= 2'b11;
        else
            rd_reset_sync <= {rd_reset_sync[0], 1'b0};
    end

    wire wr_reset = wr_reset_sync[1];
    wire rd_reset = rd_reset_sync[1];


    reg [WORD_SIZE-1:0] mem [0:FIFO_DEPTH-1];

    // Двоичные адреса локальны; через границу clocks передаются только Gray-коды.
    reg [PTR_WIDTH-1:0] wr_bin, wr_gray;
    reg [PTR_WIDTH-1:0] rd_bin, rd_gray;
    reg full_reg;

    // Указатель чтения в домене записи и указатель записи в домене чтения.
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [PTR_WIDTH-1:0] rd_gray_w1, rd_gray_w2;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [PTR_WIDTH-1:0] wr_gray_r1, wr_gray_r2;

    // Во время reset/recovery запись недоступна: источник не видит ложного разрешения.
    assign full = reset || wr_reset || full_reg;
    assign empty = !read_valid;

    wire wr_take = write_enable && !full;
    wire rd_take = read_valid && read_ready && !rd_reset && !reset;

    wire [PTR_WIDTH-1:0] wr_bin_next = wr_bin + wr_take;
    wire [PTR_WIDTH-1:0] rd_bin_next = rd_bin + rd_take;
    wire [PTR_WIDTH-1:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    wire [PTR_WIDTH-1:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    // Проверяется адрес головы ПОСЛЕ возможного приёма текущего выходного слова.
    // Синхронизированный указатель записи гарантирует, что соответствующее слово уже записано.
    wire next_head_available = (rd_gray_next != wr_gray_r2);


    always @(posedge clk_in_write or posedge wr_reset) begin
        if (wr_reset) begin
            rd_gray_w1 <= 0;
            rd_gray_w2 <= 0;
        end else begin
            rd_gray_w1 <= rd_gray;
            rd_gray_w2 <= rd_gray_w1;
        end
    end

    always @(posedge clk_in_read or posedge rd_reset) begin
        if (rd_reset) begin
            wr_gray_r1 <= 0;
            wr_gray_r2 <= 0;
        end else begin
            wr_gray_r1 <= wr_gray;
            wr_gray_r2 <= wr_gray_r1;
        end
    end


    always @(posedge clk_in_write) begin
        if (wr_take)
            mem[wr_bin[ADDR_WIDTH-1:0]] <= data_in;
    end

    always @(posedge clk_in_write or posedge wr_reset) begin
        if (wr_reset) begin
            wr_bin <= 0;
            wr_gray <= 0;
            full_reg <= 0;
        end else begin
            wr_bin <= wr_bin_next;
            wr_gray <= wr_gray_next;
            full_reg <= (wr_gray_next == (rd_gray_w2 ^ FULL_MASK));
        end
    end


    always @(posedge clk_in_read or posedge rd_reset) begin
        if (rd_reset) begin
            rd_bin <= 0;
            rd_gray <= 0;
            data_out <= 0;
            read_valid <= 0;
        end else begin
            rd_bin <= rd_bin_next;
            rd_gray <= rd_gray_next;

            // При остановке потребителя выход не меняется. Если регистр пуст или слово
            // принято, синхронно читаем голову: текущую при предвыборке, следующую при handshake.
            // Указатель продвигается только по rd_take, поэтому предвыборка не освобождает место.
            if (!read_valid || rd_take) begin
                read_valid <= next_head_available;

                if (next_head_available)
                    data_out <= mem[rd_bin_next[ADDR_WIDTH-1:0]];
            end
        end
    end

endmodule

`default_nettype wire
