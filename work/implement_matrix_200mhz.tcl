set root [file normalize [file join [file dirname [info script]] ..]]
set results [file join $root outputs matrix_200mhz]
file mkdir $results
set archive [file join $root work old_multiplier_reports]
file mkdir $archive
foreach old_file [glob -nocomplain [file join $root CourseLab.runs impl_1 testMatrix*.rpt]] {
    file copy -force $old_file [file join $archive [file tail $old_file]]
}
set old_xdc [file join $root CourseLab.srcs constr_1 constraints.xdc]
if {![file exists [file join $archive constraints_before_L.xdc]]} {
    file copy $old_xdc [file join $archive constraints_before_L.xdc]
}
open_project [file join $root CourseLab.xpr]
set_property top l_matrix_onecycle [get_filesets sources_1]
set_property top_auto_set false [get_filesets sources_1]
set_property top tb_L_function [get_filesets sim_1]
set_property top_auto_set false [get_filesets sim_1]
# Avoid mapping the full 128-bit input/output buses to package I/O.
set_property -dict [list {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} {-mode out_of_context}] [get_runs synth_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
puts "SYNTHESIS_STATUS=[get_property STATUS [get_runs synth_1]]"
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "Synthesis did not complete"
}
open_run synth_1
report_utilization -file [file join $results utilization_synth.rpt]
close_design
launch_runs impl_1 -to_step route_design -jobs 2
wait_on_run impl_1
puts "IMPLEMENTATION_STATUS=[get_property STATUS [get_runs impl_1]]"
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    error "Implementation did not complete"
}
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file [file join $results timing_summary.rpt]
report_timing -delay_type max -max_paths 10 -file [file join $results setup_paths.rpt]
report_utilization -file [file join $results utilization_routed.rpt]
report_methodology -file [file join $results methodology.rpt]
write_checkpoint -force [file join $results l_matrix_onecycle_routed.dcp]
set worst_setup [get_timing_paths -delay_type max -max_paths 1]
set worst_hold [get_timing_paths -delay_type min -max_paths 1]
puts "MATRIX_200MHZ_WNS=[get_property SLACK $worst_setup]"
puts "MATRIX_200MHZ_WHS=[get_property SLACK $worst_hold]"
close_project
exit
