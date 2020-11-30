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
 "[file normalize "${ROOT_PATH}/src/common/rr_x_in/rtl/rr_x_in.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/rr_num_vc/rtl/fpa_num_vc.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/ibuffer_vc.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/output_vc.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/routing_vc.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/sa_vc.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/va_dynamic.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/va_local_dynamic.v"]"\
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/rtl/switch_2dmesh_vc.v"]"
]

# sim files requires src_files, but they should be added/read in the top file
set sim_verilog_files [list \
 "[file normalize "${ROOT_PATH}/src/switch_2dmesh_vc/testbench/switch_2dmesh_vc_tb.v"]"
]


