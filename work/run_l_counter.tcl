set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root CourseLab.xpr]
set source_file [file join $root CourseLab.srcs experiments l_matrix_onecycle.v]
set matrix_file [file join $root CourseLab.srcs sources_1 l_matrix_comb.v]
if {[llength [get_files -quiet $matrix_file]] == 0} {
    add_files -fileset sources_1 -norecurse $matrix_file
}
if {[llength [get_files -quiet $source_file]] == 0} {
    add_files -fileset sources_1 -norecurse $source_file
}
# Keep the existing multiplier as the synthesis top for this simulation-only step.
set_property top testMatrix [get_filesets sources_1]
set_property top_auto_set false [get_filesets sources_1]
set_property top tb_L_function [get_filesets sim_1]
set_property top_auto_set false [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set previous_runtime [get_property xsim.simulate.runtime [get_filesets sim_1]]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
log_wave -r /
run all
close_sim
set_property xsim.simulate.runtime $previous_runtime [get_filesets sim_1]
close_project
exit
