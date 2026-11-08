`timescale 1ns / 1ps
`default_nettype none

// Один DUT: проверяются шифрование, расписание и интерфейс Encrypt_TOP.
// Эталон вычисляет L через полиномиальное умножение, независимо от матриц RTL.
module tb_encrypt_top;

    reg clk;
    reg rst;
    reg data_input_valid;
    reg data_input_last;
    reg [127:0] data_input;
    reg [255:0] start_key_input;

    wire data_input_ready;
    wire [127:0] data_output;
    wire data_output_valid;
    wire data_output_last;
    wire busy_all_message;

    integer TESTS;
    integer PASSED;
    integer blocks;
    integer cycles;
    integer key_steps;
    integer data_rounds;
    integer pair_index;
    integer last_key_cycle;
    integer overlap_cycles;             // Такты, в которых одновременно работают F и LSX.
    reg checking;                       // Разрешение проверки внутренних ключей текущего блока.

    reg expected_message_busy;          // Модель занятости сообщением, включая паузы между блоками.
    reg pending;                        // Есть принятый блок, для которого ещё не получен результат.
    reg expected_last;
    reg held_last;
    reg [127:0] held_result;
    integer acceptance_cycle;
    integer accepted_total;
    integer completed_total;

    reg [127:0] expected_keys [0:9];     // Раундовые ключи независимого эталона.
    reg [127:0] rfc_keys [0:9];          // Контрольные ключи стандартного примера.

    // ========== Проверяемый модуль ==========

    Encrypt_TOP dut (
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

    // ========== Тактирование ==========

    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;
    end

    // Счётчик меняется на спаде: мониторы фронта читают его без гонки.
    always @(negedge clk)
        cycles = cycles + 1;

    // ========== Независимый математический эталон ==========

    localparam [255:0] RFC_KEY = 256'h8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef;
    localparam [127:0] RFC_INPUT = 128'h1122334455667700ffeeddccbbaa9988;
    localparam [127:0] RFC_OUTPUT = 128'h7f679d90bebc24305a468d42b9d4edcd;
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
        input [7:0] a;
        input [7:0] b;
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
        integer step;
        integer byte_index;
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
        input [127:0] value;
        input [127:0] key;
        reg [127:0] transformed;
        integer j;
        begin
            transformed = value ^ key;
            for (j = 0; j < 16; j = j + 1)
                transformed[127-8*j -: 8] = PI[2047-8*transformed[127-8*j -: 8] -: 8];
            ref_lsx = ref_linear(transformed);
        end
    endfunction

    // Эталон: разворачивает key в expected_keys и шифрует plaintext в ciphertext.
    task reference_encrypt;
        input [127:0] plaintext;
        input [255:0] key;
        output [127:0] ciphertext;
        reg [127:0] left;
        reg [127:0] right;
        reg [127:0] previous_left;
        reg [127:0] state_value;
        reg [127:0] ci;
        integer step;
        integer index;
        begin
            left = key[255:128];
            right = key[127:0];
            expected_keys[0] = left;
            expected_keys[1] = right;
            for (step = 1; step <= 32; step = step + 1) begin
                ci = ref_linear(step);
                previous_left = left;
                left = ref_lsx(left, ci) ^ right;
                right = previous_left;
                if (step % 8 == 0) begin
                    expected_keys[step/4] = left;
                    expected_keys[step/4+1] = right;
                end
            end
            state_value = plaintext;
            for (index = 0; index < 9; index = index + 1)
                state_value = ref_lsx(state_value, expected_keys[index]);
            ciphertext = state_value ^ expected_keys[9];
        end
    endtask

    // ========== Контроль интерфейса и расписания ==========

    always @(posedge clk) begin
        if (rst) begin
            pending = 0;
            expected_message_busy = 0;
        end else if (data_input_valid && data_input_ready) begin
            check(pending === 0, "Second input accepted before completing the previous block");
            pending = 1;
            expected_message_busy = 1;
            expected_last = data_input_last;
            acceptance_cycle = cycles;
            accepted_total = accepted_total + 1;
        end

        // Приём фиксируется до NBA, выходы проверяются после обновления регистров.
        #0.2;
        if (rst) begin
            check(data_input_ready === 0 && data_output_valid === 0 &&
                  data_output_last === 0 && busy_all_message === 0, "Reset interface mismatch");
            held_result = 0;
            held_last = 0;
        end else begin
            if (data_output_valid === 1'b1) begin
                check(pending === 1 && data_output_last === expected_last,
                      "Unexpected result, duplicate result or wrong last");
                check(cycles - acceptance_cycle == 35, "Latency is not 35 cycles");
                pending = 0;
                if (expected_last)
                    expected_message_busy = 0;
                completed_total = completed_total + 1;
                held_result = data_output;
                held_last = data_output_last;
            end else begin
                check(data_output_valid === 0 && data_output === held_result &&
                      data_output_last === held_last, "Output changed without a valid result");
            end

            check(data_input_ready === !pending, "Ready does not match outstanding operation");
            check(busy_all_message === expected_message_busy, "Message busy mismatch");
        end
    end

    always @(posedge clk) begin
        if (!rst && checking) begin
            if (dut.data_round_enable) begin
                check(dut.current_key === expected_keys[data_rounds], "Wrong key at data round input");
                data_rounds = data_rounds + 1;
            end
            if (dut.data_round_enable && dut.key_step_enable)
                overlap_cycles = overlap_cycles + 1;

            if (dut.key_step_enable) begin
                // Проверяется константа именно внутри TOP; отдельного DUT таблицы нет.
                check(dut.current_Ci_index === key_steps + 1 &&
                      dut.current_Ci === ref_linear(key_steps + 1), "Wrong Ci or Ci index inside TOP");
                if (key_steps > 0)
                    check(cycles - last_key_cycle == 1, "Idle cycle between F steps");
                last_key_cycle = cycles;
                key_steps = key_steps + 1;
            end
            if (dut.capture_key_pair) begin
                pair_index = dut.key_step_count / 4;
                check(dut.next_key_state === {expected_keys[pair_index], expected_keys[pair_index+1]},
                      "Expanded round-key pair mismatch");
            end
        end
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

    // Входы меняются после приёма, чтобы проверить их фиксацию внутри TOP.
    task check_block;
        input [127:0] plaintext;
        input [255:0] key;
        input last_block;
        reg [127:0] expected;
        reg [127:0] held;
        integer accepted_cycle;
        integer waited;
        integer j;
        begin
            reference_encrypt(plaintext, key, expected);
            if (blocks == 0) begin
                check(expected === RFC_OUTPUT, "Reference standard ciphertext mismatch");
                for (j = 0; j < 10; j = j + 1)
                    check(expected_keys[j] === rfc_keys[j], "Reference standard round key mismatch");
            end

            @(negedge clk);
            check(data_input_ready === 1, "Idle core is not ready");
            checking = 1;
            key_steps = 0;
            data_rounds = 0;
            overlap_cycles = 0;
            data_input = plaintext;
            start_key_input = key;
            data_input_valid = 1;
            data_input_last = last_block;
            @(posedge clk);
            #0.1;
            accepted_cycle = cycles;

            @(negedge clk);
            data_input_valid = 0;
            data_input = ~plaintext;
            start_key_input = ~key;
            data_input_last = !last_block;

            waited = 0;
            while (data_output_valid !== 1'b1 && waited < 40) begin
                @(posedge clk);
                #0.1;
                waited = waited + 1;
            end
            check(data_output_valid === 1, "Encrypt_TOP result timeout");
            if (data_output !== expected) begin
                $display("Actual=%032h expected=%032h", data_output, expected);
                check(0, "Ciphertext mismatch");
            end
            check(key_steps == 32 && data_rounds == 9 && overlap_cycles == 8,
                  "F/LSX operation counts or overlap mismatch");
            check(cycles - accepted_cycle == 35, "Latency is not 35 cycles");
            blocks = blocks + 1;
            checking = 0;
            held = data_output;

            repeat (2) begin
                @(posedge clk);
                #0.3;
                check(data_output_valid === 0 && data_output === held,
                      "Result pulse or idle output hold mismatch");
            end
        end
    endtask

    // Второй запрос удерживается при ready=0 до первого разрешённого фронта.
    task check_waiting_request;
        reg [127:0] first_expected;
        reg [127:0] second_expected;
        integer first_cycle;
        integer second_cycle;
        integer waited;
        begin
            reference_encrypt(RFC_INPUT, RFC_KEY, first_expected);
            @(negedge clk);
            checking = 1;
            key_steps = 0;
            data_rounds = 0;
            overlap_cycles = 0;
            data_input = RFC_INPUT;
            start_key_input = RFC_KEY;
            data_input_last = 0;
            data_input_valid = 1;
            @(posedge clk);
            #0.1;
            first_cycle = cycles;
            @(negedge clk);
            data_input_valid = 0;

            repeat (5) @(negedge clk);
            check(data_input_ready === 0, "Busy core accepted another block");
            data_input = 0;
            start_key_input = RFC_KEY;
            data_input_last = 1;
            data_input_valid = 1;

            waited = 0;
            while (data_output_valid !== 1'b1 && waited < 40) begin
                @(posedge clk);
                #0.1;
                waited = waited + 1;
            end
            check(data_output_valid === 1 && data_output === first_expected && data_output_last === 0,
                  "Waiting input changed the first result");
            check(cycles - first_cycle == 35 && key_steps == 32 && data_rounds == 9 && overlap_cycles == 8,
                  "First operation schedule mismatch");
            blocks = blocks + 1;

            reference_encrypt(0, RFC_KEY, second_expected);
            key_steps = 0;
            data_rounds = 0;
            overlap_cycles = 0;
            @(posedge clk);
            #0.1;
            second_cycle = cycles;
            check(second_cycle - first_cycle == 36 && data_input_ready === 0 && data_output_valid === 0,
                  "Waiting request was not accepted on the first free edge");
            @(negedge clk);
            data_input_valid = 0;
            data_input_last = 0;
            data_input = RFC_INPUT;

            waited = 0;
            while (data_output_valid !== 1'b1 && waited < 40) begin
                @(posedge clk);
                #0.1;
                waited = waited + 1;
            end
            check(data_output_valid === 1 && data_output === second_expected && data_output_last === 1,
                  "Waiting block result or last mismatch");
            check(cycles - second_cycle == 35 && key_steps == 32 && data_rounds == 9 && overlap_cycles == 8,
                  "Waiting operation schedule mismatch");
            blocks = blocks + 1;
            checking = 0;

            // Ждём больше полной задержки, чтобы обнаружить лишний принятый запрос.
            repeat (40) @(negedge clk);
            check(data_output_valid === 0 && pending === 0, "Duplicate operation after held request");
        end
    endtask

    task abort_block;
        input integer delay_cycles;
        begin
            @(negedge clk);
            check(data_input_ready === 1, "Abort scenario started while busy");
            data_input = RFC_INPUT;
            start_key_input = RFC_KEY;
            data_input_valid = 1;
            data_input_last = 1;
            @(negedge clk);
            data_input_valid = 0;
            repeat (delay_cycles) @(negedge clk);
            rst = 1;
            data_input_valid = 1;
            @(posedge clk);
            #0.3;
            check(data_output_valid === 0 && data_output === 0 && data_output_last === 0 &&
                  data_input_ready === 0 && dut.key_step_count === 0 && dut.busy === 0,
                  "Reset did not override processing and input valid");
            @(negedge clk);
            rst = 0;
            data_input_valid = 0;

            repeat (36) begin
                @(posedge clk);
                #0.3;
                check(data_output_valid === 0, "Aborted operation produced a result");
            end
        end
    endtask

    // ========== Основной сценарий ==========

    initial begin
        rst = 1;
        data_input_valid = 0;
        data_input_last = 0;
        data_input = 0;
        start_key_input = 0;
        TESTS = 0;
        PASSED = 0;
        blocks = 0;
        cycles = 0;
        key_steps = 0;
        data_rounds = 0;
        overlap_cycles = 0;
        checking = 0;
        expected_message_busy = 0;
        pending = 0;
        expected_last = 0;
        held_last = 0;
        held_result = 0;
        acceptance_cycle = 0;
        accepted_total = 0;
        completed_total = 0;

        rfc_keys[0] = RFC_KEY[255:128];
        rfc_keys[1] = RFC_KEY[127:0];
        rfc_keys[2] = 128'hdb31485315694343228d6aef8cc78c44;
        rfc_keys[3] = 128'h3d4553d8e9cfec6815ebadc40a9ffd04;
        rfc_keys[4] = 128'h57646468c44a5e28d3e59246f429f1ac;
        rfc_keys[5] = 128'hbd079435165c6432b532e82834da581b;
        rfc_keys[6] = 128'h51e640757e8745de705727265a0098b1;
        rfc_keys[7] = 128'h5a7925017b9fdd3ed72a91a22286f984;
        rfc_keys[8] = 128'hbb44e25378c73123a5f32f73cdb6e517;
        rfc_keys[9] = 128'h72e9dd7416bcf45b755dbaa88e4a4043;

        begin_test("RESET AND IDLE INTERFACE");
        repeat (2) @(posedge clk);
        #0.3;
        check(data_input_ready === 0 && data_output_valid === 0 && busy_all_message === 0,
              "Reset interface mismatch");
        @(negedge clk);
        rst = 0;
        @(posedge clk);
        #0.3;
        check(data_input_ready === 1 && data_output_valid === 0 && busy_all_message === 0,
              "Idle core is not ready");
        pass_test;

        begin_test("STANDARD CIPHERTEXT AND ALL ROUND KEYS");
        check_block(RFC_INPUT, RFC_KEY, 1);
        pass_test;

        begin_test("ZERO DATA AND ZERO KEY");
        check_block(0, 0, 1);
        pass_test;

        begin_test("ALL ONE DATA AND KEY");
        check_block({128{1'b1}}, {256{1'b1}}, 1);
        pass_test;

        begin_test("RESET IMMEDIATELY AFTER ACCEPTANCE");
        abort_block(0);
        pass_test;

        begin_test("RESET DURING PARALLEL F AND LSX");
        abort_block(1);
        pass_test;

        begin_test("RESET DURING KEY EXPANSION");
        abort_block(7);
        pass_test;

        begin_test("RESET BEFORE THE RESULT EDGE");
        abort_block(34);
        pass_test;

        begin_test("ENCRYPTION AFTER RESET");
        check_block(RFC_INPUT, RFC_KEY, 1);
        pass_test;

        begin_test("MESSAGE LAST=0,0,1 AND INTER-BLOCK GAPS");
        check_block(RFC_INPUT, RFC_KEY, 0);
        repeat (7) @(negedge clk);
        check(busy_all_message === 1 && data_input_ready === 1,
              "Message lock lost during first gap");
        check_block(0, RFC_KEY, 0);
        repeat (11) @(negedge clk);
        check(busy_all_message === 1 && data_input_ready === 1,
              "Message lock lost during second gap");
        check_block({128{1'b1}}, RFC_KEY, 1);
        check(busy_all_message === 0, "Last result did not release message busy");
        pass_test;

        begin_test("HELD REQUEST, FIRST FREE EDGE AND NO DUPLICATES");
        check_waiting_request;
        check(completed_total == 9 && accepted_total == 13 && blocks == 9 &&
              pending === 0 && busy_all_message === 0, "Transaction totals mismatch");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        if (PASSED == TESTS)
            $display("ALL PASS: Encrypt_TOP; %0d scenarios; %0d blocks; latency=35", TESTS, blocks);
        else
            $display("FAIL: Encrypt_TOP summary");
        $finish;
    end

    initial begin
        #20000;
        $display("FAIL: Encrypt_TOP timeout");
        $finish;
    end

endmodule
`default_nettype wire
