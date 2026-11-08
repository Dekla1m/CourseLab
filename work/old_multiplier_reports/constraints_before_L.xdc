# Тактовый сигнал: период 5 нс.
create_clock -name clk -period 5.000 \
    -waveform {0.000 2.500} [get_ports clk]

# Входной байт a.
set_input_delay -clock clk -max 0.000 [get_ports {a[*]}]
set_input_delay -clock clk -min 0.000 [get_ports {a[*]}]

# Выходной байт y.
set_output_delay -clock clk -max 0.000 [get_ports {y[*]}]
set_output_delay -clock clk -min 0.000 [get_ports {y[*]}]