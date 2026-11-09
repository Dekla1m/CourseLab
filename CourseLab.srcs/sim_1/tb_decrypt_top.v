`timescale 1ns / 1ps

module tb_decrypt_top;

    localparam integer LATENCY = 37;
    localparam integer ROUND_CYCLES = 4;
    localparam [127:0] RFC_PLAIN  = 128'h1122334455667700ffeeddccbbaa9988;
    localparam [127:0] RFC_CIPHER = 128'h7f679d90bebc24305a468d42b9d4edcd;
    localparam [127:0] ZERO_CIPHER = 128'h98cc6b54dbcf7bd2f0800c1fab0677ef;
    localparam [127:0] ONES_CIPHER = 128'h0e697e9f0587a38c908454ac39e1c463;

    localparam [127:0] PLAIN_FIRST = "abcdefghijklmnop";
    localparam [127:0] PLAIN_LAST  = {"qrstuv", 8'h80, 72'b0};
    localparam [127:0] CIPHER_FIRST = 128'hef95dc3b6f289b46d336a03435fb3be9;
    localparam [127:0] CIPHER_LAST  = 128'h15791b7a77614170684f77afaefd1234;

    localparam [127:0] RFC_FIRST_INVERSE = 128'h76ca149eef27d1b10d17e3d5d68e5a72;
    localparam [127:0] RFC_LAST_INVERSE  = 128'h99bb99ff99bb99ffffffffffffffffff;

    // Эталонный банк подаётся непосредственно на вход DUT. K1 в старших битах.
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

    reg          clk;
    reg          rst;
    reg [127:0]  data_input;
    reg          data_input_valid;
    reg          data_input_last;
    reg [1279:0] round_keys;

    wire          data_input_ready;
    wire [127:0]  data_output;
    wire          data_output_valid;
    wire          data_output_last;
    wire          busy_all_message;

    integer TESTS;
    integer PASSED;
    integer accepted_blocks;
    integer completed_blocks;
    integer slot;

    reg [127:0] expected_input_result;
    reg [127:0] expected_data [0:LATENCY-1];
    reg [LATENCY-1:0] expected_valid;
    reg [LATENCY-1:0] expected_last;
    reg expected_output_valid;
    reg expected_message_busy;
    reg expected_draining;
    reg [127:0] held_result;
    reg held_last;


    Decrypt_TOP dut (
        .clk(clk),
        .rst(rst),
        .data_input(data_input),
        .data_input_valid(data_input_valid),
        .data_input_last(data_input_last),
        .data_input_ready(data_input_ready),
        .round_keys(round_keys),
        .data_output(data_output),
        .data_output_valid(data_output_valid),
        .data_output_last(data_output_last),
        .busy_all_message(busy_all_message)
    );

    initial begin
        clk = 1'b0;
        forever #2.5 clk = ~clk;
    end

    // Модель интерфейса считает задержку от handshake, включая пустые такты.
    always @(posedge clk) begin
        if (rst) begin
            expected_valid = 0;
            expected_last = 0;
            expected_output_valid = 0;
            expected_message_busy = 0;
            expected_draining = 0;
            held_result = 0;
            held_last = 0;
        end else begin
            check(data_input_ready === !expected_draining, "Wrong ready before the edge");

            expected_output_valid = expected_valid[LATENCY-1];
            if (expected_output_valid) begin
                held_result = expected_data[LATENCY-1];
                held_last = expected_last[LATENCY-1];
                completed_blocks = completed_blocks + 1;
            end

            for (slot = LATENCY-1; slot > 0; slot = slot - 1) begin
                expected_valid[slot] = expected_valid[slot-1];
                expected_data[slot] = expected_data[slot-1];
                expected_last[slot] = expected_last[slot-1];
            end

            expected_valid[0] = data_input_valid && data_input_ready;
            expected_data[0] = expected_input_result;
            expected_last[0] = data_input_last;

            if (expected_valid[0]) begin
                accepted_blocks = accepted_blocks + 1;
                expected_message_busy = 1;
                expected_draining = data_input_last;
            end

            if (expected_output_valid && held_last) begin
                expected_message_busy = 0;
                expected_draining = 0;
            end
        end

        #0.2;
        check(data_output_valid === expected_output_valid &&
              data_output === held_result && data_output_last === held_last,
              "Wrong result, valid or last at the expected cycle");
        check(data_input_ready === (!rst && !expected_draining) &&
              busy_all_message === expected_message_busy, "Wrong ready or busy after the edge");
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
        input [8*110-1:0] message;
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

    task drive_block;
        input [127:0] block_value;
        input [127:0] result_value;
        input last_block;
        begin
            @(negedge clk);
            data_input = block_value;
            data_input_valid = 1;
            data_input_last = last_block;
            expected_input_result = result_value;
            sample_edge;
        end
    endtask

    task idle;
        input integer cycles;
        begin
            @(negedge clk);
            data_input_valid = 0;
            data_input = ~data_input;
            data_input_last = !data_input_last;
            repeat (cycles) sample_edge;
        end
    endtask


    initial begin
        rst = 1;
        data_input = 0;
        data_input_valid = 0;
        data_input_last = 0;
        expected_input_result = 0;
        round_keys = RFC_KEYS;
        TESTS = 0;
        PASSED = 0;
        accepted_blocks = 0;
        completed_blocks = 0;

        begin_test("RFC VECTOR AND EXACT LATENCY");
        sample_edge;
        @(negedge clk);
        rst = 0;

        drive_block(RFC_CIPHER, RFC_PLAIN, 1'b1);
        idle(ROUND_CYCLES);
        check(dut.pipeline.stage_valid[1] === 1 && dut.pipeline.stage_data[1] === RFC_FIRST_INVERSE,
              "Wrong first inverse round");
        idle(LATENCY - 1 - ROUND_CYCLES);
        check(dut.pipeline.stage_valid[9] === 1 && dut.pipeline.stage_data[9] === RFC_LAST_INVERSE,
              "Wrong ninth inverse round");
        idle(2);
        check(accepted_blocks == 1 && completed_blocks == 1, "RFC block count mismatch");
        pass_test;

        begin_test("ZERO AND ALL-ONE KEY SETS");
        round_keys = ZERO_KEYS;
        drive_block(ZERO_CIPHER, 128'b0, 1'b1);
        idle(LATENCY + 1);
        round_keys = ONES_KEYS;
        drive_block(ONES_CIPHER, {128{1'b1}}, 1'b1);
        idle(LATENCY + 1);
        check(accepted_blocks == 3 && completed_blocks == 3, "Boundary vector count mismatch");
        pass_test;

        begin_test("ADJACENT BLOCKS, A BUBBLE AND A HELD REQUEST AFTER LAST");
        round_keys = RFC_KEYS;
        drive_block(CIPHER_FIRST, PLAIN_FIRST, 1'b0);
        drive_block(RFC_CIPHER, RFC_PLAIN, 1'b0);
        idle(1);
        drive_block(CIPHER_LAST, PLAIN_LAST, 1'b1);
        drive_block(RFC_CIPHER, RFC_PLAIN, 1'b1);

        repeat (LATENCY - 1) sample_edge;
        check(accepted_blocks == 6 && completed_blocks == 6 &&
              data_input_ready === 1 && data_output_last === 1,
              "The request after last escaped before the tail result");
        sample_edge;
        check(accepted_blocks == 7, "Held request missed the first free edge");
        idle(LATENCY + 1);
        pass_test;

        begin_test("FULL PIPELINE ACCEPTS WHILE PRODUCING A RESULT");
        // Заполняем все стадии. Следующий блок входит на фронте первого результата.
        drive_block(CIPHER_FIRST, PLAIN_FIRST, 1'b0);
        repeat (LATENCY - 1)
            drive_block(RFC_CIPHER, RFC_PLAIN, 1'b0);
        drive_block(CIPHER_LAST, PLAIN_LAST, 1'b1);
        check(accepted_blocks == LATENCY + 8 && completed_blocks == 8 && data_output_valid === 1,
              "Input and output did not advance together in the full pipeline");
        idle(LATENCY + 1);
        check(completed_blocks == LATENCY + 8 && busy_all_message === 0, "Full pipeline did not drain");
        pass_test;

        begin_test("RESET CANCELS MULTIPLE BLOCKS AND CLEARS LAST");
        drive_block(CIPHER_FIRST, PLAIN_FIRST, 1'b0);
        drive_block(CIPHER_LAST, PLAIN_LAST, 1'b1);
        @(negedge clk);
        rst = 1;
        sample_edge;
        @(negedge clk);
        rst = 0;
        data_input_valid = 0;
        repeat (LATENCY + 1) sample_edge;
        check(accepted_blocks == LATENCY + 10 && completed_blocks == LATENCY + 8,
              "A cancelled block survived reset");
        drive_block(RFC_CIPHER, RFC_PLAIN, 1'b1);
        idle(LATENCY + 1);
        check(accepted_blocks == LATENCY + 11 && completed_blocks == LATENCY + 9, "Post-reset block count mismatch");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        $display("ALL PASS: Decrypt_TOP; %0d scenarios; %0d blocks; latency=%0d",
                 PASSED, completed_blocks, LATENCY);
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: Decrypt_TOP timeout");
        $finish;
    end

endmodule
