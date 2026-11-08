# Full-L core benchmark at 200 MHz; out-of-context.
# Ideal boundary delays; no board pin assignments.
create_clock -name clk -period 5.000 -waveform {0.000 2.500} [get_ports clk]
set_input_delay -clock clk -max 0.000 [get_ports {a[*] start rst}]
set_input_delay -clock clk -min 0.000 [get_ports {a[*] start rst}]
set_output_delay -clock clk -max 0.000 [get_ports {y[*] done}]
set_output_delay -clock clk -min 0.000 [get_ports {y[*] done}]
