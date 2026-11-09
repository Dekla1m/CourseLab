`timescale 1ns / 1ps

module tb_encrypt_top;

    localparam integer LATENCY = 10;
    localparam [127:0] RFC_PLAIN  = 128'h1122334455667700ffeeddccbbaa9988;
    localparam [127:0] RFC_CIPHER = 128'h7f679d90bebc24305a468d42b9d4edcd;
    localparam [127:0] ZERO_CIPHER = 128'h98cc6b54dbcf7bd2f0800c1fab0677ef;
    localparam [127:0] ONES_CIPHER = 128'h0e697e9f0587a38c908454ac39e1c463;

    localparam [127:0] PLAIN_FIRST = "abcdefghijklmnop";
    localparam [127:0] PLAIN_LAST  = {"qrstuv", 8'h80, 72'b0};
    localparam [127:0] CIPHER_FIRST = 128'hef95dc3b6f289b46d336a03435fb3be9;
    localparam [127:0] CIPHER_LAST  = 128'h15791b7a77614170684f77afaefd1234;


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

    reg [127:0] expected_keys [0:9];
    reg [127:0] reference_result;
    integer key_index;

    Encrypt_TOP dut (
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
        forever #5 clk = ~clk;
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

        reference_encrypt(RFC_PLAIN, RFC_KEYS[1279:1024], reference_result);
        check(reference_result === RFC_CIPHER, "Independent RFC ciphertext mismatch");
        for (key_index = 0; key_index < 10; key_index = key_index + 1)
            check(expected_keys[key_index] === RFC_KEYS[1279-128*key_index -: 128],
                  "Independent RFC round key mismatch");
        drive_block(RFC_PLAIN, RFC_CIPHER, 1'b1);
        idle(LATENCY + 1);
        check(accepted_blocks == 1 && completed_blocks == 1, "RFC block count mismatch");
        pass_test;

        begin_test("ZERO AND ALL-ONE KEY SETS");
        round_keys = ZERO_KEYS;
        drive_block(128'b0, ZERO_CIPHER, 1'b1);
        idle(LATENCY + 1);
        round_keys = ONES_KEYS;
        drive_block({128{1'b1}}, ONES_CIPHER, 1'b1);
        idle(LATENCY + 1);
        check(accepted_blocks == 3 && completed_blocks == 3, "Boundary vector count mismatch");
        pass_test;

        begin_test("ADJACENT BLOCKS, A BUBBLE AND A HELD REQUEST AFTER LAST");
        round_keys = RFC_KEYS;
        drive_block(PLAIN_FIRST, CIPHER_FIRST, 1'b0);
        drive_block(RFC_PLAIN, RFC_CIPHER, 1'b0);
        idle(1);
        drive_block(PLAIN_LAST, CIPHER_LAST, 1'b1);
        drive_block(RFC_PLAIN, RFC_CIPHER, 1'b1);

        repeat (LATENCY - 1) sample_edge;
        check(accepted_blocks == 6 && completed_blocks == 6 &&
              data_input_ready === 1 && data_output_last === 1,
              "The request after last escaped before the tail result");
        sample_edge;
        check(accepted_blocks == 7, "Held request missed the first free edge");
        idle(LATENCY + 1);
        pass_test;

        begin_test("FULL PIPELINE ACCEPTS WHILE PRODUCING A RESULT");
        // Десять блоков заполняют тракт. Одиннадцатый входит на фронте первого результата.
        drive_block(PLAIN_FIRST, CIPHER_FIRST, 1'b0);
        repeat (LATENCY - 1)
            drive_block(RFC_PLAIN, RFC_CIPHER, 1'b0);
        drive_block(PLAIN_LAST, CIPHER_LAST, 1'b1);
        check(accepted_blocks == 18 && completed_blocks == 8 && data_output_valid === 1,
              "Input and output did not advance together in the full pipeline");
        idle(LATENCY + 1);
        check(completed_blocks == 18 && busy_all_message === 0, "Full pipeline did not drain");
        pass_test;

        begin_test("RESET CANCELS MULTIPLE BLOCKS AND CLEARS LAST");
        drive_block(PLAIN_FIRST, CIPHER_FIRST, 1'b0);
        drive_block(PLAIN_LAST, CIPHER_LAST, 1'b1);
        @(negedge clk);
        rst = 1;
        sample_edge;
        @(negedge clk);
        rst = 0;
        data_input_valid = 0;
        repeat (LATENCY + 1) sample_edge;
        check(accepted_blocks == 20 && completed_blocks == 18,
              "A cancelled block survived reset");
        drive_block(RFC_PLAIN, RFC_CIPHER, 1'b1);
        idle(LATENCY + 1);
        check(accepted_blocks == 21 && completed_blocks == 19, "Post-reset block count mismatch");
        pass_test;

        $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
        $display("ALL PASS: Encrypt_TOP; %0d scenarios; %0d blocks; latency=%0d",
                 PASSED, completed_blocks, LATENCY);
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: Encrypt_TOP timeout");
        $finish;
    end

endmodule
