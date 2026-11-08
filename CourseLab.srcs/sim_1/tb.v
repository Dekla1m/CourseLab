`timescale 1ns / 1ps

// Проверка полного L-преобразования: результат, задержка и управление запуском
module tb_L_function;

    parameter real CLK_PERIOD_NS = 5.0;

    reg clk;
    reg rst;
    reg start;
    reg [127:0] a;

    wire [127:0] y;
    wire done;

    integer TESTS;
    integer PASSED;
    reg [127:0] held_y;

    localparam [127:0] EXAMPLE_IN = 128'h64a59400000000000000000000000000;
    localparam [127:0] EXAMPLE_OUT = 128'hd456584dd0e3e84cc3166e4b7fa2890d;
    localparam [127:0] BASIS_OUT = 128'h6ea276726c487ab85d27bd10dd849401;

    // ========== Проверяемый модуль ==========

    l_matrix_onecycle dut (
        .clk(clk),
        .rst(rst),
        .data_input_r(start),
        .data_input(a),
        .data_output(y),
        .data_output_r(done)
    );

    // ========== Тактирование ==========

    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2.0) clk = ~clk;
    end

    // ========== Задачи ==========

    task begin_test;
        input [8*100-1:0] name;
        begin
            TESTS = TESTS + 1;
            $display("\nTEST %0d: %0s", TESTS, name);
        end
    endtask

    task check;
        input condition;
        input [8*140-1:0] message;
        begin
            if (condition !== 1'b1) begin
                $display("FAIL: TEST %0d: %0s", TESTS, message);
                $finish;
            end
        end
    endtask

    task pass_test;
        begin
            PASSED = PASSED + 1;
            $display("TEST %0d: PASS", TESTS);
        end
    endtask

    task run_example;
        input [127:0] value;
        input [127:0] expected;
        reg [127:0] previous_y;
        begin
            @(negedge clk);
            previous_y = y;
            a = value;
            start = 1;
            #0.1;
            check(y === previous_y, "Output changed before processing edge");

            @(posedge clk);
            #0.1;
            check(done === 1 && y === expected, "L result or one-cycle latency mismatch");

            @(negedge clk);
            start = 0;
            @(posedge clk);
            #0.1;
            check(done === 0 && y === expected, "Done did not clear or result was not held");
        end
    endtask

    // ========== Основной сценарий ==========

    initial begin
        rst = 1;
        start = 0;
        a = 0;
        TESTS = 0;
        PASSED = 0;

        begin_test("RESET");
        repeat (2) @(posedge clk);
        #0.1;
        check(y === 0 && done === 0, "Reset did not clear outputs");
        @(negedge clk);
        rst = 0;
        pass_test;

        begin_test("STANDARD L EXAMPLE, ONE CYCLE");
        run_example(EXAMPLE_IN, EXAMPLE_OUT);
        pass_test;

        begin_test("ZERO INPUT");
        run_example(0, 0);
        pass_test;

        begin_test("LOWEST INPUT BIT AND BYTE ORDER");
        run_example(128'h1, BASIS_OUT);
        pass_test;

        begin_test("DISABLED INPUT DOES NOT CHANGE RESULT");
        held_y = y;
        repeat (3) begin
            @(negedge clk);
            a = ~a;
            @(posedge clk);
            #0.1;
            check(y === held_y && done === 0, "Disabled operation changed output");
        end
        pass_test;

        begin_test("THREE CONSECUTIVE ENABLED CYCLES");
        // При непрерывном разрешении каждый фронт принимает новый вход.
        @(negedge clk);
        start = 1;
        a = EXAMPLE_IN;
        @(posedge clk);
        #0.1;
        check(done === 1 && y === EXAMPLE_OUT, "Consecutive result 1 mismatch");
        @(negedge clk);
        a = 0;
        @(posedge clk);
        #0.1;
        check(done === 1 && y === 0, "Consecutive result 2 mismatch");
        @(negedge clk);
        a = 1;
        @(posedge clk);
        #0.1;
        check(done === 1 && y === BASIS_OUT, "Consecutive result 3 mismatch");
        pass_test;

        begin_test("RESET HAS PRIORITY OVER ENABLE");
        @(negedge clk);
        rst = 1;
        a = EXAMPLE_IN;
        @(posedge clk);
        #0.1;
        check(done === 0 && y === 0, "Enable overrode reset");
        @(negedge clk);
        rst = 0;
        start = 0;
        run_example(EXAMPLE_IN, EXAMPLE_OUT);
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        if (PASSED == TESTS)
            $display("ALL PASS: L one-cycle; %0d scenarios", TESTS);
        else
            $display("FAIL: L one-cycle summary");
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: L one-cycle timeout");
        $finish;
    end

endmodule
