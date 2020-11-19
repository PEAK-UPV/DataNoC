if { ![info exists env(ROOT_PATH)] } {
  error "ROOT_PATH env variable not set - please set to the root of DataNoC directory"
}

variable ROOT_PATH
set ROOT_PATH [set env(ROOT_PATH)]

variable script_file
set script_file "${ROOT_PATH}/vivado/vivado_synth.tcl"

set DEVICE    "xcku115-flvb2104-1-c"
set TOP_SYNTH "switch_2dmesh_vc"
set ODIR      "output_files"

# Help information for this script
proc help {} {
  variable script_file
  variable DEVICE
  variable TOP_SYNTH
  variable ODIR
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--dev <part-number> (default ${DEVICE})\]"
  puts "$script_file -tclargs \[--top_synth <top_module> (default ${TOP_SYNTH})\]"
  puts "$script_file -tclargs \[--output_dir <dir>  (default ${ODIR})\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch $option {
      "--dev" { incr i; set DEVICE [lindex $::argv $i] }
      "--top_synth" {incr i; set TOP_SYNTH [lindex $::argv $i] }
      "--output_dir" { incr i; set ODIR [lindex $::argv $i] }
      "--help"       { help }
      default {
        puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
        return 1
      }
    }
  }
}


#include source files
source ${ROOT_PATH}/src/${TOP_SYNTH}/tcl/${TOP_SYNTH}_src_files.tcl
read_verilog ${src_verilog_files}



# synthetize design
synth_design \
   -top ${TOP_SYNTH} \
   -part ${DEVICE} \
   -include_dirs ${ROOT_PATH}/include \
   -keep_equivalent_registers

# write design after synthesis
write_checkpoint -force ${ODIR}/${TOP_SYNTH}_synthesized.dcp
report_utilization -file ${ODIR}/${TOP_SYNTH}_utilization_synth_rpt

