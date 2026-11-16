`timescale 1ns/1ps
// Deterministic failure: write a full buffer while the read clock is stopped.
module tb_fifo_original;
    reg wr_clk=0, rd_clk=0, reset=0, wen=0;
    reg [7:0] data=0;
    wire [7:0] out;
    wire valid,empty,full;
    integer i;
    always #5 wr_clk=~wr_clk;
    FIFO #(.FIFO_DEPTH(64)) dut (
        .reset(reset), .data_in(data), .clk_in_write(wr_clk), .clk_in_read(rd_clk),
        .enable(1'b1), .write_enable(wen), .read_enable(1'b0),
        .data_out(out), .valid_out(valid), .empty(empty), .full(full)
    );
    initial begin
        #1; reset=1; #20; reset=0;
        repeat(5) @(negedge wr_clk);
        for(i=0;i<64;i=i+1) begin
            data=i; wen=1; @(negedge wr_clk);
        end
        wen=0; #1;
        if(full !== 1'b1) begin
            $display("REPRODUCED ORIGINAL BUG: wrote 64 words with read clock stopped, full=%b (expected 1)",full);
            $finish;
        end
        $fatal(1,"Expected original FIFO bug was not reproduced");
    end
endmodule
