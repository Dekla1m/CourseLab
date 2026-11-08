from pathlib import Path
import random
import shutil

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "CourseLab.srcs/sources_1/l_matrix_onecycle.v"
TB = ROOT / "CourseLab.srcs/sim_1/tb.v"
BACKUP = ROOT / "work/tb_before_L_counter.v"
COEFFICIENTS = (148,32,133,16,194,192,1,251,1,192,194,16,133,32,148,1)

def multiply(a,b):
    result = 0
    for j in range(8):
        if b & (1 << j):
            result ^= a << j
    for degree in range(14,7,-1):
        if result & (1 << degree):
            result ^= 0x1c3 << (degree-8)
    return result

def reference_l(value):
    state = list(value.to_bytes(16,"big"))
    for _ in range(16):
        r = 0
        for a,c in zip(state,COEFFICIENTS):
            r ^= multiply(a,c)
        state = [r,*state[:15]]
    return int.from_bytes(bytes(state),"big")

columns = [reference_l(1 << i) for i in range(128)]
rows = [sum(((columns[i] >> j) & 1) << i for i in range(128)) for j in range(128)]

def matrix_l(value):
    return sum(((value & mask).bit_count() % 2) << j for j,mask in enumerate(rows))

examples = (
    (0,0),
    (1,int("6ea276726c487ab85d27bd10dd849401",16)),
    (int("64a59400000000000000000000000000",16),int("d456584dd0e3e84cc3166e4b7fa2890d",16)),
    (int("e87de8b6e87de8b6b6b6b6b6b6b6b6b6",16),int("e297b686e355b0a1cf4a2f9249140830",16)),
)
for value,expected in examples:
    assert reference_l(value)==expected
    assert matrix_l(value)==expected
rng = random.Random(3412)
for _ in range(256):
    value = rng.getrandbits(128)
    assert matrix_l(value)==reference_l(value)

rtl = """// Full Kuznyechik L: direct 128x128 binary matrix.
// Byte order: data_input[127:120]=a15, data_input[7:0]=a0.
// Matrix constants were generated from the polynomial 0x1C3.
// Inputs launched after clock N produce registered output at N+1.
// data_input_r/data_output_r are one-cycle valid signals; data_input new block can arrive every cycle.
`timescale 1ns/1ps
module l_matrix_onecycle (
    input wire clk,
    input wire rst,
    input wire data_input_r,
    input wire [127:0] data_input,
    output reg [127:0] data_output,
    output reg data_output_r
);
    wire [127:0] linear_result;
    l_matrix_comb l_transform (.data_input(data_input), .data_output(linear_result));
"""
comb = """// Combinational Kuznyechik L: 128 fixed XOR masks, no registers.
`timescale 1ns/1ps
module l_matrix_comb(input wire [127:0] data_input, output wire [127:0] data_output);
"""
for j,mask in enumerate(rows):
    comb += f"    assign data_output[{j}] = ^(data_input & 128'h{mask:032x});\n"
comb += 'endmodule\n'
SOURCE.with_name('l_matrix_comb.v').write_text(comb,encoding='utf-8')
rtl += """
    always @(posedge clk) begin
        if (rst) begin
            data_output <= 128'b0;
            data_output_r <= 1'b0;
        end else begin
            data_output_r <= data_input_r;
            if (data_input_r)
                data_output <= linear_result;
        end
    end
endmodule
"""
SOURCE.write_text(rtl,encoding="utf-8")

tb = """`timescale 1ns/1ps

// This test measures full L, not a single 8-bit multiplication.
// Default 100 MHz; functional latency is also one cycle at other periods.
// Functional simulation does not check post-route setup/hold timing.
module tb;
    parameter real CLK_PERIOD_NS = 10.0;
    reg clk = 1'b0;
    always #(CLK_PERIOD_NS / 2.0) clk = ~clk;

    reg rst = 1'b1;
    reg start = 1'b0;
    reg [127:0] a = 128'b0;
    wire [127:0] y;
    wire done;

    l_matrix_onecycle dut (
        .clk(clk), .rst(rst), .data_input_r(start),
        .data_input(a), .data_output(y), .data_output_r(done)
    );

    integer cycle_count = 0;
    integer start_cycle = 0;
    integer end_cycle = 0;
    integer last_cycles = 0;
    integer passed = 0;
    real launch_time_ns;
    real elapsed_ns;

    // Free-running testbench clock counter, not part of the synthesized DUT.
    always @(posedge clk)
        cycle_count = cycle_count + 1;

    task run_example;
        input [127:0] input_value;
        input [127:0] expected_value;
        reg [127:0] previous_y;
        begin
            // Launch just after a rising edge to avoid testbench/DUT races.
            @(posedge clk);
            #0.1;
            if (done !== 1'b0)
                $fatal(1, "Unexpected stale done before launch");

            start_cycle = cycle_count;
            launch_time_ns = $realtime;
            previous_y = y;
            a = input_value;
            start = 1'b1;

            // Registered output must not update immediately with input changes.
            #0.1;
            if (done !== 1'b0 || y !== previous_y)
                $fatal(1, "Output changed before the next rising edge");

            while (done !== 1'b1) begin
                @(posedge clk);
                #0.1; // Wait for nonblocking assignments.
                if (cycle_count - start_cycle > 32)
                    $fatal(1, "Timeout: L did not finish");
            end

            end_cycle = cycle_count;
            last_cycles = end_cycle - start_cycle;
            elapsed_ns = $realtime - launch_time_ns;
            start = 1'b0;

            if (y !== expected_value)
                $fatal(1, "L mismatch: input=%032h actual=%032h expected=%032h",
                       input_value, y, expected_value);
            if (last_cycles != 1)
                $fatal(1, "Expected one cycle, measured %0d", last_cycles);

            passed = passed + 1;
            $display("MATRIX L: input=%032h output=%032h cycles=%0d elapsed_ns=%0.1f",
                     input_value, y, last_cycles, elapsed_ns);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #0.1;
        rst = 1'b0;

        run_example(128'h00000000000000000000000000000000,
                    128'h00000000000000000000000000000000);
        run_example(128'h00000000000000000000000000000001,
                    128'h6ea276726c487ab85d27bd10dd849401);
        run_example(128'h64a59400000000000000000000000000,
                    128'hd456584dd0e3e84cc3166e4b7fa2890d);
        run_example(128'he87de8b6e87de8b6b6b6b6b6b6b6b6b6,
                    128'he297b686e355b0a1cf4a2f9249140830);

        @(posedge clk);
        #0.1;
        if (done !== 1'b0)
            $fatal(1, "done did not clear after start was deasserted");
        $display("PASS: %0d full-L examples; latency = 1 cycle.", passed);
        $finish;
    end
endmodule
"""
if not BACKUP.exists():
    shutil.copy2(TB,BACKUP)
TB.write_text(tb,encoding="utf-8")
print("Generated full-L matrix, verified 4 known examples and 256 random inputs.")
print("Original multiplier testbench backed up:",BACKUP)

