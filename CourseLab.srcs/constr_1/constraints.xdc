set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports rst]

#set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports BTN_0]
#set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports BTN_1]

#set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports UART_RXD]
#set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports UART_TXD]

