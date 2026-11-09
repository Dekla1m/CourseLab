// Full L using one R datapath reused for 16 clock cycles.
// Constant GF multipliers use eight basis contributions and XOR.
// Inputs launched after edge N complete at edge N+16.
// start is accepted only when busy=0. done pulses for one cycle.
`timescale 1ns/1ps
module l_iterative_16cycles (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [127:0] a,
    output reg [127:0] y,
    output reg done,
    output reg busy
);
    reg [127:0] state;
    reg [4:0] step_count;

    function automatic [7:0] mult_polinom(
        input [7:0] value,
        input [7:0] coefficient
    );
        reg [63:0] contributions;
        reg [7:0] result;
        integer bit_index;
        begin
            case (coefficient)
                8'd1: contributions = 64'h8040201008040201;
                8'd16: contributions = 64'hd78a45c380402010;
                8'd32: contributions = 64'h6dd78a45c3804020;
                8'd133: contributions = 64'hb259cd87a251c985;
                8'd148: contributions = 64'he593a8542a15eb94;
                8'd192: contributions = 64'hadb7ba5dcf8643c0;
                8'd194: contributions = 64'h6e37fa7ddf8e47c2;
                8'd251: contributions = 64'hde6fd66bd46a35fb;
                default: contributions = 64'b0;
            endcase
            result = 8'b0;
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                if (value[bit_index])
                    result = result ^ contributions[8 * bit_index +: 8];
            mult_polinom = result;
        end
    endfunction

    function automatic [127:0] r_step(input [127:0] block_value);
        reg [7:0] r;
        begin
            r = mult_polinom(block_value[127:120], 8'd148)
              ^ mult_polinom(block_value[119:112], 8'd32)
              ^ mult_polinom(block_value[111:104], 8'd133)
              ^ mult_polinom(block_value[103:96], 8'd16)
              ^ mult_polinom(block_value[95:88], 8'd194)
              ^ mult_polinom(block_value[87:80], 8'd192)
              ^ mult_polinom(block_value[79:72], 8'd1)
              ^ mult_polinom(block_value[71:64], 8'd251)
              ^ mult_polinom(block_value[63:56], 8'd1)
              ^ mult_polinom(block_value[55:48], 8'd192)
              ^ mult_polinom(block_value[47:40], 8'd194)
              ^ mult_polinom(block_value[39:32], 8'd16)
              ^ mult_polinom(block_value[31:24], 8'd133)
              ^ mult_polinom(block_value[23:16], 8'd32)
              ^ mult_polinom(block_value[15:8], 8'd148)
              ^ mult_polinom(block_value[7:0], 8'd1);
            r_step = {r, block_value[127:8]};
        end
    endfunction

    // Select the external input for R1, otherwise use the saved state.
    // Exactly one R function call describes the shared datapath.
    wire [127:0] r_input = busy ? state : a;
    wire [127:0] next_state = r_step(r_input);

    always @(posedge clk) begin
        if (rst) begin
            state <= 128'b0;
            y <= 128'b0;
            step_count <= 5'd0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (busy) begin
                state <= next_state;
                if (step_count == 5'd15) begin
                    y <= next_state;
                    step_count <= 5'd16;
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    step_count <= step_count + 1'b1;
                end
            end else if (start) begin
                // R1 is computed on the first processing edge.
                state <= next_state;
                step_count <= 5'd1;
                busy <= 1'b1;
            end
        end
    end
endmodule
