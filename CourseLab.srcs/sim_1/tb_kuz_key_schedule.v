`timescale 1ns / 1ps

module tb_kuz_key_schedule;

    localparam integer PREPARE_CYCLES = 33;
    localparam [255:0] RFC_KEY = 256'h8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef;
    localparam [1279:0] RFC_KEYS = {
        RFC_KEY,
        128'hdb31485315694343228d6aef8cc78c44, 128'h3d4553d8e9cfec6815ebadc40a9ffd04,
        128'h57646468c44a5e28d3e59246f429f1ac, 128'hbd079435165c6432b532e82834da581b,
        128'h51e640757e8745de705727265a0098b1, 128'h5a7925017b9fdd3ed72a91a22286f984,
        128'hbb44e25378c73123a5f32f73cdb6e517, 128'h72e9dd7416bcf45b755dbaa88e4a4043
    };

    reg         clk;
    reg         rst;
    reg [255:0] start_key_input;
    reg         key_input_valid;

    wire         key_input_ready;
    wire         round_keys_ready;
    wire [1279:0] round_keys;

    integer TESTS;
    integer PASSED;

    kuz_key_schedule dut (
        .clk(clk),
        .rst(rst),
        .start_key_input(start_key_input),
        .key_input_valid(key_input_valid),
        .key_input_ready(key_input_ready),
        .round_keys_ready(round_keys_ready),
        .round_keys(round_keys)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
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
        input [8*96-1:0] message;
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
            #0.2;
        end
    endtask

    task send_key;
        input [255:0] key;
        begin
            @(negedge clk);
            check(key_input_ready === 1'b1, "Key input was not ready");
            start_key_input = key;
            key_input_valid = 1'b1;
            sample_edge;
            @(negedge clk);
            key_input_valid = 1'b0;
            start_key_input = ~key;
        end
    endtask

    task expect_preparation;
        integer elapsed;
        begin
            // t0 уже прошёл в send_key. K9/K10 публикуются вместе с остальным набором на t33.
            for (elapsed = 1; elapsed < PREPARE_CYCLES; elapsed = elapsed + 1) begin
                check(round_keys_ready === 1'b0 && key_input_ready === 1'b0,
                      "Key set published or new request allowed too early");
                sample_edge;
            end
            check(round_keys_ready === 1'b0 && key_input_ready === 1'b0, "Key set published before t33");
            sample_edge;
            check(round_keys_ready === 1'b1 && key_input_ready === 1'b1, "Key set missing at t33");
        end
    endtask

    initial begin
        rst = 1'b1;
        start_key_input = 0;
        key_input_valid = 1'b0;
        TESTS = 0;
        PASSED = 0;

        begin_test("RFC 7801 AND PARALLEL KEY BUS");
        sample_edge;
        check(round_keys_ready === 0 && key_input_ready === 0 && round_keys === 0,
              "Reset did not clear the schedule");
        @(negedge clk);
        rst = 1'b0;
        send_key(RFC_KEY);
        expect_preparation;
        check(round_keys === RFC_KEYS, "Parallel key order or value mismatch");
        pass_test;

        begin_test("REPEATED KEY REUSES THE PREPARED SET");
        send_key(RFC_KEY);
        check(round_keys_ready === 1 && key_input_ready === 1, "Repeated key triggered expansion");
        check(round_keys === RFC_KEYS, "Repeated key changed the parallel bus");
        pass_test;

        begin_test("RESET DURING REPLACEMENT AND RELOAD");
        send_key(256'b0);
        repeat (4) sample_edge;
        check(round_keys_ready === 0 && key_input_ready === 0, "Replacement did not invalidate the old set");
        @(negedge clk);
        rst = 1'b1;
        sample_edge;
        check(round_keys_ready === 0 && key_input_ready === 0 && round_keys === 0,
              "Reset did not cancel preparation");
        @(negedge clk);
        rst = 1'b0;
        send_key(RFC_KEY);
        expect_preparation;
        check(round_keys === RFC_KEYS, "Wrong key set after reset");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        $display("ALL PASS: kuz_key_schedule; %0d scenarios; prepare=%0d cycles", PASSED, PREPARE_CYCLES);
        $finish;
    end

    initial begin
        #5000;
        $display("FAIL: kuz_key_schedule timeout");
        $finish;
    end

endmodule
