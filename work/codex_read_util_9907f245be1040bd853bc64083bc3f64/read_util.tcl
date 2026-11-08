open_checkpoint {C:/Users/cosmo/VivadoProjects/CourseLab/CourseLab.runs/impl_1/test_impl_IO_low_routed.dcp}
report_utilization -hierarchical -hierarchical_depth 6 -file hierarchy.rpt
foreach {label path} {
  ENC dut/encrypter/round_data_transform
  DEC dut/decrypter/round_data_transform
  KEYS dut/key_schedule
} {
    set cell [get_cells -quiet $path]
    if {[llength $cell] != 1} {
        puts "CELL_NOT_FOUND $path"
        continue
    }
    puts "CELL $label $path [get_property REF_NAME $cell]"
    report_utilization -cells $cell -file ${label}.rpt
    set leaves [get_cells -hierarchical -quiet -filter "IS_PRIMITIVE && NAME =~ $path/*"]
    set locations [get_property LOC $leaves]
    set slices [lsort -unique [lsearch -all -inline -glob $locations SLICE_X*]]
    puts "FOOTPRINT $label [llength $leaves] primitive cells [llength $slices] unique slices"
}
close_design
