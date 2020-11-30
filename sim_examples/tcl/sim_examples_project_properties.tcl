if { ![info exists env(ROOT_PATH)] } {
  error "ROOT_PATH env variable not set - please set to the root of DataNoC directory"
}

set ROOT_PATH [set env(ROOT_PATH)]

set file "${ROOT_PATH}/sim_examples/rtl/mesh2d_vc_tb.v"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "Verilog" $file_obj
set_property "is_enabled" "1" $file_obj
set_property "is_global_include" "0" $file_obj
set_property "library" "xil_defaultlib" $file_obj
set_property "path_mode" "RelativeFirst" $file_obj
set_property "used_in" "simulation" $file_obj
set_property "used_in_implementation" "0" $file_obj
set_property "used_in_simulation" "1" $file_obj
set_property "used_in_synthesis" "0" $file_obj

set file "${ROOT_PATH}/sim_examples/rtl/ms.v"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "Verilog" $file_obj
set_property "is_enabled" "1" $file_obj
set_property "is_global_include" "0" $file_obj
set_property "library" "xil_defaultlib" $file_obj
set_property "path_mode" "RelativeFirst" $file_obj
set_property "used_in" "simulation" $file_obj
set_property "used_in_implementation" "0" $file_obj
set_property "used_in_simulation" "1" $file_obj
set_property "used_in_synthesis" "0" $file_obj

set file "${ROOT_PATH}/sim_examples/rtl/random_seed.v"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "Verilog" $file_obj
set_property "is_enabled" "1" $file_obj
set_property "is_global_include" "0" $file_obj
set_property "library" "xil_defaultlib" $file_obj
set_property "path_mode" "RelativeFirst" $file_obj
set_property "used_in" "simulation" $file_obj
set_property "used_in_implementation" "0" $file_obj
set_property "used_in_simulation" "1" $file_obj
set_property "used_in_synthesis" "0" $file_obj

set file "${ROOT_PATH}/sim_examples/include/synthetic_traffic_generator.h"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "Verilog Header" $file_obj
set_property "is_enabled" "1" $file_obj
set_property "is_global_include" "0" $file_obj
set_property "library" "xil_defaultlib" $file_obj
set_property "path_mode" "RelativeFirst" $file_obj
set_property "used_in" "simulation" $file_obj
set_property "used_in_simulation" "1" $file_obj
set_property "used_in_synthesis" "0" $file_obj
