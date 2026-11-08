set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root CourseLab.xpr]
set sim [get_filesets sim_1]
set previous_top [get_property top $sim]
set previous_auto [get_property top_auto_set $sim]
set previous_runtime [get_property xsim.simulate.runtime $sim]
set previous_source [get_property SOURCE_SET $sim]
set_property SOURCE_SET sources_1 $sim
set_property top tb_matrix_round $sim
set_property top_auto_set false $sim
set_property xsim.simulate.runtime all $sim
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
close_sim
set log_file [open [file join $root CourseLab.sim sim_1 behav xsim simulate.log] r]
set sim_log [read $log_file]
close $log_file
set_property SOURCE_SET $previous_source $sim
set_property top $previous_top $sim
set_property top_auto_set $previous_auto $sim
set_property xsim.simulate.runtime $previous_runtime $sim
close_project
if {[string first "FAIL:" $sim_log] >= 0 || [string first "ALL PASS: F and LSX;" $sim_log] < 0} {
    error "Project round simulation failed"
}
puts "PROJECT_ROUND_CHECK_PASS: F and LSX directed scenarios"
exit
