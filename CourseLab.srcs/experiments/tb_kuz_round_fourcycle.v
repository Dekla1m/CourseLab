`timescale 1ns / 1ps

module tb_kuz_round_fourcycle #(
    parameter DECRYPT = 1'b0
);

    // Три первых раунда ENC или DEC из RFC 7801, разделы 5.5 и 5.6.
    localparam [127:0] INPUT_1 = DECRYPT ? 128'h7f679d90bebc24305a468d42b9d4edcd :
                                          128'h1122334455667700ffeeddccbbaa9988;
    localparam [127:0] KEY_1 = DECRYPT ? 128'h72e9dd7416bcf45b755dbaa88e4a4043 :
                                        128'h8899aabbccddeeff0011223344556677;
    localparam [127:0] KEY_2 = DECRYPT ? 128'hbb44e25378c73123a5f32f73cdb6e517 :
                                        128'hfedcba98765432100123456789abcdef;
    localparam [127:0] KEY_3 = DECRYPT ? 128'h5a7925017b9fdd3ed72a91a22286f984 :
                                        128'hdb31485315694343228d6aef8cc78c44;
    localparam [127:0] RESULT_1 = DECRYPT ? 128'h76ca149eef27d1b10d17e3d5d68e5a72 :
                                           128'he297b686e355b0a1cf4a2f9249140830;
    localparam [127:0] RESULT_2 = DECRYPT ? 128'h5d9b06d41b9d1d2d04df7755363e94a9 :
                                           128'h285e497a0862d596b36f4258a1c69072;
    localparam [127:0] RESULT_3 = DECRYPT ? 128'h79487192aa45709c115559d6e9280f6e :
                                           128'h0187a3a429b567841ad50d29207cc34e;

    reg         clk;
    reg         rst;
    reg         data_round_enable;
    reg [127:0] data_input;
    reg [127:0] key_input;

    wire         data_round_done;
    wire [127:0] data_output;

    integer TESTS;
    integer PASSED;
    integer completed;

    reg [127:0] expected_input;
    reg [127:0] expected_history [0:2];
    reg [2:0]   expected_valid;
    reg         expected_done;
    reg [127:0] expected_output;

    kuz_round_fourcycle #(
        .DECRYPT(DECRYPT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_round_enable(data_round_enable),
        .data_input(data_input),
        .key_input(key_input),
        .data_output(data_output),
        .data_round_done(data_round_done)
    );


    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Считаем фронт XOR первым. На четвёртом фронте выходит соответствующий результат.
    always @(posedge clk) begin
        if (rst) begin
            expected_valid  = 3'b0;
            expected_done   = 1'b0;
            expected_output = 128'b0;
        end else begin
            expected_done = expected_valid[2];
            if (expected_done) begin
                expected_output = expected_history[2];
                completed = completed + 1;
            end

            expected_valid      = {expected_valid[1:0], data_round_enable};
            expected_history[2] = expected_history[1];
            expected_history[1] = expected_history[0];
            expected_history[0] = expected_input;
        end

        #0.2;
        check(data_round_done === expected_done, "Wrong result cycle");
        check(data_output === expected_output, "Wrong or unheld result");
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

    task sample_edge;
        begin
            @(posedge clk);
            #0.3;
        end
    endtask

    task drive;
        input [127:0] block_value;
        input [127:0] key_value;
        input [127:0] result_value;
        begin
            @(negedge clk);
            data_round_enable = 1'b1;
            data_input = block_value;
            key_input = key_value;
            expected_input = result_value;
            sample_edge;
        end
    endtask

    task idle;
        input integer edges;
        begin
            @(negedge clk);
            data_round_enable = 1'b0;
            data_input = ~data_input;
            key_input = ~key_input;
            repeat (edges) sample_edge;
        end
    endtask


    initial begin
        rst = 1'b1;
        data_round_enable = 1'b0;
        data_input = 128'b0;
        key_input = 128'b0;
        expected_input = 128'b0;
        TESTS = 0;
        PASSED = 0;
        completed = 0;

        begin_test("RFC ROUND AND EXACT LATENCY");
        sample_edge;
        @(negedge clk);
        rst = 1'b0;
        drive(INPUT_1, KEY_1, RESULT_1);
        check(dut.stage_x === (INPUT_1 ^ KEY_1), "Wrong registered key XOR");
        idle(1);
        if (!DECRYPT)
            check(dut.stage_2 === 128'he87de8b6e87de8b6b6b6b6b6b6b6b6b6, "Wrong registered S");
        sample_edge;
        if (DECRYPT)
            check(dut.stage_3 === 128'h8a6b930a52211b45c5baa43ff8b91319, "Wrong registered inverse L");
        repeat (2) sample_edge;
        check(completed == 1, "Single round did not complete exactly once");
        pass_test;

        begin_test("CONSECUTIVE INPUTS WITH DIFFERENT KEYS AND A BUBBLE");
        drive(INPUT_1, KEY_1, RESULT_1);
        drive(RESULT_1, KEY_2, RESULT_2);
        idle(1);
        drive(RESULT_2, KEY_3, RESULT_3);
        idle(4);
        check(completed == 4, "Pipeline lost a result");
        pass_test;

        begin_test("RESET WITH TWO IN-FLIGHT BLOCKS AND RECOVERY");
        drive(INPUT_1, KEY_1, RESULT_1);
        drive(RESULT_1, KEY_2, RESULT_2);
        @(negedge clk);
        rst = 1'b1;
        sample_edge;
        @(negedge clk);
        rst = 1'b0;
        data_round_enable = 1'b0;
        repeat (4) sample_edge;
        check(completed == 4, "Cancelled result survived reset");
        drive(RESULT_2, KEY_3, RESULT_3);
        idle(4);
        check(completed == 5, "Recovery result missing");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        $display("ALL PASS: kuz_round_fourcycle; DECRYPT=%0d; %0d scenarios; %0d results",
                 DECRYPT, PASSED, completed);
        $finish;
    end

    initial begin
        #3000;
        $display("FAIL: kuz_round_fourcycle timeout");
        $finish;
    end

endmodule
