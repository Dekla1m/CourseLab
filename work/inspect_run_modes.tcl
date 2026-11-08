open_project [file normalize [file join [file dirname [info script]] .. CourseLab.xpr]]
foreach p [list_property [get_runs synth_1]] {
    if {[regexp {MODE|IOBUF|MORE} $p]} {
        puts "RUN_PROPERTY $p = [get_property $p [get_runs synth_1]]"
    }
}
close_project
exit
