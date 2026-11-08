set root [file normalize [file join [file dirname [info script]] ..]]
set opened_here [expr {[llength [get_projects -quiet]] == 0}]
if {$opened_here} {
    open_project [file join $root CourseLab.xpr]
} elseif {![string equal -nocase [file normalize [get_property DIRECTORY [current_project]]] $root]} {
    error "Open CourseLab before sourcing this script"
}
set old_top [get_property top [get_filesets sources_1]]
set old_sim [get_property name [current_fileset -simset]]
foreach name {l_matrix_comb l_matrix_onecycle kuz_lsx_matrix_comb lsx_matrix_onecycle f_matrix_onecycle} {
    set source_file [file join $root CourseLab.srcs sources_1 ${name}.v]
    if {[llength [get_files -quiet -of_objects [get_filesets sources_1] $source_file]] == 0} {
        add_files -norecurse -fileset sources_1 $source_file
    }
    set source_object [get_files -of_objects [get_filesets sources_1] $source_file]
    set_property library xil_defaultlib $source_object
    set_property used_in_synthesis true $source_object
    set_property used_in_simulation true $source_object
}
update_compile_order -fileset sources_1
if {[llength [get_filesets -quiet sim_round]] != 0} {
    update_compile_order -fileset sim_round
}
set_property top $old_top [get_filesets sources_1]
current_fileset -simset [get_filesets $old_sim]
# HDL compilation and simulation are checked by check_matrix_round.ps1.
# Here validate project registration without changing the selected source run.
foreach name {l_matrix_comb l_matrix_onecycle kuz_lsx_matrix_comb lsx_matrix_onecycle f_matrix_onecycle} {
    set source_file [file join $root CourseLab.srcs sources_1 ${name}.v]
    if {[llength [get_files -quiet -of_objects [get_filesets sources_1] $source_file]] != 1} {
        error "Expected exactly one project entry for $name"
    }
}
puts "SPLIT_MODULES_PROJECT_PASS: five separate files; selected top=$old_top"
check_syntax -fileset sources_1
if {$opened_here} {
    close_project
} else {
    puts "GUI updated: module sources registered; project remains open."
}
