`timescale 1ns / 1ps

module tb_key_input_order;

reg clk;
reg rst;
reg mode;
reg [9:0] TX_DATA;
reg TX_VALID;
reg key_ready_receiver;

wire TX_READY;
wire [255:0] key;
wire key_valid;
wire key_noerr;

integer TESTS;
integer PASSED;
integer CASE_OK;
integer RESULTS;
integer result_before;

reg stalled;
reg [255:0] held_key;
reg held_noerr;

localparam [255:0] RFC_KEY = 256'h8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef;

Key_input_order DUT (
    .clk(clk),
    .rst(rst),
    .mode(mode),

    .TX_DATA(TX_DATA),
    .TX_VALID(TX_VALID),
    .TX_READY(TX_READY),

    .key_ready_receiver(key_ready_receiver),
    .key(key),
    .key_valid(key_valid),
    .key_noerr(key_noerr)
);

always #5 clk = ~clk;

// Контроль удержания результата не зависит от внутреннего состояния DUT.
always @(posedge clk) begin
    if (rst) begin
        stalled = 0;
    end
    else begin
        if (stalled && (key_valid !== 1 || key !== held_key || key_noerr !== held_noerr)) begin
            $display("FAIL: key changed before handshake");
            $finish;
        end

        if (key_valid && TX_READY) begin
            $display("FAIL: parser accepted bytes while holding a key");
            $finish;
        end

        if (key_valid && key_ready_receiver)
            RESULTS = RESULTS + 1;

        stalled = key_valid && !key_ready_receiver;
        held_key = key;
        held_noerr = key_noerr;
    end
end


task begin_test;
input [8*64-1:0] NAME;
begin
    TESTS = TESTS + 1;
    CASE_OK = 1;
    $display("\nTEST %0d: %0s", TESTS, NAME);
end
endtask


task check;
input CONDITION;
input [8*96-1:0] MESSAGE;
begin
    if (CONDITION !== 1'b1) begin
        CASE_OK = 0;
        $display("    FAIL | %0s", MESSAGE);
    end
end
endtask


task end_test;
begin
    if (CASE_OK) begin
        PASSED = PASSED + 1;
        $display("TEST %0d: PASS", TESTS);
    end
    else begin
        $display("TEST %0d: FAIL", TESTS);
        $finish;
    end
end
endtask


task do_reset;
begin
    @(negedge clk);
    rst = 1;
    TX_VALID = 0;
    key_ready_receiver = 0;

    repeat (3) @(posedge clk);
    #1;
    check(key_valid === 0 && key === 0 && TX_READY === 0, "reset outputs");

    @(negedge clk);
    rst = 0;
end
endtask


task send_word;
input [9:0] WORD;
begin
    @(negedge clk);
    TX_DATA = WORD;
    TX_VALID = 1;

    // Источник удерживает байт, пока сам DUT не разрешит приём.
    @(posedge clk);
    while (!TX_READY) @(posedge clk);

    @(negedge clk);
    TX_VALID = 0;
end
endtask


function [7:0] hex_character;
input [3:0] VALUE;
input LOWERCASE;
begin
    if (VALUE < 10)
        hex_character = 8'h30 + VALUE;
    else
        hex_character = (LOWERCASE ? 8'h61 : 8'h41) + VALUE - 10;
end
endfunction


task send_hex;
input [255:0] VALUE;
input integer LENGTH;
input integer BAD_CHARACTER;
input integer BAD_FRAME;
input [1:0] FRAME_FLAGS;
integer i;
reg [7:0] character;
begin
    for (i = 0; i < LENGTH; i = i + 1) begin
        character = hex_character(VALUE[255-4*(i%64) -: 4], i%2);
        if (i == BAD_CHARACTER) character = 8'h5a;

        send_word({(i == BAD_FRAME ? FRAME_FLAGS : 2'b00), character});
    end
end
endtask


task send_line;
input [255:0] VALUE;
input integer LENGTH;
input integer BAD_CHARACTER;
input integer BAD_FRAME;
input [1:0] FRAME_FLAGS;
input [1:0] ENDING_ERRORS;
begin
    send_hex(VALUE, LENGTH, BAD_CHARACTER, BAD_FRAME, FRAME_FLAGS);
    send_word({(ENDING_ERRORS[0] ? 2'b01 : 2'b00), 8'h0d});
    send_word({(ENDING_ERRORS[1] ? 2'b01 : 2'b00), 8'h0a});
end
endtask


task check_result;
input [255:0] EXPECTED_KEY;
input EXPECTED_NOERR;
integer before_count;
begin
    wait (key_valid);
    check(key_noerr === EXPECTED_NOERR, "key_noerr");
    if (EXPECTED_NOERR)
        check(key === EXPECTED_KEY, "key value and byte order");

    before_count = RESULTS;
    @(posedge clk);
    #1;
    check(key_valid === 0 && TX_READY === 1, "return to IDLE after handshake");
    check(RESULTS == before_count + 1, "exactly one key handshake");

    repeat (3) @(negedge clk);
    check(key_valid === 0, "no repeated result");
end
endtask


task line_test;
input [8*64-1:0] NAME;
input [255:0] VALUE;
input integer LENGTH;
input integer BAD_CHARACTER;
input integer BAD_FRAME;
input [1:0] FRAME_FLAGS;
input [1:0] ENDING_ERRORS;
input EXPECTED_NOERR;
begin
    begin_test(NAME);
    send_line(VALUE, LENGTH, BAD_CHARACTER, BAD_FRAME, FRAME_FLAGS, ENDING_ERRORS);
    check_result(VALUE, EXPECTED_NOERR);
    end_test;
end
endtask


// ========== Основной сценарий ==========
initial begin
    clk = 0;
    rst = 0;
    mode = 0;
    TX_DATA = 0;
    TX_VALID = 0;
    key_ready_receiver = 0;
    TESTS = 0;
    PASSED = 0;
    RESULTS = 0;
    CASE_OK = 1;
    stalled = 0;

    begin_test("RESET, HOLD AND WAITING INPUT BYTE");
    do_reset;
    send_line(RFC_KEY, 64, -1, -1, 0, 0);
    wait (key_valid);

    repeat (3) @(negedge clk);
    check(key === RFC_KEY && key_noerr === 1 && TX_READY === 0, "held result");

    fork
        begin
            send_line({32{8'hab}}, 64, -1, -1, 0, 0);
        end
        begin
            repeat (3) @(negedge clk);
            check(key_valid === 1 && key === RFC_KEY && TX_READY === 0, "input stalled during HOLD_RESULT");
            key_ready_receiver = 1;
            @(posedge clk);
            #1;
            check(RESULTS == 1 && key_valid === 0, "first key accepted once");
        end
    join

    check_result({32{8'hab}}, 1);
    end_test;

    line_test("ZERO KEY", 0, 64, -1, -1, 0, 0, 1);
    line_test("ALL-ONES KEY", {256{1'b1}}, 64, -1, -1, 0, 0, 1);

    line_test("EMPTY KEY", RFC_KEY, 0, -1, -1, 0, 0, 0);
    line_test("63 HEX CHARACTERS", RFC_KEY, 63, -1, -1, 0, 0, 0);
    line_test("65 HEX CHARACTERS", RFC_KEY, 65, -1, -1, 0, 0, 0);
    line_test("INVALID HEX CHARACTER", RFC_KEY, 64, 20, -1, 0, 0, 0);
    line_test("PARITY ERROR", RFC_KEY, 64, -1, 20, 1, 0, 0);
    line_test("STOP ERROR", RFC_KEY, 64, -1, 33, 2, 0, 0);
    line_test("UART ERROR ON CR", RFC_KEY, 64, -1, -1, 0, 1, 0);
    line_test("UART ERROR ON LF", RFC_KEY, 64, -1, -1, 0, 2, 0);

    begin_test("EXTRA CHARACTER BEFORE CR");
    send_hex(RFC_KEY, 64, -1, -1, 0);
    send_word(10'h058);
    send_word(10'h00d);
    send_word(10'h00a);
    check_result(0, 0);
    end_test;

    begin_test("WRONG CHARACTER AFTER CR");
    send_hex(RFC_KEY, 64, -1, -1, 0);
    send_word(10'h00d);
    send_word(10'h058);
    send_word(10'h00d);
    send_word(10'h00a);
    check_result(0, 0);
    end_test;

    begin_test("REPEATED CR");
    send_hex(RFC_KEY, 64, -1, -1, 0);
    send_word(10'h00d);
    send_word(10'h00d);
    send_word(10'h00a);
    check_result(0, 0);
    end_test;

    line_test("RECOVERY AFTER INVALID INPUT", RFC_KEY, 64, -1, -1, 0, 0, 1);

    begin_test("RESET DURING PARTIAL KEY");
    send_hex(RFC_KEY, 13, -1, -1, 0);
    result_before = RESULTS;
    do_reset;
    key_ready_receiver = 1;
    repeat (3) @(negedge clk);
    check(RESULTS == result_before, "partial key cancelled");
    send_line(RFC_KEY, 64, -1, -1, 0, 0);
    check_result(RFC_KEY, 1);
    end_test;

    begin_test("RESET DURING HELD RESULT");
    @(negedge clk);
    key_ready_receiver = 0;
    send_line(RFC_KEY, 64, -1, -1, 0, 0);
    wait (key_valid);
    result_before = RESULTS;
    do_reset;
    key_ready_receiver = 1;
    repeat (3) @(negedge clk);
    check(RESULTS == result_before, "pending key cancelled");
    send_line({32{8'hab}}, 64, -1, -1, 0, 0);
    check_result({32{8'hab}}, 1);
    end_test;

    $display("\nTESTS PASSED: %0d / %0d", PASSED, TESTS);
    if (PASSED == TESTS && RESULTS == 18)
        $display("ALL PASS: Key_input_order unit test; %0d scenarios, %0d results", TESTS, RESULTS);
    else
        $display("FAIL: Key_input_order test totals");

    $finish;
end

initial begin
    #1000000;
    $display("FAIL: Key_input_order test timeout");
    $finish;
end

endmodule
