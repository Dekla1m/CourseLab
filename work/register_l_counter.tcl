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
set iterative_file [file join $root CourseLab.srcs experiments l_iterative_16cycles.v]
if {[llength [get_files -quiet $iterative_file]] == 0} {
    add_files -fileset sources_1 -norecurse $iterative_file
}
set iterative_tb [file join $root CourseLab.srcs experiments tb_iterative.v]
if {[llength [get_files -quiet $iterative_tb]] == 0} {
    add_files -fileset sim_1 -norecurse $iterative_tb
}
set_property top testMatrix [get_filesets sources_1]
set_property top_auto_set false [get_filesets sources_1]
set_property top tb_L_function [get_filesets sim_1]
set_property top_auto_set false [get_filesets sim_1]
set_property xsim.simulate.runtime 1000ns [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project
exit
