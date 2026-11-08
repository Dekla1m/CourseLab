set root [file normalize [file join [file dirname [info script]] ..]]
set tests [file join $root work fifo_tests]
create_project -force fifo_original [file join $tests original] -part xc7a100tcsg324-1
add_files [file join $tests FIFO_original.v]
add_files -fileset sim_1 [file join $root CourseLab.srcs sim_1 tb_fifo_original.v]
set_property top tb_fifo_original [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation -mode behavioral
close_sim
set f [open [file join $tests original fifo_original.sim sim_1 behav xsim simulate.log] r]
set original_log [read $f]
close $f
if {[string first "REPRODUCED ORIGINAL BUG" $original_log] < 0} {error "Original bug not reproduced"}
close_project

open_project [file join $root CourseLab.xpr]
set fifo [file join $root CourseLab.srcs sources_1 FIFO.v]
add_files -norecurse -fileset sources_1 $fifo
add_files -norecurse -fileset sources_uart $fifo
if {[llength [get_filesets -quiet sim_fifo]] == 0} {create_fileset -simset sim_fifo}
set_property SOURCE_SET sources_uart [get_filesets sim_fifo]
add_files -fileset sim_fifo [file join $root CourseLab.srcs sim_1 tb_fifo.v]
set_property top tb_fifo [get_filesets sim_fifo]
set_property top_auto_set false [get_filesets sim_fifo]
set_property xsim.simulate.runtime all [get_filesets sim_fifo]
update_compile_order -fileset sim_fifo
launch_simulation -simset sim_fifo -mode behavioral
close_sim
set f [open [file join $root CourseLab.sim sim_fifo behav xsim simulate.log] r]
set fixed_log [read $f]
close $f
current_fileset -simset [get_filesets sim_uart]
close_project
if {[string first "ALL PASS: FIFO unit test;" $fixed_log] < 0} {error "Fixed FIFO test failed"}
puts "FIFO_CHECK_SUCCESS: original failure reproduced; corrected FIFO passed all configurations"
