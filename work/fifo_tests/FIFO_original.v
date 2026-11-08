module FIFO #(
    parameter WORD_SIZE  = 8,   // Ширина слова данных
    parameter FIFO_DEPTH = 64    // Глубина FIFO (должна быть степенью 2)
)(
    input wire reset,                    // Сброс (активный высокий)
    input wire [WORD_SIZE-1:0] data_in,  // Данные для записи
    input wire clk_in_write,             // Такт записи
    input wire clk_in_read,              // Такт чтения
    input wire enable,                   // Разрешение работы FIFO
    input wire write_enable,             // Разрешение записи
    input wire read_enable,              // Разрешение чтения
    output reg [WORD_SIZE-1:0] data_out, // Выходные данные
    output reg valid_out,                // Флаг валидности данных
    output reg empty,                    // Флаг пустого FIFO
    output reg full                      // Флаг полного FIFO
);

localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

function [ADDR_WIDTH-1:0] next_ptr_val;
    input [ADDR_WIDTH-1:0] ptr;
    input condition;
    begin
        if(condition) begin
            if(ptr == (FIFO_DEPTH-1))
                next_ptr_val = {ADDR_WIDTH{1'b0}};
            else
                next_ptr_val = ptr + 1'b1;
        end else
            next_ptr_val = ptr;
    end
endfunction

/** Блочная память FIFO */
reg [WORD_SIZE-1:0] mem [0:FIFO_DEPTH-1];

reg [ADDR_WIDTH-1:0] write_pointer, read_pointer;

/** Синхронизатор (WRITE_POINTER -> READ_DOMAIN) */
reg [ADDR_WIDTH-1:0] write_pointer_sync [1:0];

/** Синхронизатор (READ_POINTER -> WRITE_DOMAIN) */
reg [ADDR_WIDTH-1:0] read_pointer_sync [1:0];

/** Чтение данных из буфера FIFO */
wire read_condition = enable && read_enable && !empty;
wire [ADDR_WIDTH-1:0] read_pointer_inc = next_ptr_val(read_pointer, read_condition);

/** Запись данных в буфер FIFO */
wire write_condition = enable && write_enable && !full;
wire [ADDR_WIDTH-1:0] write_pointer_inc = next_ptr_val(write_pointer, write_condition);

/** Логика установки флага empty */
wire empty_next = (write_pointer_sync[1] == read_pointer_inc) && !full;

/** Логика установки флага full */
wire full_next = (read_pointer_sync[1] == write_pointer_inc) && !empty;

// Инициализация регистров
initial begin
    write_pointer = {ADDR_WIDTH{1'b0}};
    read_pointer  = {ADDR_WIDTH{1'b0}};
    write_pointer_sync[0] = {ADDR_WIDTH{1'b0}};
    write_pointer_sync[1] = {ADDR_WIDTH{1'b0}};
    read_pointer_sync[0]  = {ADDR_WIDTH{1'b0}};
    read_pointer_sync[1]  = {ADDR_WIDTH{1'b0}};
    data_out = {WORD_SIZE{1'b0}};
    valid_out = 1'b0;
    empty = 1'b1;
    full = 1'b0;
end

/** Синхронизатор (WRITE_POINTER -> READ_DOMAIN) */
always @(posedge clk_in_read or posedge reset) begin
    if(reset) begin
        write_pointer_sync[0] <= {ADDR_WIDTH{1'b0}};
        write_pointer_sync[1] <= {ADDR_WIDTH{1'b0}};
    end else begin
        write_pointer_sync[0] <= write_pointer;
        write_pointer_sync[1] <= write_pointer_sync[0];
    end
end

/** Синхронизатор (READ_POINTER -> WRITE_DOMAIN) */
always @(posedge clk_in_write or posedge reset) begin
    if(reset) begin
        read_pointer_sync[0] <= {ADDR_WIDTH{1'b0}};
        read_pointer_sync[1] <= {ADDR_WIDTH{1'b0}};
    end else begin
        read_pointer_sync[0] <= read_pointer;
        read_pointer_sync[1] <= read_pointer_sync[0];
    end
end

/** Чтение данных из буфера FIFO */
always @(posedge clk_in_read or posedge reset) begin
    if(reset) begin
        data_out    <= {WORD_SIZE{1'b0}};
        valid_out   <= 1'b0;
        read_pointer <= {ADDR_WIDTH{1'b0}};
    end else begin
        read_pointer <= read_pointer_inc;
        if(read_condition) begin
            data_out  <= mem[read_pointer[ADDR_WIDTH-1:0]];
            valid_out <= 1'b1;
        end else
            valid_out <= 1'b0;
    end
end

/** Запись данных в буфер FIFO */
always @(posedge clk_in_write or posedge reset) begin
    if(reset)
        write_pointer <= {ADDR_WIDTH{1'b0}};
    else begin
        write_pointer <= write_pointer_inc;
        if(write_condition)
            mem[write_pointer[ADDR_WIDTH-1:0]] <= data_in;
    end
end

/** Логика установки флага empty */
always @(posedge clk_in_read or posedge reset) begin
    if(reset)
        empty <= 1'b1;
    else
        empty <= empty_next;
end

/** Логика установки флага full */
always @(posedge clk_in_write or posedge reset) begin
    if(reset)
        full <= 1'b0;
    else
        full <= full_next;
end

endmodule