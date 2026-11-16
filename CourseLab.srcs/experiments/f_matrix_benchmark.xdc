# Isolated FF -> full F -> FF benchmark, not board/interface timing sign-off.
create_clock -name clk -period 5.000 [get_ports clk]
set_false_path -from [get_ports {a[*] b[*] k[*] start rst}]
set_false_path -to [get_ports {a_next[*] b_next[*] done}]
