if { ![info exists env(ROOT_PATH)] } {
  error "ROOT_PATH env variable not set - please set to the root of DataNoC directory"
}

set ROOT_PATH [set env(ROOT_PATH)]

# here source files for synthesis
#set src_verilog_files [list \
#]

# here sim files
set sim_verilog_files [list \
 "[file normalize "${ROOT_PATH}/sim_examples/include/synthetic_traffic_generator.h"]"\
 "[file normalize "${ROOT_PATH}/sim_examples/rtl/random_seed.v"]"\
 "[file normalize "${ROOT_PATH}/sim_examples/rtl/ms.v"]"\
 "[file normalize "${ROOT_PATH}/sim_examples/rtl/mesh2d_vc_tb.v"]"
]
