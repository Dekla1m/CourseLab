`timescale 1ns/1ps

// Один DUT. Направленные сценарии и модель очереди по внешним handshake.
// Gray-указатели проверяются отдельно; предвыборка не считается чтением.
module tb_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 64,
    parameter WR_HALF = 5,
    parameter RD_HALF = 7,
    parameter SAME_CLOCK = 0,
    parameter ID = 0
);


    reg wr_clk;
    reg async_rd_clk;
    reg wr_run;
    reg rd_run;
    wire rd_clk = SAME_CLOCK ? wr_clk : async_rd_clk;

    reg reset;
    reg wen;
    reg ready;
    reg [WIDTH-1:0] data;
    wire [WIDTH-1:0] out;
    wire valid;
    wire empty;
    wire full;

    FIFO #(.WORD_SIZE(WIDTH), .FIFO_DEPTH(DEPTH)) DUT (
        .reset(reset),
        .clk_in_write(wr_clk),
        .data_in(data),
        .write_enable(wen),
        .full(full),
        .clk_in_read(rd_clk), .read_ready(ready),
        .data_out(out),
        .read_valid(valid),
        .empty(empty)
    );

    reg [WIDTH-1:0] model [0:16*DEPTH+32];
    integer tail;
    integer head;
    integer writes;
    integer reads;
    integer TESTS;
    integer PASSED;
    integer w;
    reg [WIDTH-1:0] held_out;
    reg was_stalled;
    reg [$clog2(DEPTH):0] old_wr_gray, old_rd_gray, delta;
    integer i, j, saved_tail, saved_head;
    integer last_zeros;
    integer last_ones;
    integer target_reads;

    always #(WR_HALF) if (wr_run) wr_clk = ~wr_clk;

    initial begin
        #2;
        forever begin
            #(RD_HALF);
            if (rd_run) async_rd_clk = ~async_rd_clk;
        end
    end

    task begin_test;
        input [8*64-1:0] NAME;
        begin
            TESTS = TESTS + 1;
            $display("\nTEST %0d: %0s", TESTS, NAME);
        end
    endtask

    task pass_test;
        begin
            PASSED = PASSED + 1;
            $display("TEST %0d: PASS", TESTS);
        end
    endtask

    function [31:0] pattern_step;
        input [31:0] value;
        reg [31:0] x;
        begin
            x = value ^ (value << 13);
            x = x ^ (x >> 17);
            pattern_step = x ^ (x << 5);
        end
    endfunction

    // Генерируются все WIDTH битов, включая бит 128 (last), а не только младшие 32.
    function [WIDTH-1:0] word_pattern;
        input integer number;
        reg [31:0] x;
        integer bit_index;
        begin
            x = number ^ (32'h93a75421 + ID);
            for (bit_index = 0; bit_index < WIDTH; bit_index = bit_index + 1) begin
                x = pattern_step(x);
                word_pattern[bit_index] = x[0];
            end
        end
    endfunction

    always @(posedge reset) begin
        tail = 0;
        head = 0;
    end

    always @(posedge wr_clk) begin
        old_wr_gray = DUT.wr_gray;

        if (!reset) begin
            if (full !== 0 && full !== 1)
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d unknown full", ID);
                    $finish;
                end

            if (wen && !full) begin
                if (tail-head >= DEPTH)
                    begin
                        $display("FAIL: FIFO");
                        $display("case %0d exceeded advertised capacity", ID);
                        $finish;
                    end

                if (WIDTH == 129) begin
                    if (data[WIDTH-1]) last_ones = last_ones + 1;
                    else last_zeros = last_zeros + 1;
                end

                model[tail] = data;
                tail = tail + 1;
                writes = writes + 1;
            end

            #0.1;
            delta = DUT.wr_gray ^ old_wr_gray;
            if (!DUT.wr_reset && (delta & (delta-1)) != 0)
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d non-Gray write transition", ID);
                    $finish;
                end
        end
    end

    always @(posedge rd_clk) begin
        old_rd_gray = DUT.rd_gray;
        held_out = out;
        was_stalled = valid && !ready;

        if (!reset && !DUT.rd_reset) begin
            if (valid !== 0 && valid !== 1)
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d unknown valid", ID);
                    $finish;
                end

            if (empty !== !valid)
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d empty disagrees with valid", ID);
                    $finish;
                end

            if (valid && ready) begin
                if (head >= tail || out !== model[head])
                    begin
                        $display("FAIL: FIFO");
                        $display("case %0d word %0d expected=%h actual=%h", ID, head, model[head], out);
                        $finish;
                    end

                head = head + 1;
                reads = reads + 1;
            end

            #0.1;

            if (was_stalled && (valid !== 1 || out !== held_out))
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d changed a stalled word/valid", ID);
                    $finish;
                end

            if (valid && (head >= tail || out !== model[head]))
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d invalid prefetched head", ID);
                    $finish;
                end

            delta = DUT.rd_gray ^ old_rd_gray;
            if ((delta & (delta-1)) != 0)
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d non-Gray read transition", ID);
                    $finish;
                end
        end
    end

    task put;
        input [WIDTH-1:0] word;
        begin
            @(negedge wr_clk);
            while (full) @(negedge wr_clk);
            data = word;
            wen = 1;
            @(negedge wr_clk);
            wen = 0;
        end
    endtask

    task drain;
        begin
            @(negedge rd_clk);
            ready = 1;
            wait (head == tail);
            repeat (5) @(negedge rd_clk);
            ready = 0;

            if (valid !== 0 || empty !== 1)
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d failed to drain", ID);
                    $finish;
                end
        end
    endtask

    // ========== Основной сценарий ==========
    initial begin
        wr_clk = 0;
        async_rd_clk = 0;
        wr_run = 1;
        rd_run = 0;
        reset = 0;
        wen = 0;
        ready = 0;
        data = 0;
        tail = 0;
        head = 0;
        writes = 0;
        reads = 0;
        last_zeros = 0;
        last_ones = 0;
        TESTS = 0;
        PASSED = 0;

        begin_test("RESET AND RECOVERY");
        #1; reset = 1;
        #23; reset = 0;
        repeat (5) @(negedge wr_clk);
        pass_test;

        begin_test("EXACT CAPACITY AND BLOCKED WRITES");
        for (i = 0; i < DEPTH; i = i + 1) put(word_pattern(i));
        if (full !== 1)
            begin
                $display("FAIL: FIFO");
                $display("case %0d full missing at exact depth", ID);
                $finish;
            end

        saved_tail = tail;
        @(negedge wr_clk); wen = 1; data = {WIDTH{1'b1}};
        repeat (6) @(negedge wr_clk);
        wen = 0;
        if (tail != saved_tail)
            begin
                $display("FAIL: FIFO");
                $display("case %0d accepted a write while full", ID);
                $finish;
            end

        pass_test;

        begin_test("PREFETCH, HOLD AND CONTINUOUS READ");
        rd_run = 1;
        wait (valid);
        saved_head = head;
        repeat (12) @(negedge rd_clk);
        if (head != saved_head || full !== 1)
            begin
                $display("FAIL: FIFO");
                $display("case %0d prefetch released capacity before handshake", ID);
                $finish;
            end

        // Весь накопленный пакет должен читаться по слову за такт без пузырей.
        @(negedge rd_clk); ready = 1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge rd_clk);
            if (!valid) begin
                $display("FAIL: FIFO");
                $display("case %0d bubble inside a prefetched burst", ID);
                $finish;
            end
        end
        @(negedge rd_clk); ready = 0;
        drain;

        pass_test;

        begin_test("EMPTY AND FIRST WORD WITHOUT READY");
        saved_head = head;
        @(negedge rd_clk); ready = 1;
        repeat (6) @(negedge rd_clk);
        ready = 0;
        if (head != saved_head)
            begin
                $display("FAIL: FIFO");
                $display("case %0d read from empty FIFO", ID);
                $finish;
            end

        // Первое слово появляется без предварительного ready.
        put(word_pattern(100));
        wait (valid);
        repeat (5) @(negedge rd_clk);
        drain;

        pass_test;

        begin_test("POINTER WRAPAROUND");
        for (j = 0; j < 2; j = j + 1) begin
            for (i = 0; i < DEPTH; i = i + 1) put(word_pattern(200+j*DEPTH+i));
            drain;
        end

        pass_test;

        begin_test("THREE SIMULTANEOUS WRITES AND READS");
        target_reads = reads + 3;
        fork
            begin
                for (w = 0; w < 3; w = w + 1)
                    put(word_pattern(w + 2000));
            end
            begin
                @(negedge rd_clk);
                ready = 1;
                wait (reads == target_reads);
                @(negedge rd_clk);
                ready = 0;
            end
        join
        drain;
        pass_test;

        if (!SAME_CLOCK) begin
            begin_test("STOPPED WRITE CLOCK");
            for (i = 0; i < DEPTH; i = i + 1) put(word_pattern(i+10000));
            @(negedge wr_clk); wr_run = 0;
            drain;
            wr_run = 1;
            repeat (5) @(negedge wr_clk);
            pass_test;

            begin_test("RESET WITH STOPPED READ CLOCK");
            for (i = 0; i < DEPTH; i = i + 1) put(word_pattern(i+11000));
            @(negedge rd_clk); rd_run = 0;
            #3; reset = 1; wen = 1; ready = 1;
            #1;
            if (empty !== 1 || full !== 1 || valid !== 0 || out !== 0)
                begin
                    $display("FAIL: FIFO");
                    $display("case %0d reset failed with stopped read clock", ID);
                    $finish;
                end

            #41; reset = 0; wen = 0; ready = 0;
            repeat (6) @(negedge wr_clk);
            for (i = 0; i < DEPTH; i = i + 1) put(word_pattern(i+12000));
            if (!full) begin
                $display("FAIL: FIFO");
                $display("case %0d recovery capacity failed", ID);
                $finish;
            end
            rd_run = 1;
            drain;
            pass_test;
        end

        begin_test("RESET WITH BOTH CLOCKS STOPPED");

        // Асинхронный reset обязан работать даже при остановке обоих clocks.
        @(negedge wr_clk); wr_run = 0;
        if (!SAME_CLOCK) begin
            @(negedge rd_clk); rd_run = 0;
        end
        #3; reset = 1;
        #1;
        if (full !== 1 || valid !== 0 || empty !== 1 || out !== 0)
            begin
                $display("FAIL: FIFO");
                $display("case %0d reset failed with both clocks stopped", ID);
                $finish;
            end
        #9; reset = 0;
        #20;
        if (full !== 1 || valid !== 0)
            begin
                $display("FAIL: FIFO");
                $display("case %0d reset released without local clock", ID);
                $finish;
            end
        wr_run = 1; rd_run = 1;
        put(word_pattern(13000));
        drain;

        if (WIDTH == 129 && (last_zeros == 0 || last_ones == 0))
            begin
                $display("FAIL: FIFO");
                $display("case %0d did not exercise both last values", ID);
                $finish;
            end

        if (head != tail) begin
            $display("FAIL: FIFO");
            $display("case %0d words remain", ID);
            $finish;
        end
        $display("PASS FIFO case %0d: width=%0d depth=%0d same_clock=%0d writes=%0d reads=%0d", ID, WIDTH, DEPTH, SAME_CLOCK, writes, reads);
        pass_test;
        $display("TESTS PASSED: %0d / %0d", PASSED, TESTS);
        if (PASSED == TESTS)
            $display("ALL PASS: FIFO unit test; width=%0d depth=%0d same_clock=%0d", WIDTH, DEPTH, SAME_CLOCK);
        else
            $display("FAIL: FIFO test count mismatch");
        $finish;
    end


initial begin
    #10000000;
    $display("FAIL: FIFO test timeout");
    $finish;
end

endmodule
