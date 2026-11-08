set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root CourseLab.xpr]
if {[llength [get_filesets -quiet sources_uart]] == 0} {create_fileset -srcset sources_uart}
add_files -norecurse -fileset sources_uart [glob [file join $root CourseLab.srcs sources_1 *.v]]
add_files -norecurse -fileset sources_uart [file join $root CourseLab.srcs sources_1 FIFO.v]
set_property top kuz_uart_top [get_filesets sources_uart]
set_property top_auto_set false [get_filesets sources_uart]
if {[llength [get_filesets -quiet constrs_uart]] == 0} {create_fileset -constrset constrs_uart}
add_files -norecurse -fileset constrs_uart [file join $root CourseLab.srcs constr_1 uart_board.xdc]
if {[llength [get_filesets -quiet sim_uart]] == 0} {create_fileset -simset sim_uart}
set_property SOURCE_SET sources_uart [get_filesets sim_uart]
add_files -norecurse -fileset sim_uart [file join $root CourseLab.srcs sim_1 tb_kuz_uart.v]
set_property top tb_kuz_uart [get_filesets sim_uart]
set_property top_auto_set false [get_filesets sim_uart]
set_property xsim.simulate.runtime all [get_filesets sim_uart]
if {[llength [get_runs -quiet synth_uart]] == 0} {
    create_run synth_uart -flow {Vivado Synthesis 2022} -strategy {Vivado Synthesis Defaults} -srcset sources_uart -constrset constrs_uart -part xc7a100tcsg324-1
}
if {[llength [get_runs -quiet impl_uart]] == 0} {
    create_run impl_uart -parent_run synth_uart -flow {Vivado Implementation 2022} -strategy {Vivado Implementation Defaults} -constrset constrs_uart -part xc7a100tcsg324-1
}
current_run -synthesis synth_uart
current_run -implementation impl_uart
current_fileset -simset [get_filesets sim_uart]
update_compile_order -fileset sources_uart
update_compile_order -fileset sim_uart
close_project
