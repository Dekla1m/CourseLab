`timescale 1ns / 1ps

// Один DUT. Фиксированные векторы и проверка интерфейса по фронтам clk.

module tb_decrypt_top;

    localparam integer LATENCY = 10;

    localparam [255:0] RFC_KEY = 256'h8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef;
    localparam [127:0] RFC_CIPHER = 128'h7f679d90bebc24305a468d42b9d4edcd;
    localparam [127:0] RFC_PLAIN  = 128'h1122334455667700ffeeddccbbaa9988;
    localparam [127:0] RFC_FIRST_INVERSE = 128'h76ca149eef27d1b10d17e3d5d68e5a72;
    localparam [127:0] RFC_LAST_INVERSE  = 128'h99bb99ff99bb99ffffffffffffffffff;

    // Значения рассчитаны программным эталоном через 16 шагов R.
    localparam [127:0] ZERO_CIPHER = 128'h98cc6b54dbcf7bd2f0800c1fab0677ef;
    localparam [127:0] ONES_CIPHER = 128'h0e697e9f0587a38c908454ac39e1c463;

    // Эталонные наборы для модели банка ключей. K1 занимает старшие 128 бит.
    localparam [1279:0] RFC_KEYS = {
        128'h8899aabbccddeeff0011223344556677, 128'hfedcba98765432100123456789abcdef,
        128'hdb31485315694343228d6aef8cc78c44, 128'h3d4553d8e9cfec6815ebadc40a9ffd04,
        128'h57646468c44a5e28d3e59246f429f1ac, 128'hbd079435165c6432b532e82834da581b,
        128'h51e640757e8745de705727265a0098b1, 128'h5a7925017b9fdd3ed72a91a22286f984,
        128'hbb44e25378c73123a5f32f73cdb6e517, 128'h72e9dd7416bcf45b755dbaa88e4a4043
    };
    localparam [1279:0] ZERO_KEYS = {
        128'h00000000000000000000000000000000, 128'h00000000000000000000000000000000,
        128'hd7e5947c30b506702a4f8be01e49f157, 128'h374d255d7d0febc6b0205b0ce5916145,
        128'hc15446aa1feeb6db4806751155e0386e, 128'h718c5e8a75e7186038aeeed50c1fb72d,
        128'h5bdf9ba55b4668dc436895951b6855cc, 128'h70804dc50f238f839409bcaed4322502,
        128'h528ba9f04997c2684b01a4944e91c0f1, 128'h491b9222400a7c584f13a7f67a2db897
    };
    localparam [1279:0] ONES_KEYS = {
        128'hffffffffffffffffffffffffffffffff, 128'hffffffffffffffffffffffffffffffff,
        128'hd474a3450f37ac64c2e6958a056b0da0, 128'h01af6b82631a03261135b1fb30176ae1,
        128'hbfd23b89d92fc7d9e856f52882cc5002, 128'h0458cfc521197643a8ccb22ca4ac0edc,
        128'h43a45b1c857cac19d17e0edc85de8c16, 128'h4d4a76637cad83f96cc16e4c12ecc843,
        128'h966bde626ea2f76bd2e2773db71767df, 128'h465077194bf76002a5ffdc99defe76eb
    };

    reg         clk;
    reg         rst;
    reg [127:0] data_input;
    reg [1279:0] test_keys;
    reg [127:0] round_key_input;
    reg         data_input_valid;
    reg         data_input_last;

    wire [3:0]   round_key_read_index;
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
        .data_input_valid(data_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(data_input_ready),
        .round_key_read_index(round_key_read_index),
        .round_key_input(round_key_input),

        .data_output(data_output),
        .data_output_valid(data_output_valid),
        .data_output_last(data_output_last),
        .busy_all_message(busy_all_message)
    );


    always @(posedge clk) begin
        if (rst)
            round_key_input <= 128'b0;
        else
            round_key_input <= test_keys[1279-128*round_key_read_index -: 128];
    end


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
            case (key)
                RFC_KEY: test_keys = RFC_KEYS;
                256'b0:  test_keys = ZERO_KEYS;
                default: test_keys = ONES_KEYS;
            endcase
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

            data_input = ~data_input;
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
                      busy_all_message === 1'b1, "Result or ready appeared before t10");
                check(data_output === held_data && data_output_last === held_last,
                      "Output changed before a result");

                if (check_rfc_rounds && elapsed == 1)
                    check(dut.round_data_output === RFC_FIRST_INVERSE, "RFC first inverse round mismatch");
                if (check_rfc_rounds && elapsed == 9)
                    check(dut.round_data_output === RFC_LAST_INVERSE, "RFC last inverse round mismatch");
            end

            @(posedge clk);
            #0.1;
            check(data_output_valid === 1'b1 && data_input_ready === 1'b1, "Expected a result on t10");
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
        test_keys = RFC_KEYS;
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
        data_input_last = 1;
        data_input_valid = 1;
        expect_result(RFC_PLAIN, 1'b1, 1'b0);
        test_keys = ZERO_KEYS;

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

        begin_test("RESET AFTER THE FIRST INVERSE ROUND");
        abort_block(1);
        pass_test;

        begin_test("RESET DURING INVERSE ROUNDS");
        abort_block(5);
        pass_test;

        begin_test("RESET AT THE RESULT BOUNDARY");
        abort_block(9);
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
