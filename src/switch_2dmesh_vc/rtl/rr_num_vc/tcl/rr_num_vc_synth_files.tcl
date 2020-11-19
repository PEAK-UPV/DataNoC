if { ![info exists env(ROOT_PATH)] } {
  error "ROOT_PATH env variable not set - please set to the root of DataNoC directory"
}

if { ![info exists TARGET_LIBRARY] } {
  set TARGET_LIBRARY libpeak_round_robin
}

# verilog files here
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/switch_2dmesh_vc/rr_num_vc/rtl/rot_left_num_vc.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/switch_2dmesh_vc/rr_num_vc/rtl/rot_right_num_vc.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/switch_2dmesh_vc/rr_num_vc/rtl/fpa_num_vc.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/switch_2dmesh_vc/rr_num_vc/rtl/update_token_num_vc.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/switch_2dmesh_vc/rr_num_vc/rtl/round_robin_arb_num_vc.v


# system verilog files here
#read_verilog -sv -library ${RR_LIBARY} ...

# vhdl files here
#read_vhdl -library ${TARGET_LIBRARY} ...

# xdc files here
#read_xdc ...
