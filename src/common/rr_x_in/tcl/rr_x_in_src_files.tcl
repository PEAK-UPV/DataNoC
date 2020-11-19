if { ![info exists env(ROOT_PATH)] } {
  error "ROOT_PATH env variable not set - please set to the root of DataNoC directory"
}
set ROOT_PATH [set env(ROOT_PATH)]

set src_verilog_files [list \
 "[file normalize "${ROOT_PATH}/src/common/encoder/rtl/encoder.v"]"\
 "[file normalize "${ROOT_PATH}/src/common/rr_x_in/rtl/fpa_x_in.v"]"\
 "[file normalize "${ROOT_PATH}/src/common/rr_x_in/rtl/rot_left_x_in.v"]"\
 "[file normalize "${ROOT_PATH}/src/common/rr_x_in/rtl/rot_right_x_in.v"]"\
 "[file normalize "${ROOT_PATH}/src/common/rr_x_in/rtl/update_token_x_in.v"]"\
 "[file normalize "${ROOT_PATH}/src/common/rr_x_in/rtl/rr_x_in.v"]"
]

# sim files requires src_files, but they should be added/read in the top file
set sim_verilog_files [list \
 "[file normalize "${ROOT_PATH}/src/common/testbench/rr_x_in_tb.v"]"
]

