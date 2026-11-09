`timescale 1ns / 1ps

module tb_kuz_key_loader;

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

    reg clk_core;
    reg clk_keys;
    reg rst;
    reg [255:0] start_key_input;
    reg key_input_valid;
    reg round_keys_ready;

    wire key_input_ready;
    wire key_update_pending;
    wire [1279:0] round_keys;
    wire round_keys_valid;

    integer TESTS;
    integer PASSED;
    integer transfers;


    kuz_key_loader DUT (
        .clk_core(clk_core),
        .rst_core(rst),
        .clk_keys(clk_keys),
        .rst_keys(rst),
        .start_key_input(start_key_input),
        .key_input_valid(key_input_valid),
        .key_input_ready(key_input_ready),
        .key_update_pending(key_update_pending),
        .round_keys(round_keys),
        .round_keys_valid(round_keys_valid),
        .round_keys_ready(round_keys_ready)
    );


    initial begin
        clk_core = 0;
        forever #2.5 clk_core = ~clk_core;
    end

    // Сдвиг фронтов проверяет, что результат не зависит от их совпадения.
    initial begin
        clk_keys = 0;
        #1;
        forever #5 clk_keys = ~clk_keys;
    end

    always @(posedge clk_core) begin
        if (!rst && round_keys_valid && round_keys_ready)
            transfers = transfers + 1;
    end


    task begin_test;
        input [8*80-1:0] name;
        begin
            TESTS = TESTS + 1;
            $display("\nTEST %0d: %0s", TESTS, name);
        end
    endtask

    task check;
        input condition;
        input [8*100-1:0] message;
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

    task sample_core;
        begin
            @(posedge clk_core);
            #0.2;
        end
    endtask

    task reset_loader;
        begin
            @(negedge clk_core);
            rst = 1;
            key_input_valid = 0;
            round_keys_ready = 0;

            repeat (4) sample_core;
            check(key_input_ready === 0 && key_update_pending === 0 && round_keys_valid === 0,
                  "Reset did not clear the request");

            @(negedge clk_core);
            rst = 0;
            sample_core;
            check(key_input_ready === 1 && round_keys_valid === 0,
                  "Loader did not return to idle");
        end
    endtask

    task send_key;
        input [255:0] key;
        begin
            @(negedge clk_core);
            check(key_input_ready === 1, "Loader is not ready for the key");
            start_key_input = key;
            key_input_valid = 1;
            sample_core;
            check(key_update_pending === 1 && key_input_ready === 0 && round_keys_valid === 0,
                  "Request was not captured exactly once");

            @(negedge clk_core);
            key_input_valid = 0;
            start_key_input = ~key;
        end
    endtask

    task expect_keys;
        input [1279:0] expected;
        input integer limit;
        integer elapsed;
        begin
            elapsed = 0;
            while (round_keys_valid === 0 && elapsed < limit) begin
                sample_core;
                elapsed = elapsed + 1;
            end
            check(round_keys_valid === 1 && round_keys === expected && key_input_ready === 0,
                  "Key set is missing or differs from the reference");
        end
    endtask

    task accept_keys;
        integer previous_transfers;
        begin
            @(negedge clk_core);
            previous_transfers = transfers;
            round_keys_ready = 1;

            sample_core;
            check(transfers == previous_transfers + 1 && round_keys_valid === 0 &&
                  key_update_pending === 0 && key_input_ready === 1,
                  "Acknowledgement did not release the loader");

            sample_core;
            check(transfers == previous_transfers + 1, "Key set was transferred twice");
            @(negedge clk_core);
            round_keys_ready = 0;
        end
    endtask


    initial begin
        TESTS = 0;
        PASSED = 0;
        transfers = 0;
        rst = 1;
        start_key_input = 0;
        key_input_valid = 0;
        round_keys_ready = 0;

        begin_test("RFC KEY WITH DELAYED ACKNOWLEDGEMENT");
        reset_loader;
        send_key(RFC_KEYS[1279:1024]);
        expect_keys(RFC_KEYS, 90);

        repeat (3) begin
            sample_core;
            check(round_keys_valid === 1 && round_keys === RFC_KEYS &&
                  key_update_pending === 1 && transfers == 0,
                  "Prepared key set changed before acknowledgement");
        end
        accept_keys;
        pass_test;

        begin_test("REPEATED KEY COMPLETES WITHOUT REEXPANSION");
        send_key(RFC_KEYS[1279:1024]);
        expect_keys(RFC_KEYS, 16);
        accept_keys;
        pass_test;

        begin_test("RESET CANCELS PENDING UPDATE AND ALLOWS A DIFFERENT KEY");
        send_key(256'b0);
        repeat (16) sample_core;
        check(round_keys_valid === 0 && key_update_pending === 1,
              "Replacement was published before expansion");
        reset_loader;

        repeat (90) begin
            sample_core;
            check(round_keys_valid === 0 && key_update_pending === 0 && transfers == 2,
                  "Cancelled request reappeared after reset");
        end

        send_key(256'b0);
        expect_keys(ZERO_KEYS, 90);
        accept_keys;
        check(transfers == 3, "Unexpected number of completed key transfers");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        $display("ALL PASS: kuz_key_loader; %0d scenarios; %0d transfers", PASSED, transfers);
        $finish;
    end

    initial begin
        #5000;
        $display("FAIL: kuz_key_loader timeout");
        $finish;
    end

endmodule
