if { ![info exists env(ROOT_PATH)] } {
  error "ROOT_PATH env variable not set - please set to the root of DataNoC directory"
}

if { ![info exists TARGET_LIBRARY] } {
  set TARGET_LIBRARY libpeak_round_robin_arb
}

# verilog files here
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/rot_left_vn_p.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/rot_right_vn_p.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/fpa_vn_p.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/update_token_vn_p.v
read_verilog -library ${TARGET_LIBRARY} ${ROOT_PATH}/src/network_injector/rtl/rr_vn_p/rtl/round_robin_arb_vn_p.v


# system verilog files here
#read_verilog -sv -library ${TARGET_LIBARY} ...

# vhdl files here
#read_vhdl -library ${TARGET_LIBRARY} ...

# xdc files here
#read_xdc ...
