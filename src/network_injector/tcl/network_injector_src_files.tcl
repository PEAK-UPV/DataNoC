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
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/rot_left_vn_p.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/rot_right_vn_p.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/fpa_vn_p.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/update_token_vn_p.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/round_robin_arb_vn_p.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/ibuffer_ni.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/output_ni.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/routing_ni.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/sa_ni.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/va_ni_dynamic.v"]"\
 "[file normalize "${ROOT_PATH}/src/network_injector/rtl/network_injector.v"]"
]


set sim_verilog_files [list \
 "[file normalize "${ROOT_PATH}/src/network_injector/testbench/network_injector_tb.v"]"
]

