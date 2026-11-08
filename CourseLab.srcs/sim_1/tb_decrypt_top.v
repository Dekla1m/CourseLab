`timescale 1ns / 1ps

// Один DUT. Фиксированные векторы и проверка интерфейса по фронтам clk.

module tb_decrypt_top;

    localparam integer LATENCY = 43;

    localparam [255:0] RFC_KEY = 256'h8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef;
    localparam [127:0] RFC_CIPHER = 128'h7f679d90bebc24305a468d42b9d4edcd;
    localparam [127:0] RFC_PLAIN  = 128'h1122334455667700ffeeddccbbaa9988;
    localparam [127:0] RFC_FIRST_INVERSE = 128'h76ca149eef27d1b10d17e3d5d68e5a72;
    localparam [127:0] RFC_LAST_INVERSE  = 128'h99bb99ff99bb99ffffffffffffffffff;

    // Значения рассчитаны программным эталоном через 16 шагов R.
    localparam [127:0] ZERO_CIPHER = 128'h98cc6b54dbcf7bd2f0800c1fab0677ef;
    localparam [127:0] ONES_CIPHER = 128'h0e697e9f0587a38c908454ac39e1c463;

    reg         clk;
    reg         rst;
    reg [127:0] data_input;
    reg [255:0] start_key_input;
    reg         data_input_valid;
    reg         data_input_last;

    wire         data_input_ready;
    wire [127:0] data_output;
    wire         data_output_valid;
    wire         data_output_last;
    wire         busy_all_message;

    integer TESTS;
    integer PASSED;
    integer accepted_blocks;
    integer completed_blocks;


    // ========== Проверяемый модуль ==========

    Decrypt_TOP dut (
        .clk(clk),
        .rst(rst),

        .data_input(data_input),
        .start_key_input(start_key_input),
        .data_input_valid(data_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(data_input_ready),

        .data_output(data_output),
        .data_output_valid(data_output_valid),
        .data_output_last(data_output_last),
        .busy_all_message(busy_all_message)
    );


    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Приём фиксируется до NBA, результат проверяется после обновления регистров.
    always @(posedge clk) begin
        if (!rst && data_input_valid && data_input_ready)
            accepted_blocks = accepted_blocks + 1;

        #0.2;
        if (!rst && data_output_valid)
            completed_blocks = completed_blocks + 1;
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

    task launch_block;
        input [127:0] cipher;
        input [255:0] key;
        input last_block;
        begin
            @(negedge clk);
            check(data_input_ready === 1'b1, "Core is not ready before request");
            data_input = cipher;
            start_key_input = key;
            data_input_last = last_block;
            data_input_valid = 1'b1;

            @(posedge clk);
            #0.1;
            check(data_input_ready === 1'b0 && data_output_valid === 1'b0 &&
                  busy_all_message === 1'b1, "Input acceptance did not start a block");
        end
    endtask

    task release_input;
        begin
            @(negedge clk);
            data_input_valid = 1'b0;

            // Изменение портов после приёма проверяет фиксацию блока, ключа и last.
            data_input = ~data_input;
            start_key_input = ~start_key_input;
            data_input_last = !data_input_last;
        end
    endtask

    task expect_result;
        input [127:0] expected_plain;
        input expected_last;
        input check_rfc_rounds;
        integer elapsed;
        reg [127:0] held_data;
        reg held_last;
        begin
            held_data = data_output;
            held_last = data_output_last;

            for (elapsed = 1; elapsed < LATENCY; elapsed = elapsed + 1) begin
                @(posedge clk);
                #0.1;
                check(data_input_ready === 1'b0 && data_output_valid === 1'b0 &&
                      busy_all_message === 1'b1, "Result or ready appeared before t43");
                check(data_output === held_data && data_output_last === held_last,
                      "Output changed before a result");

                if (check_rfc_rounds && elapsed == 34)
                    check(dut.round_data_output === RFC_FIRST_INVERSE, "RFC first inverse round mismatch");
                if (check_rfc_rounds && elapsed == 42)
                    check(dut.round_data_output === RFC_LAST_INVERSE, "RFC last inverse round mismatch");
            end

            @(posedge clk);
            #0.1;
            check(data_output_valid === 1'b1 && data_input_ready === 1'b1, "Expected a result on t43");
            check(data_output_last === expected_last && busy_all_message === !expected_last,
                  "Result last or message busy mismatch");

            if (data_output !== expected_plain) begin
                $display("Actual=%032h expected=%032h", data_output, expected_plain);
                check(0, "Plaintext mismatch");
            end
        end
    endtask

    task check_gap;
        input integer cycles;
        input expected_busy;
        reg [127:0] held_data;
        reg held_last;
        begin
            held_data = data_output;
            held_last = data_output_last;

            repeat (cycles) begin
                @(posedge clk);
                #0.1;
                check(data_input_ready === 1'b1 && data_output_valid === 1'b0 &&
                      busy_all_message === expected_busy, "Idle ready, valid or message busy mismatch");
                check(data_output === held_data && data_output_last === held_last,
                      "Result was not held between blocks");
            end
        end
    endtask

    task run_block;
        input [127:0] cipher;
        input [255:0] key;
        input [127:0] plain;
        input last_block;
        input check_rfc_rounds;
        begin
            launch_block(cipher, key, last_block);
            release_input;
            expect_result(plain, last_block, check_rfc_rounds);
            check_gap(1, !last_block);
        end
    endtask

    task abort_block;
        input integer elapsed_cycles;
        begin
            launch_block(RFC_CIPHER, RFC_KEY, 1'b1);
            release_input;

            repeat (elapsed_cycles) begin
                @(posedge clk);
                #0.1;
                check(data_output_valid === 1'b0 && data_input_ready === 1'b0,
                      "Abort scenario left the active operation early");
            end

            @(negedge clk);
            rst = 1'b1;
            data_input_valid = 1'b1;
            @(posedge clk);
            #0.1;
            check(data_output === 0 && data_output_valid === 0 && data_output_last === 0 &&
                  data_input_ready === 0 && busy_all_message === 0, "Reset did not cancel the block");

            @(negedge clk);
            rst = 1'b0;
            data_input_valid = 1'b0;

            // Окно полной задержки обнаруживает запоздалый результат отменённой операции.
            check_gap(LATENCY + 1, 1'b0);
        end
    endtask


    // ========== Основной сценарий ==========

    initial begin
        rst = 1;
        data_input = 0;
        start_key_input = 0;
        data_input_valid = 0;
        data_input_last = 0;
        TESTS = 0;
        PASSED = 0;
        accepted_blocks = 0;
        completed_blocks = 0;

        begin_test("RESET AND IDLE");
        repeat (2) @(posedge clk);
        #0.1;
        check(data_output === 0 && data_output_valid === 0 && data_output_last === 0 &&
              data_input_ready === 0 && busy_all_message === 0, "Reset outputs mismatch");
        @(negedge clk);
        rst = 0;
        check_gap(1, 1'b0);
        pass_test;

        begin_test("RFC 7801 CIPHERTEXT AND INVERSE ROUND VALUES");
        run_block(RFC_CIPHER, RFC_KEY, RFC_PLAIN, 1'b1, 1'b1);
        pass_test;

        begin_test("ZERO KEY AND ZERO PLAINTEXT");
        run_block(ZERO_CIPHER, 256'b0, 128'b0, 1'b1, 1'b0);
        pass_test;

        begin_test("ALL ONE KEY AND PLAINTEXT");
        run_block(ONES_CIPHER, {256{1'b1}}, {128{1'b1}}, 1'b1, 1'b0);
        pass_test;

        begin_test("MESSAGE BUSY ACROSS GAP, LAST=0 THEN LAST=1");
        run_block(RFC_CIPHER, RFC_KEY, RFC_PLAIN, 1'b0, 1'b0);
        check_gap(3, 1'b1);
        run_block(RFC_CIPHER, RFC_KEY, RFC_PLAIN, 1'b1, 1'b0);
        pass_test;

        begin_test("HELD REQUEST ACCEPTED ON THE FIRST FREE EDGE");
        launch_block(RFC_CIPHER, RFC_KEY, 1'b1);
        @(negedge clk);
        data_input = ZERO_CIPHER;
        start_key_input = 0;
        data_input_last = 1;
        data_input_valid = 1;
        expect_result(RFC_PLAIN, 1'b1, 1'b0);

        @(posedge clk);
        check(data_input_valid === 1'b1 && data_input_ready === 1'b1,
              "Waiting request did not reach the first free edge");
        #0.1;
        check(data_input_ready === 1'b0 && data_output_valid === 1'b0 &&
              busy_all_message === 1'b1, "Waiting request was not accepted");
        release_input;
        expect_result(128'b0, 1'b1, 1'b0);
        check_gap(LATENCY + 1, 1'b0);
        pass_test;

        begin_test("RESET DURING KEY EXPANSION");
        abort_block(8);
        pass_test;

        begin_test("RESET DURING INVERSE ROUNDS");
        abort_block(37);
        pass_test;

        begin_test("RESET AT THE RESULT BOUNDARY");
        abort_block(42);
        pass_test;

        begin_test("NEW BLOCK AFTER RESET");
        run_block(ONES_CIPHER, {256{1'b1}}, {128{1'b1}}, 1'b1, 1'b0);
        #0.2;
        check(accepted_blocks == 11 && completed_blocks == 8,
              "Transaction totals do not match accepted, completed and cancelled blocks");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        if (PASSED == TESTS)
            $display("ALL PASS: Decrypt_TOP; %0d scenarios; %0d blocks; latency=%0d",
                     TESTS, completed_blocks, LATENCY);
        else
            $display("FAIL: Decrypt_TOP summary");
        $finish;
    end

    initial begin
        #20000;
        $display("FAIL: Decrypt_TOP timeout");
        $finish;
    end

endmodule

`default_nettype wire
