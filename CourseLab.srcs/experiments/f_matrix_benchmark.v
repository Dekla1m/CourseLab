`timescale 1ns/1ps
// Benchmark only. Real input registers and a global clock buffer surround F.
// External port timing is excluded in the benchmark XDC; report core FF->FF paths.
module f_matrix_benchmark (
    input wire clk, rst, start,
    input wire [127:0] a,b,k,
    output wire [127:0] a_next,b_next,
    output wire done
);
    wire core_clk;
    BUFG clk_buffer (.I(clk),.O(core_clk));
    reg [127:0] a_reg,b_reg,k_reg;
    reg start_reg;
    always @(posedge core_clk) begin
        if(rst) begin
            a_reg<=0; b_reg<=0; k_reg<=0; start_reg<=0;
        end else begin
            a_reg<=a; b_reg<=b; k_reg<=k; start_reg<=start;
        end
    end
    (* keep_hierarchy="yes" *) key_matrix_onecycle dut (
        .clk(core_clk),.rst(rst),.key_step_enable(start_reg),
        .key_left_input(a_reg),.key_right_input(b_reg),.iteration_constant_input(k_reg),
        .key_left_output(a_next),.key_right_output(b_next),.key_step_done(done)
    );
endmodule
