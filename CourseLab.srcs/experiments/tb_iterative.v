`timescale 1ns / 1ps

// Проверка полного L-преобразования: результат, задержка и управление запуском
module tb_iterative;

    parameter real CLK_PERIOD_NS = 10.0;

    reg clk;
    reg rst;
    reg start;
    reg [127:0] a;

    wire [127:0] y;
    wire done;
    wire busy;

    integer TESTS;
    integer PASSED;
    reg [127:0] held_y;

    localparam [127:0] EXAMPLE_IN = 128'h64a59400000000000000000000000000;
    localparam [127:0] EXAMPLE_OUT = 128'hd456584dd0e3e84cc3166e4b7fa2890d;
    localparam [127:0] BASIS_OUT = 128'h6ea276726c487ab85d27bd10dd849401;

    // ========== Проверяемый модуль ==========

    l_iterative_16cycles dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .y(y),
        .done(done),
        .busy(busy)
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
        input disturb_input;
        reg [127:0] previous_y;
        integer step;
        begin
            @(negedge clk);
            previous_y = y;
            a = value;
            start = 1;

            // Первый обрабатывающий фронт уже выполняет R1; результат нужен на R16.
            for (step = 1; step <= 16; step = step + 1) begin
                @(posedge clk);
                #0.1;
                if (step < 16)
                    check(busy === 1 && done === 0 && y === previous_y,
                          "Busy, early done or output hold mismatch");
                else
                    check(busy === 0 && done === 1 && y === expected,
                          "L result or 16-cycle latency mismatch");

                @(negedge clk);
                start = 0;
                if (disturb_input) begin
                    a = ~a;
                    if (step == 4 || step == 5)
                        start = 1;
                end
            end

            @(posedge clk);
            #0.1;
            check(done === 0 && busy === 0 && y === expected,
                  "Done is not a pulse or a busy-time request was queued");
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
        check(y === 0 && done === 0 && busy === 0, "Reset did not clear outputs");
        @(negedge clk);
        rst = 0;
        pass_test;

        begin_test("STANDARD L EXAMPLE, SIXTEEN CYCLES");
        run_example(EXAMPLE_IN, EXAMPLE_OUT, 0);
        pass_test;

        begin_test("ZERO INPUT");
        run_example(0, 0, 0);
        pass_test;

        begin_test("LOWEST INPUT BIT AND BYTE ORDER");
        run_example(128'h1, BASIS_OUT, 0);
        pass_test;

        begin_test("INPUT CHANGES AND START WHILE BUSY");
        run_example(EXAMPLE_IN, EXAMPLE_OUT, 1);
        pass_test;

        begin_test("IDLE RESULT HOLD");
        held_y = y;
        repeat (3) begin
            @(negedge clk);
            a = ~a;
            @(posedge clk);
            #0.1;
            check(y === held_y && done === 0 && busy === 0, "Idle result changed");
        end
        pass_test;

        begin_test("RESET ABORTS AN ACTIVE OPERATION");
        @(negedge clk);
        a = EXAMPLE_IN;
        start = 1;
        @(negedge clk);
        start = 0;
        repeat (6) @(negedge clk);
        check(busy === 1, "Abort scenario did not reach active operation");
        rst = 1;
        start = 1;
        @(posedge clk);
        #0.1;
        check(y === 0 && done === 0 && busy === 0, "Reset did not override active start");
        @(negedge clk);
        rst = 0;
        start = 0;
        repeat (17) begin
            @(posedge clk);
            #0.1;
            check(done === 0 && busy === 0 && y === 0, "Aborted operation produced a result");
        end
        pass_test;

        begin_test("NEW OPERATION AFTER RESET");
        run_example(EXAMPLE_IN, EXAMPLE_OUT, 0);
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        if (PASSED == TESTS)
            $display("ALL PASS: L iterative; %0d scenarios", TESTS);
        else
            $display("FAIL: L iterative summary");
        $finish;
    end

    initial begin
        #20000;
        $display("FAIL: L iterative timeout");
        $finish;
    end

endmodule
