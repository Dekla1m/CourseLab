set root [file normalize [file join [file dirname [info script]] ..]]
set results [file join $root outputs f_matrix_200mhz]
file mkdir $results
create_project -in_memory -part xc7a100tcsg324-1
read_verilog [file join $root CourseLab.srcs sources_1 l_matrix_onecycle.v]
read_verilog [file join $root CourseLab.srcs sources_1 l_matrix_comb.v]
read_verilog [file join $root CourseLab.srcs sources_1 kuz_lsx_matrix_comb.v]
read_verilog [file join $root CourseLab.srcs sources_1 lsx_matrix_onecycle.v]
read_verilog [file join $root CourseLab.srcs sources_1 f_matrix_onecycle.v]
read_verilog [file join $root work f_matrix_benchmark.v]
read_xdc [file join $root work f_matrix_benchmark.xdc]
synth_design -top f_matrix_benchmark -part xc7a100tcsg324-1 -mode out_of_context
report_utilization -file [file join $results utilization_synth.rpt]
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file [file join $results timing_summary.rpt]
report_timing -delay_type max -from [all_registers] -to [all_registers] -max_paths 10 -file [file join $results setup_paths.rpt]
report_timing -delay_type min -from [all_registers] -to [all_registers] -max_paths 10 -file [file join $results hold_paths.rpt]
report_utilization -file [file join $results utilization_routed.rpt]
report_utilization -hierarchical -file [file join $results utilization_hierarchical.rpt]
report_drc -file [file join $results drc.rpt]
write_checkpoint -force [file join $results f_matrix_benchmark_routed.dcp]
set setup_path [get_timing_paths -delay_type max -from [all_registers] -to [all_registers] -max_paths 1]
set hold_path [get_timing_paths -delay_type min -from [all_registers] -to [all_registers] -max_paths 1]
puts "F_ROUND_200MHZ_SETUP_SLACK=[get_property SLACK $setup_path]"
puts "F_ROUND_200MHZ_HOLD_SLACK=[get_property SLACK $hold_path]"
close_project
exit
