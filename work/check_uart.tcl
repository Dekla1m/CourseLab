set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root CourseLab.xpr]
launch_simulation -simset sim_uart -mode behavioral
close_sim
set log_file [open [file join $root CourseLab.sim sim_uart behav xsim simulate.log] r]
set sim_log [read $log_file]
close $log_file
if {[string first "ALL PASS: 10 serial transactions" $sim_log] < 0} {error "UART simulation failed"}
# Optional argument: simulation only, without synthesis or implementation.
if {[lsearch -exact $argv sim_only] >= 0} {close_project; exit}
# Clear only the new UART run's abandoned launcher state.
reset_run synth_uart
close_project
# Run in-process: avoids the Windows run-launcher dependency.
create_project -in_memory -part xc7a100tcsg324-1
read_verilog [glob [file join $root CourseLab.srcs sources_1 *.v]]
read_verilog [file join $root CourseLab.srcs sources_1 FIFO.v]
read_xdc [file join $root CourseLab.srcs constr_1 uart_board.xdc]
synth_design -top kuz_uart_top -part xc7a100tcsg324-1
set results [file join $root outputs uart_100mhz]
file mkdir $results
report_utilization -file [file join $results utilization_synth.rpt]
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file [file join $results timing_summary.rpt]
report_utilization -file [file join $results utilization_routed.rpt]
report_drc -file [file join $results drc.rpt]
write_checkpoint -force [file join $results kuz_uart_top_routed.dcp]
set setup_slack [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
set hold_slack [get_property SLACK [get_timing_paths -delay_type min -max_paths 1]]
puts "UART_100MHZ_WNS=$setup_slack WHS=$hold_slack"
if {$setup_slack < 0 || $hold_slack < 0} {error "UART timing constraints not met"}
close_project
