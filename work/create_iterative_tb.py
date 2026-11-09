from pathlib import Path
root = Path(__file__).resolve().parents[1]
tb = (root / "CourseLab.srcs/experiments/tb.v").read_text(encoding="utf-8")
tb = tb.replace("module tb;", "module tb_iterative;")
tb = tb.replace("Default 100 MHz; functional latency is also one cycle at other periods.", "Default 100 MHz; functional latency is 16 cycles.")
tb = tb.replace("wire done;", "wire done;\n    wire busy;")
# The iterative module retains its original port names.
tb = tb.replace(".data_input_r(start)", ".start(start)").replace(".data_input(a)", ".a(a)")
tb = tb.replace(".data_output(y)", ".y(y)").replace(".data_output_r(done)", ".done(done)")
tb = tb.replace("l_matrix_onecycle dut", "l_iterative_16cycles dut")
tb = tb.replace(".a(a), .y(y), .done(done)", ".a(a), .y(y), .done(done), .busy(busy)")
tb = tb.replace("last_cycles != 1", "last_cycles != 16")
tb = tb.replace("Expected one cycle, measured", "Expected 16 cycles, measured")
tb = tb.replace("MATRIX L:", "ITERATIVE L:")
tb = tb.replace("latency = 1 cycle.", "latency = 16 cycles.")
(root / "CourseLab.srcs/experiments/tb_iterative.v").write_text(tb,encoding="utf-8")
print("Created tb_iterative: the same four full-L examples and cycle counter.")
