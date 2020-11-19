if { ![info exists env(ROOT_PATH)] } {
  error "ROOT_PATH env variable not set - please set to the root of DataNoC directory"
}

variable ROOT_PATH
set ROOT_PATH [set env(ROOT_PATH)]

variable script_file
set script_file "${ROOT_PATH}/vivado/vivado_project.tcl"

set DEVICE    "xcku115-flvb2104-1-c"
set TOP_SYNTH "switch_2dmesh_vc"
set TOP_SIM   "switch_2dmesh_vc"
set ODIR      "output_files"

# Help information for this script
proc help {} {
  variable script_file
  variable DEVICE
  variable TOP_SYNTH
  variable TOP_SIM
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
  puts "$script_file -tclargs \[--top_sim <top_module> (default ${TOP_SIM})\]"
  puts "$script_file -tclargs \[--prj_dir <dir>  (default ${ODIR})\]"
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
      "--top_sim" { incr i; set TOP_SIM [lindex $::argv $i] }
      "--prj_dir" { incr i; set ODIR [lindex $::argv $i] }
      "--help"       { help }
      default {
        puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
        return 1
      }
    }
  }
}

# create the project
create_project -part ${DEVICE} data_noc ${ODIR}

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# project properties
set obj [get_projects data_noc]
set_property -name "target_language" -value "Verilog" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'sources_1' fileset object
set obj_src [get_filesets sources_1]

# Set 'sim_1' fileset object
set obj_sim [get_filesets sim_1]

# Set 'constrs_1' fileset object
set obj_xdc [get_filesets constrs_1]

# add switch_2dmesh_vc source files to project
source ${ROOT_PATH}/src/switch_2dmesh_vc/tcl/switch_2dmesh_vc_src_files.tcl
add_files -norecurse -fileset $obj_src $src_verilog_files
add_files -norecurse -fileset $obj_sim $sim_verilog_files
#add_files -norecurse -fileset $obj_xdc $xdc_synth_files
#add_files -norecurse -fileset $obj_xdc $xdc_impl_files

# add network_injector source files to project
source ${ROOT_PATH}/src/network_injector/tcl/network_injector_src_files.tcl
add_files -norecurse -fileset $obj_src $src_verilog_files
add_files -norecurse -fileset $obj_sim $sim_verilog_files
#add_files -norecurse -fileset $obj_xdc $xdc_synth_files
#add_files -norecurse -fileset $obj_xdc $xdc_impl_files

# switch and injector properties for the vivado project
source ${ROOT_PATH}/src/switch_2dmesh_vc/tcl/switch_2dmesh_vc_project_properties.tcl
source ${ROOT_PATH}/src/network_injector/tcl/network_injector_project_properties.tcl

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "design_mode" -value "RTL" -objects $obj
set_property -name "generic" -value "" -objects $obj
set_property -name "include_dirs" -value "[file normalize "${ROOT_PATH}/include"]" -objects $obj
set_property -name "lib_map_file" -value "" -objects $obj
set_property -name "loop_count" -value "1000" -objects $obj
set_property -name "name" -value "sources_1" -objects $obj
set_property -name "top" -value "${TOP_SYNTH}" -objects $obj


# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "name" -value "constrs_1" -objects $obj
set_property -name "target_constrs_file" -value "" -objects $obj


# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "generic" -value "" -objects $obj
set_property -name "include_dirs" -value "[file normalize "${ROOT_PATH}/include"]" -objects $obj
set_property -name "name" -value "sim_1" -objects $obj
set_property -name "source_set" -value "sources_1" -objects $obj
set_property -name "top" -value "${TOP_SIM}" -objects $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:data_noc"

start_gui

