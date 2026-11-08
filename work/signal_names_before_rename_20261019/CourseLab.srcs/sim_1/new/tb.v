`timescale 1ns/1ps

// This test measures full L, not a single 8-bit multiplication.
// Default 200 MHz; functional latency is one cycle regardless of timing closure.
// Functional simulation does not check post-route setup/hold timing.
module tb;
    parameter real CLK_PERIOD_NS = 5.0;
    reg clk = 1'b0;
    always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

    reg rst = 1'b1;
    reg start = 1'b0;
    reg [127:0] a = 128'b0;
    wire [127:0] y;
    wire done;

    l_matrix_onecycle dut (
        .clk(clk), .rst(rst), .start(start),
        .a(a), .y(y), .done(done)
    );

    integer cycle_count = 0;
    integer start_cycle = 0;
    integer end_cycle = 0;
    integer last_cycles = 0;
    integer passed = 0;
    real launch_time_ns;
    real elapsed_ns;

    // Free-running testbench clock counter, not part of the synthesized DUT.
    always @(posedge clk)
        cycle_count = cycle_count + 1;

    task run_example;
        input [127:0] input_value;
        input [127:0] expected_value;
        reg [127:0] previous_y;
        begin
            // Launch just after a rising edge to avoid testbench/DUT races.
            @(posedge clk);
            #0.1;
            if (done !== 1'b0)
                $fatal(1, "Unexpected stale done before launch");

            start_cycle = cycle_count;
            launch_time_ns = $realtime;
            previous_y = y;
            a = input_value;
            start = 1'b1;

            // Registered output must not update immediately with input changes.
            #0.1;
            if (done !== 1'b0 || y !== previous_y)
                $fatal(1, "Output changed before the next rising edge");

            while (done !== 1'b1) begin
                @(posedge clk);
                #0.1; // Wait for nonblocking assignments.
                if (cycle_count - start_cycle > 32)
                    $fatal(1, "Timeout: L did not finish");
            end

            end_cycle = cycle_count;
            last_cycles = end_cycle - start_cycle;
            elapsed_ns = $realtime - launch_time_ns;
            start = 1'b0;

            if (y !== expected_value)
                $fatal(1, "L mismatch: input=%032h actual=%032h expected=%032h",
                       input_value, y, expected_value);
            if (last_cycles != 1)
                $fatal(1, "Expected one cycle, measured %0d", last_cycles);

            passed = passed + 1;
            $display("MATRIX L: input=%032h output=%032h cycles=%0d elapsed_ns=%0.1f",
                     input_value, y, last_cycles, elapsed_ns);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #0.1;
        rst = 1'b0;

        run_example(128'h00000000000000000000000000000000,
                    128'h00000000000000000000000000000000);
        run_example(128'h00000000000000000000000000000001,
                    128'h6ea276726c487ab85d27bd10dd849401);
        run_example(128'h64a59400000000000000000000000000,
                    128'hd456584dd0e3e84cc3166e4b7fa2890d);
        run_example(128'he87de8b6e87de8b6b6b6b6b6b6b6b6b6,
                    128'he297b686e355b0a1cf4a2f9249140830);

        @(posedge clk);
        #0.1;
        if (done !== 1'b0)
            $fatal(1, "done did not clear after start was deasserted");
        $display("PASS: %0d full-L examples; latency = 1 cycle.", passed);
        $finish;
    end
endmodule
