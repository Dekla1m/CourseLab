set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK]
create_clock -name sys_clk_pin -period 10.000 [get_ports CLK]

set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports SYS_NRST]
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports UART_RXD]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports UART_TXD]

set_false_path -from [get_ports UART_RXD] -to [get_pins -hier -filter {NAME =~ *SYNCHR/synchr_reg*/D}]
set_property ASYNC_REG TRUE [get_cells -hier -filter {NAME =~ *SYNCHR/synchr_reg*}]
set_false_path -from [get_ports SYS_NRST] -to [get_pins -hier -filter {NAME =~ *rst_sync_reg*/PRE}]

set_false_path -to [get_ports UART_TXD]
