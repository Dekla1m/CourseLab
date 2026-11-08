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
    (* keep_hierarchy="yes" *) f_matrix_onecycle dut (
        .clk(core_clk),.rst(rst),.start(start_reg),
        .a(a_reg),.b(b_reg),.k(k_reg),
        .a_next(a_next),.b_next(b_next),.done(done)
    );
endmodule
