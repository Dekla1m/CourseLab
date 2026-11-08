`timescale 1ns / 1ps

// Проверка одного kuz_TOP. Формирователь сообщений заменён готовыми блоками.

module tb_kuz_top;

    localparam integer ENC_LATENCY = 10;
    localparam integer DEC_LATENCY = 10;

    localparam [255:0] KEY = 256'h8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef;

    // Строка из 22 символов занимает два блока. Второй дополнен 80 hex и нулями.
    localparam [127:0] PLAIN_FIRST = "abcdefghijklmnop";
    localparam [127:0] PLAIN_LAST  = {"qrstuv", 8'h80, 72'b0};

    // Программный эталон считает L через 16 шагов R и проверен на векторе RFC 7801.
    localparam [127:0] CIPHER_FIRST = 128'hef95dc3b6f289b46d336a03435fb3be9;
    localparam [127:0] CIPHER_LAST  = 128'h15791b7a77614170684f77afaefd1234;

    reg         clk;
    reg         rst;
    reg         btn_pulse;
    reg [127:0] data_input;
    reg [255:0] start_key_input;
    reg         key_input_valid;
    reg         data_input_valid;
    reg         data_input_last;

    wire         key_input_ready;
    wire         round_keys_ready;
    wire         data_input_ready;
    wire [127:0] data_output;
    wire         data_output_valid;
    wire         data_output_last;
    wire         busy_all_message;
    wire         switch_mode_pulse;

    integer TESTS;
    integer PASSED;
    integer cycle_number;
    integer accepted_cycle;       // Номер фронта фактического приёма последнего блока.
    integer accepted_blocks;
    integer accepted_keys;
    integer completed_blocks;
    integer mode_switches;
    integer before_accept;

    reg [127:0] first_cipher;
    reg [127:0] last_cipher;
    reg [127:0] first_plain;
    reg [127:0] last_plain;


    // ========== Проверяемый модуль ==========

    kuz_TOP dut (
        .clk(clk),
        .rst(rst),
        .btn_pulse(btn_pulse),

        .data_input(data_input),
        .start_key_input(start_key_input),
        .key_input_valid(key_input_valid),
        .key_input_ready(key_input_ready),
        .round_keys_ready(round_keys_ready),
        .data_input_valid(data_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(data_input_ready),

        .data_output(data_output),
        .data_output_valid(data_output_valid),
        .data_output_last(data_output_last),
        .busy_all_message(busy_all_message),
        .switch_mode_pulse(switch_mode_pulse)
    );


    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Handshake берётся до обновления регистров, импульсы проверяются после.
    always @(posedge clk) begin
        cycle_number = cycle_number + 1;

        if (!rst && data_input_valid && data_input_ready) begin
            accepted_cycle = cycle_number;
            accepted_blocks = accepted_blocks + 1;
        end

        if (!rst && key_input_valid && key_input_ready)
            accepted_keys = accepted_keys + 1;

        #0.2;
        if (!rst && data_output_valid)
            completed_blocks = completed_blocks + 1;

        if (!rst && switch_mode_pulse)
            mode_switches = mode_switches + 1;
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

    task sample_edge;
        begin
            @(posedge clk);
            #0.3;
        end
    endtask

    task reset_core;
        begin
            @(negedge clk);
            rst = 1;
            btn_pulse = 0;
            key_input_valid = 0;
            data_input_valid = 0;

            sample_edge;
            check(data_input_ready === 0 && data_output_valid === 0 &&
                  data_output === 0 && data_output_last === 0 &&
                  busy_all_message === 0 && switch_mode_pulse === 0,
                  "Reset did not clear the interface");

            @(negedge clk);
            rst = 0;
            sample_edge;
            check(data_input_ready === 0 && round_keys_ready === 0 &&
                  key_input_ready === 1 && data_output_valid === 0 &&
                  busy_all_message === 0 && switch_mode_pulse === 0,
                  "Core did not return to idle after reset");
        end
    endtask

    task wait_for_keys;
        integer elapsed;
        begin
            for (elapsed = 1; elapsed < 33; elapsed = elapsed + 1) begin
                sample_edge;
                check(round_keys_ready === 0 && data_input_ready === 0,
                      "A block could enter during key preparation");
            end
            sample_edge;
            check(round_keys_ready === 1 && data_input_ready === 1,
                  "Prepared keys did not open the data input");
        end
    endtask

    task load_key;
        input [255:0] key;
        integer previous_keys;
        begin
            @(negedge clk);
            previous_keys = accepted_keys;
            start_key_input = key;
            key_input_valid = 1'b1;
            sample_edge;
            check(accepted_keys == previous_keys + 1, "Key request was not accepted");
            @(negedge clk);
            key_input_valid = 1'b0;
            wait_for_keys;
        end
    endtask

    task launch_block;
        input [127:0] block_value;
        input last_block;
        integer previous_accepts;
        begin
            @(negedge clk);
            check(data_input_ready === 1, "Core is not ready for this block");
            previous_accepts = accepted_blocks;
            data_input = block_value;
            data_input_valid = 1;
            data_input_last = last_block;

            sample_edge;
            check(accepted_blocks == previous_accepts + 1 && data_input_ready === 0 &&
                  busy_all_message === 1 && data_output_valid === 0,
                  "Block was not accepted exactly once");
        end
    endtask

    task release_input;
        begin
            @(negedge clk);
            data_input_valid = 0;
            data_input = ~data_input;
            data_input_last = !data_input_last;
        end
    endtask

    task expect_result;
        input [127:0] expected_data;
        input expected_last;
        input integer latency;
        integer result_cycle;
        reg [127:0] held_data;
        reg held_last;
        begin
            result_cycle = accepted_cycle + latency;
            held_data = data_output;
            held_last = data_output_last;

            while (cycle_number < result_cycle) begin
                sample_edge;
                if (cycle_number < result_cycle) begin
                    check(data_input_ready === 0 && data_output_valid === 0 &&
                          busy_all_message === 1 && switch_mode_pulse === 0,
                          "Premature ready, result or mode switch");
                    check(data_output === held_data && data_output_last === held_last,
                          "Output changed during block processing");
                end
            end

            check(cycle_number == result_cycle && data_output_valid === 1,
                  "Result did not arrive at the expected latency");
            check(data_output_last === expected_last && busy_all_message === !expected_last &&
                  switch_mode_pulse === 0, "Incorrect last, busy or early mode switch");

            if (data_output !== expected_data) begin
                $display("Actual=%032h expected=%032h", data_output, expected_data);
                check(0, "Result data mismatch");
            end
        end
    endtask

    task run_block;
        input [127:0] block_value;
        input [127:0] expected_data;
        input last_block;
        input integer latency;
        begin
            launch_block(block_value, last_block);
            release_input;
            expect_result(expected_data, last_block, latency);
        end
    endtask

    task expect_mode_switch;
        begin
            sample_edge;
            check(switch_mode_pulse === 1 && data_output_valid === 0 &&
                  busy_all_message === 0, "Expected one mode switch after the completed result");
        end
    endtask

    task switch_idle_mode;
        begin
            @(negedge clk);
            btn_pulse = 1;
            expect_mode_switch;

            @(negedge clk);
            btn_pulse = 0;
            sample_edge;
            check(switch_mode_pulse === 0 && data_input_ready === 1,
                  "Mode notification did not clear after one cycle");
        end
    endtask


    // ========== Основной сценарий ==========

    initial begin
        rst = 1;
        btn_pulse = 0;
        data_input = 0;
        start_key_input = 0;
        key_input_valid = 0;
        data_input_valid = 0;
        data_input_last = 0;

        TESTS = 0;
        PASSED = 0;
        cycle_number = 0;
        accepted_cycle = 0;
        accepted_blocks = 0;
        accepted_keys = 0;
        completed_blocks = 0;
        mode_switches = 0;

        begin_test("ENC -> DEC -> ENC, 22 CHARACTERS IN TWO BLOCKS");
        reset_core;
        load_key(KEY);
        run_block(PLAIN_FIRST, CIPHER_FIRST, 1'b0, ENC_LATENCY);
        first_cipher = data_output;
        run_block(PLAIN_LAST, CIPHER_LAST, 1'b1, ENC_LATENCY);
        last_cipher = data_output;

        switch_idle_mode;
        run_block(first_cipher, PLAIN_FIRST, 1'b0, DEC_LATENCY);
        first_plain = data_output;
        run_block(last_cipher, PLAIN_LAST, 1'b1, DEC_LATENCY);
        last_plain = data_output;

        switch_idle_mode;
        run_block(first_plain, first_cipher, 1'b0, ENC_LATENCY);
        run_block(last_plain, last_cipher, 1'b1, ENC_LATENCY);
        check(accepted_blocks == 6 && completed_blocks == 6 && mode_switches == 2 && accepted_keys == 1,
              "Round-trip block or mode switch totals mismatch");
        pass_test;

        begin_test("BUTTON REQUEST BETWEEN MESSAGE BLOCKS");
        run_block(PLAIN_FIRST, CIPHER_FIRST, 1'b0, ENC_LATENCY);

        @(negedge clk);
        btn_pulse = 1;
        sample_edge;
        check(busy_all_message === 1 && data_input_ready === 1 && switch_mode_pulse === 0,
              "Button in the inter-block gap changed the active mode");

        @(negedge clk);
        btn_pulse = 0;
        sample_edge;
        check(busy_all_message === 1 && data_output_valid === 0 && switch_mode_pulse === 0,
              "Deferred request broke the inter-block gap");

        run_block(PLAIN_LAST, CIPHER_LAST, 1'b1, ENC_LATENCY);
        check(data_input_ready === 0, "Pending mode switch must block the next block");
        expect_mode_switch;
        sample_edge;
        check(switch_mode_pulse === 0 && data_input_ready === 1 && mode_switches == 3,
              "Deferred mode change was not reported exactly once");
        pass_test;

        begin_test("BUTTON AND INPUT VALID ON THE SAME EDGE");
        @(negedge clk);
        before_accept = accepted_blocks;
        btn_pulse = 1;
        data_input = PLAIN_FIRST;
        data_input_valid = 1;
        data_input_last = 1;

        // Внешнего ready=0 недостаточно, если внутренний valid дойдёт до ядра.
        #0.1;
        check(data_input_ready === 0 && dut.enc_input_valid === 0 && dut.dec_input_valid === 0,
              "A core can see valid on the switching edge");

        expect_mode_switch;
        check(accepted_blocks == before_accept, "Block was accepted while changing mode");

        @(negedge clk);
        btn_pulse = 0;
        sample_edge;
        check(accepted_blocks == before_accept + 1 && switch_mode_pulse === 0 &&
              busy_all_message === 1, "Held request was not accepted in the new mode");

        release_input;
        expect_result(CIPHER_FIRST, 1'b1, ENC_LATENCY);
        pass_test;

        begin_test("RESET CLEARS A DEFERRED REQUEST AND RESTORES ENC");
        switch_idle_mode;
        launch_block(CIPHER_FIRST, 1'b0);
        release_input;

        @(negedge clk);
        btn_pulse = 1;
        sample_edge;
        check(busy_all_message === 1 && switch_mode_pulse === 0,
              "Button request was not deferred during decryption");

        reset_core;

        // Полная задержка DEC даёт отменённой операции время проявиться при ошибке сброса.
        repeat (DEC_LATENCY + 1) begin
            sample_edge;
            check(data_output_valid === 0 && switch_mode_pulse === 0 &&
                  busy_all_message === 0 && data_input_ready === 0 && round_keys_ready === 0,
                  "Aborted operation or deferred request survived reset");
        end

        load_key(KEY);
        run_block(PLAIN_LAST, CIPHER_LAST, 1'b1, ENC_LATENCY);
        sample_edge;
        check(data_output_valid === 0 && data_input_ready === 1 &&
              busy_all_message === 0 && switch_mode_pulse === 0,
              "Final result or mode change pulse did not clear");
        check(accepted_blocks == 11 && completed_blocks == 10 && mode_switches == 5,
              "Overall accepted, completed and switched totals mismatch");
        pass_test;

        begin_test("BLOCK PRIORITY, KEY HELD UNTIL LAST RESULT, NEW CIPHERTEXT");
        @(negedge clk);
        before_accept = accepted_blocks;
        start_key_input = 0;
        key_input_valid = 1'b1;
        data_input = PLAIN_FIRST;
        data_input_valid = 1'b1;
        data_input_last = 1'b0;
        sample_edge;
        check(accepted_blocks == before_accept + 1 && accepted_keys == 2,
              "Key update took priority over the first block");
        release_input;
        expect_result(CIPHER_FIRST, 1'b0, ENC_LATENCY);
        sample_edge;
        check(key_input_ready === 0 && accepted_keys == 2 && round_keys_ready === 1,
              "Key accepted in the gap inside the message");

        run_block(PLAIN_LAST, CIPHER_LAST, 1'b1, ENC_LATENCY);
        sample_edge;
        check(accepted_keys == 3 && round_keys_ready === 0,
              "Deferred key was not accepted after the last result");
        @(negedge clk);
        key_input_valid = 1'b0;
        wait_for_keys;
        run_block(128'b0, 128'h98cc6b54dbcf7bd2f0800c1fab0677ef, 1'b1, ENC_LATENCY);
        check(accepted_keys == 3 && completed_blocks == 13, "Unexpected block or key count");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        $display("ALL PASS: kuz_TOP; %0d scenarios; %0d blocks; ENC=%0d DEC=%0d",
                 PASSED, completed_blocks, ENC_LATENCY, DEC_LATENCY);
        $finish;
    end

    initial begin
        #20000;
        $display("FAIL: kuz_TOP timeout");
        $finish;
    end

endmodule

`default_nettype wire
