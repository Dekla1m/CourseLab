`timescale 1ns / 1ps

module tb_matrix_round;

    reg clk;
    reg rst;
    reg f_enable;
    reg lsx_enable;
    reg [127:0] a;
    reg [127:0] b;
    reg [127:0] k;

    wire [127:0] a_next;
    wire [127:0] b_next;
    wire [127:0] lsx;
    wire f_done;
    wire lsx_done;

    integer TESTS;
    integer PASSED;
    integer i;
    reg [127:0] hold_a;
    reg [127:0] hold_b;
    reg [127:0] hold_lsx;
    reg [127:0] expected_lsx;

    localparam [127:0] KEY_LEFT = 128'h8899aabbccddeeff0011223344556677;
    localparam [127:0] KEY_RIGHT = 128'hfedcba98765432100123456789abcdef;
    localparam [127:0] C1 = 128'h6ea276726c487ab85d27bd10dd849401;
    localparam [127:0] FIRST_F = 128'hc3d5fa01ebe36f7a9374427ad7ca8949;

    // ========== Проверяемые модули ==========

    key_matrix_onecycle f_dut (
        .clk(clk),
        .rst(rst),
        .key_step_enable(f_enable),
        .key_left_input(a),
        .key_right_input(b),
        .iteration_constant_input(k),
        .key_left_output(a_next),
        .key_right_output(b_next),
        .key_step_done(f_done)
    );

    data_matrix_onecycle lsx_dut (
        .clk(clk),
        .rst(rst),
        .data_round_enable(lsx_enable),
        .data_input(a),
        .key_input(k),
        .data_output(lsx),
        .data_round_done(lsx_done)
    );

    // ========== Тактирование ==========

    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;
    end

    // ========== Независимый математический эталон ==========

    localparam [127:0] COEFFICIENTS = 128'h94208510c2c001fb01c0c21085209401;
    // Таблица S: каждый фрагмент содержит 16 последовательных значений.
    localparam [2047:0] PI = {
        128'hfceedd11cf6e3116fbc4fada23c5044d,
        128'he977f0db932e99ba1736f1bb14cd5fc1,
        128'hf918655ae25cef21811c3c428b018e4f,
        128'h058402aee36a8fa0060bed987fd4d31f,
        128'heb342c51eac848abf22a68a2fd3acecc,
        128'hb5700e56080c7612bf7213479cb75d87,
        128'h15a19629107b9ac7f391786f9d9eb2b1,
        128'h3275193dff358a7e6d54c680c3bd0d57,
        128'hdff524a93ea843c9d779d6f67c22b903,
        128'he00fecde7a94b0bcdce828504e330a4a,
        128'ha79760731e0062441ab83882649f2641,
        128'had454692275e552f8ca3a57d69d5953b,
        128'h0758b34086ac1df730376be488d9e789,
        128'he11b83494c3ff8fe8d53aa90cad88561,
        128'h207167a42d2b095bcb9b25d0bee56c52,
        128'h59a674d2e6f4b4c0d166afc2394b63b6
    };

    // Независимое умножение: произведение без переносов и полиномиальное деление.
    function [7:0] ref_multiply;
        input [7:0] a, b;
        reg [15:0] product;
        integer j;
        begin
            product = 0;
            for (j = 0; j < 8; j = j + 1)
                if (b[j]) product = product ^ ({8'b0, a} << j);
            for (j = 14; j >= 8; j = j - 1)
                if (product[j]) product = product ^ (16'h01c3 << (j - 8));
            ref_multiply = product[7:0];
        end
    endfunction

    function [127:0] ref_linear;
        input [127:0] value;
        reg [127:0] block_value;
        reg [7:0] feedback;
        integer step, byte_index;
        begin
            block_value = value;
            for (step = 0; step < 16; step = step + 1) begin
                feedback = 0;
                for (byte_index = 0; byte_index < 16; byte_index = byte_index + 1)
                    feedback = feedback ^ ref_multiply(block_value[127-8*byte_index -: 8], COEFFICIENTS[127-8*byte_index -: 8]);
                block_value = {feedback, block_value[127:8]};
            end
            ref_linear = block_value;
        end
    endfunction

    function [127:0] ref_lsx;
        input [127:0] value, key;
        reg [127:0] transformed;
        integer j;
        begin
            transformed = value ^ key;
            for (j = 0; j < 16; j = j + 1)
                transformed[127-8*j -: 8] = PI[2047-8*transformed[127-8*j -: 8] -: 8];
            ref_lsx = ref_linear(transformed);
        end
    endfunction


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
        input [127:0] left;
        input [127:0] right;
        input [127:0] constant_value;
        reg [127:0] expected;
        reg [127:0] previous_a;
        reg [127:0] previous_b;
        reg [127:0] previous_lsx;
        begin
            @(negedge clk);
            previous_a = a_next;
            previous_b = b_next;
            previous_lsx = lsx;
            a = left;
            b = right;
            k = constant_value;
            expected = ref_lsx(left, constant_value);
            f_enable = 1;
            lsx_enable = 1;
            #0.1;
            check(a_next === previous_a && b_next === previous_b && lsx === previous_lsx,
                  "Registered outputs changed before processing edge");

            @(posedge clk);
            #0.1;
            check(f_done === 1 && lsx_done === 1, "One-cycle result indication mismatch");
            check(a_next === (expected ^ right) && b_next === left, "F pair mismatch");
            check(lsx === expected, "LSX result mismatch");
        end
    endtask

    // ========== Основной сценарий ==========

    initial begin
        rst = 1;
        f_enable = 0;
        lsx_enable = 0;
        a = 0;
        b = 0;
        k = 0;
        TESTS = 0;
        PASSED = 0;

        begin_test("RESET");
        repeat (2) @(posedge clk);
        #0.1;
        check(a_next === 0 && b_next === 0 && lsx === 0 && f_done === 0 && lsx_done === 0,
              "Reset did not clear outputs");
        @(negedge clk);
        rst = 0;
        pass_test;

        begin_test("STANDARD FIRST F AND LSX EXAMPLE");
        run_example(KEY_LEFT, KEY_RIGHT, C1);
        // Фиксированный ответ дополнительно проверяет сам математический эталон.
        check(a_next === FIRST_F && lsx === (FIRST_F ^ KEY_RIGHT), "Standard answer mismatch");
        pass_test;

        begin_test("ALL ZERO INPUTS");
        run_example(0, 0, 0);
        pass_test;

        begin_test("ALL ONE INPUTS");
        run_example({128{1'b1}}, {128{1'b1}}, {128{1'b1}});
        pass_test;

        begin_test("DISABLED INPUT CHANGES AND RESULT HOLD");
        hold_a = a_next;
        hold_b = b_next;
        hold_lsx = lsx;
        repeat (3) begin
            @(negedge clk);
            f_enable = 0;
            lsx_enable = 0;
            a = ~a;
            b = ~b;
            k = ~k;
            @(posedge clk);
            #0.1;
            check(f_done === 0 && lsx_done === 0, "Done did not clear after disable");
            check(a_next === hold_a && b_next === hold_b && lsx === hold_lsx,
                  "Disabled inputs changed a stored result");
        end
        pass_test;

        begin_test("THREE CONSECUTIVE STEPS WITH F FEEDBACK");
        // Следующий шаг F получает фактическую пару предыдущего шага.
        run_example(KEY_LEFT, KEY_RIGHT, C1);
        for (i = 2; i <= 3; i = i + 1)
            run_example(a_next, b_next, ref_linear(i));
        pass_test;

        begin_test("INDEPENDENT ENABLES");
        hold_lsx = lsx;
        @(negedge clk);
        f_enable = 1;
        lsx_enable = 0;
        a = KEY_LEFT;
        b = KEY_RIGHT;
        k = C1;
        @(posedge clk);
        #0.1;
        check(f_done === 1 && a_next === FIRST_F && b_next === KEY_LEFT, "F-only operation failed");
        check(lsx_done === 0 && lsx === hold_lsx, "Disabled LSX changed");
        hold_a = a_next;
        hold_b = b_next;

        @(negedge clk);
        f_enable = 0;
        lsx_enable = 1;
        a = 0;
        k = 0;
        expected_lsx = ref_lsx(a, k);
        @(posedge clk);
        #0.1;
        check(lsx_done === 1 && lsx === expected_lsx, "LSX-only operation failed");
        check(f_done === 0 && a_next === hold_a && b_next === hold_b, "Disabled F changed");
        pass_test;

        begin_test("RESET PRIORITY AND RECOVERY");
        @(negedge clk);
        rst = 1;
        f_enable = 1;
        lsx_enable = 1;
        @(posedge clk);
        #0.1;
        check(a_next === 0 && b_next === 0 && lsx === 0 && f_done === 0 && lsx_done === 0,
              "Enable overrode reset");
        @(negedge clk);
        rst = 0;
        f_enable = 0;
        lsx_enable = 0;
        run_example(KEY_LEFT, KEY_RIGHT, C1);
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        if (PASSED == TESTS)
            $display("ALL PASS: F and LSX; %0d scenarios", TESTS);
        else
            $display("FAIL: F and LSX summary");
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: F and LSX timeout");
        $finish;
    end

endmodule
