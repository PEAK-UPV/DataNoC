///////////////////////////////////////////////////////////////////////////////
// DataNoC
// 
// Copyright (c) 2021 PEAK UPV
// Parallel Architectures Group (GAP)
// Department of Computing Engineering (DISCA)
// Universitat Politecnica de Valencia (UPV)
// Valencia, Spain
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 
//-----------------------------------------------------------------------------
//
// Company: GAP (UPV) 
// Engineer: R. Tornero (ratorga@disca.upv.es)
// Contact: J.Flich (jflich@disca.upv.es)
// Create Date: October 11, 2016
// File Name: data_net_virtual_channel.h
// Module Name:
// Project Name: DataNoC
// Target Devices: 
// Description: 
//
//  This file provides the parameters required for definining width, offsets and
//  formats of a phit/flit data network with Virtual Channel support. Also, the
//  format of the buses that connect the Routers (SW) among them and NI to SW is provided.
//
//  It assumes the following macros or parameters are defined:
//      `DATA_NET_FLIT_w or DATA_NET_FLIT_w, Flit size
//      `DATA_NET_PHIT_w or DATA_NET_PHIT_w, Phit size
//      `DATA_NET_FLIT_UNIT_ID_w or DATA_NET_FLIT_UNIT_ID_w, SRC/DST ID width
//      `DATA_NET_FLIT_UNIT_TYPE_w or DATA_NET_FLIT_UNIT_TYPE_w, SRC/DST component type width
//      `DATA_NET_FLIT_MSG_TYPE_w or DATA_NET_FLIT_MSG_TYPE_w, message type width
//      `DATA_NET_NUM_VN, num Virtual Networks
//      `DATA_NET_NUM_VC_PER_VN, Num Virtual Channels per Virtual Network
//      `DATA_NET_IB_QUEUE_SIZE or DATA_NET_IB_QUEUE_SIZE, input buffer sizes at routers
//      `DATA_NET_IB_SG_UPPER_THRESHOLD or DATA_NET_IB_SG_UPPER_THRESHOLD, S&G upper threshold
//      `DATA_NET_IB_SG_LOWER_THRESHOLD or DATA_NET_IB_SG_LOWER_THRESHOLD, S&G lower threshold
//      `DATA_NET_VC_DYNAMIC_WAY (Optional)
//      `DATA_NET_VN_WITH_PRIORITIES (Optional) 
//      `DATA_NET_VN_WEIGTH_PRIORITIES 2'd2, 2'd1,... (Optional)
//
//  The format of the SW<->SW and NI->SW bus (when DATA_NET_FLIT_w as physical transfer unit) is:
//        Virtual Channel (VC_w) |  Broadcast (1) | Valid (1) | Go (NUM_VC) 
//      | Flit (programable using DATA_NET_FLIT_w)
//
//  The format of the SW<->SW and NI->SW bus (when using DATA_NET_PHIT_w as physical transfer unit) is:
//        Virtual Channel (VC_w) | Broadcast (1) | Valid (1) | Go (NUM_VC) 
//      | Phit (programable using DATA_NET_PHIT_w) 
//
//  The format of a flit is:
//
//        MSG_TYPE (DATA_NET_MSG_FLIT_MSG_TYPE_w) | (DST_UNIT_ID[DATA_NET_FLIT_UNIT_ID_w],DST_UNIT_TYPE[DATA_NET_FLIT_UNIT_TYPE_w]) 
//        | (SRC_UNIT_ID[DATA_NET_FLIT_UNIT_ID_w],SRC_UNIT_TYPE[DATA_NET_FLIT_UNIT_TYPE_w]) | PADDING/PAYLOAD(DATA_NET_FLIT_w-MSG_TYPE_w-DST_w-SRC_w)
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef __DATA_NET_VIRTUAL_CHANNEL_H__
`define __DATA_NET_VIRTUAL_CHANNEL_H__ 

`define DATA_NET_VC_SUPPORT

// * Defines support for Virtual Channels (compatibility)
`define VC_SUPPORT

// // * defines the default input buffer size for datanet routers
// `ifndef DATA_NET_IB_QUEUE_SIZE
//   `define DATA_NET_IB_QUEUE_SIZE DATA_NET_IB_QUEUE_SIZE
// `endif

// // * defines the upper threshold for the Stop&Go flow control between datanet routers
// `ifndef DATA_NET_IB_SG_UPPER_THRESHOLD
//   `define DATA_NET_IB_SG_UPPER_THRESHOLD DATA_NET_IB_SG_UPPER_THRESHOLD
// `endif

// // * defines the lower threshold for the Stop&Go flow control between datanet routers
// `ifndef DATA_NET_IB_SG_LOWER_THRESHOLD
//   `define DATA_NET_IB_SG_LOWER_THRESHOLD DATA_NET_IB_SG_LOWER_THRESHOLD
// `endif

// // * Defines the width of the Unit ID, but if not defined externally
// // * UID is unique for each Unit
// `ifndef DATA_NET_FLIT_UNIT_ID_w 
//   `define DATA_NET_FLIT_UNIT_ID_w DATA_NET_FLIT_UNIT_ID_w
// `endif

// // * Defines the width of type of a component, only if not defined externally
// `ifndef DATA_NET_FLIT_UNIT_TYPE_w
//   `define DATA_NET_FLIT_UNIT_TYPE_w DATA_NET_FLIT_UNIT_TYPE_w
// `endif

// // * Defines the width for the message type, if not defined externally
// `ifndef DATA_NET_FLIT_MSG_TYPE_w
//   `define DATA_NET_FLIT_MSG_TYPE_w DATA_NET_FLIT_MSG_TYPE_w
// `endif

// // * defines the width of a flit, when is not defined yet
// `ifndef DATA_NET_FLIT_w
//   `define DATA_NET_FLIT_w DATA_NET_FLIT_w
// `endif

// // * defines the width of a phit, when is not defined yet
// `ifndef DATA_NET_PHIT_w
//   `define DATA_NET_PHIT_w DATA_NET_PHIT_w
// `endif

// // * defines the number of Virtual Networks, when is not defined yet
// `ifndef DATA_NET_NUM_VN
//   `define DATA_NET_NUM_VN DATA_NET_NUM_VN
// `endif  

// // * defines the number of Virtual Channels per Virtual Networks, when is not defined yet
// `ifndef DATA_NET_NUM_VC_PER_VN
//   `define DATA_NET_NUM_VC_PER_VN DATA_NET_NUM_VC_PER_VN
// `endif  

//*************** COMMON DEFINITIONS FOR PHIT AND FLIT ******************************************************


// * defines the total number of Virtual channels
`define DATA_NET_NUM_VC `DATA_NET_NUM_VC_PER_VN * `DATA_NET_NUM_VN

// * defines the number of bits required to code the datanet flit types
`define DATA_NET_FT_w 2

// * defines the width for the GO bus signal coming from the Network router
`define DATA_NET_GO_w `DATA_NET_NUM_VC

// * defines the width for the Valid bus signal going to the Network router
`define DATA_NET_VALID_w 1

// * defines the width for the Broadcast bus signal going to the Network router
`define DATA_NET_BC_w 1

// * defines the number of bits required for coding a Virtual Network
`define DATA_NET_VN_w Log2_w(`DATA_NET_NUM_VN)

// * defines the number of bits required for coding a Virtual Channel
`define DATA_NET_VC_w Log2_w(`DATA_NET_NUM_VC)

// * defines the number of bits required for coding a Virtual Network/Virtual Channel
`define DATA_NET_NUM_VC_PER_VN_w Log2_w(`DATA_NET_NUM_VC_PER_VN)

// * the FlitType lsb offset in the signals bus used for connecting data routers
`define DATA_NET_FT_LSB 0 

// * defines the FlitType msb offset in the signals bus used for connecting data routers
`define DATA_NET_FT_MSB `DATA_NET_FT_LSB + `DATA_NET_FT_w - 1 

// * defines the GO lsb offset in the signals bus used for connecting data routers
`define DATA_NET_GO_LSB `DATA_NET_FT_MSB + 1 

// * defines the GO msb offset in the signals bus used for connecting data routers
`define DATA_NET_GO_MSB `DATA_NET_GO_LSB + `DATA_NET_GO_w - 1 

// * defines the VALID LSB offset in the signals bus used for connecting data routers
`define DATA_NET_VALID_LSB `DATA_NET_GO_MSB + 1

// * defines the VALID MSB offset in the signals bus used for connecting data routers
`define DATA_NET_VALID_MSB `DATA_NET_VALID_LSB + `DATA_NET_VALID_w - 1

// * defines the BroadCast LSB offset in the signals bus used for connecting data routers
`define DATA_NET_BC_LSB `DATA_NET_VALID_MSB + 1

// * defines the BroadCast MSB offset in the signals bus used for connecting data routers
`define DATA_NET_BC_MSB `DATA_NET_BC_LSB + `DATA_NET_BC_w - 1

// * defines the VirtualChannel lsb offset in the signals bus used for connecting data routers
`define DATA_NET_VC_LSB `DATA_NET_BC_MSB + 1 

// * defines the VirtualChannel msb offset in the signals bus used for connecting data routers
`define DATA_NET_VC_MSB `DATA_NET_VC_LSB + `DATA_NET_VC_w - 1 

// * defines the number of control signals used in the datanet
// * Currently are: see file description at the head
// * MODIFY! this setting when the number of control signals changes for the datanet 
`define DATA_NET_NUM_CONTROL_SIGNALS `DATA_NET_VC_w + `DATA_NET_BC_w + `DATA_NET_VALID_w + `DATA_NET_GO_w + `DATA_NET_FT_w



// ********************* FLIT FORMAT **************************************



// * Defines the width of the SRC field
`define DATA_NET_FLIT_SRC_w `DATA_NET_FLIT_UNIT_ID_w + `DATA_NET_FLIT_UNIT_TYPE_w

// * Defines the width of the DST field
`define DATA_NET_FLIT_DST_w `DATA_NET_FLIT_UNIT_ID_w + `DATA_NET_FLIT_UNIT_TYPE_w

// * Defines the width of the payload field
`define DATA_NET_FLIT_PADDING_w `DATA_NET_FLIT_w - `DATA_NET_FLIT_MSG_TYPE_w - (`DATA_NET_FLIT_DST_w) - (`DATA_NET_FLIT_SRC_w) 


// * Defines the payload Least significant bit in the flit
`define DATA_NET_FLIT_PADDING_LSB 0

// * Defines the payload most significant bit in the flit
`define DATA_NET_FLIT_PADDING_MSB `DATA_NET_FLIT_PADDING_w - 1

// * Defines the destination LSB in the flit
`define DATA_NET_FLIT_DST_LSB `DATA_NET_FLIT_PADDING_MSB + 1

// * Defines the destination MSB in the flit
`define DATA_NET_FLIT_DST_MSB `DATA_NET_FLIT_DST_LSB + `DATA_NET_FLIT_DST_w - 1

// Defines the component type MSB for the destination in the flit
`define DATA_NET_FLIT_DST_UNIT_TYPE_LSB `DATA_NET_FLIT_DST_LSB

// * Defines the component type MSB for the destination in the flit
`define DATA_NET_FLIT_DST_UNIT_TYPE_MSB `DATA_NET_FLIT_DST_UNIT_TYPE_LSB + `DATA_NET_FLIT_UNIT_TYPE_w - 1

// * Defines the component id MSB for the destination in the flit
`define DATA_NET_FLIT_DST_UNIT_ID_LSB `DATA_NET_FLIT_DST_UNIT_TYPE_MSB + 1

// * Defines the component id MSB for the destination in the flit
`define DATA_NET_FLIT_DST_UNIT_ID_MSB `DATA_NET_FLIT_DST_UNIT_ID_LSB + `DATA_NET_FLIT_UNIT_ID_w - 1

// * Defines the source LSB in the flit
`define DATA_NET_FLIT_SRC_LSB `DATA_NET_FLIT_DST_MSB + 1

// * Defines the source MSB in the flit
`define DATA_NET_FLIT_SRC_MSB `DATA_NET_FLIT_SRC_LSB + `DATA_NET_FLIT_SRC_w - 1

// * Defines the component type LSB for the source in the flit
`define DATA_NET_FLIT_SRC_UNIT_TYPE_LSB `DATA_NET_FLIT_SRC_LSB

// * Defines the component type MSB for the source in the flit
`define DATA_NET_FLIT_SRC_UNIT_TYPE_MSB `DATA_NET_FLIT_SRC_UNIT_TYPE_LSB + `DATA_NET_FLIT_UNIT_TYPE_w - 1

// * Defines the component ID LSB for the source in the flit
`define DATA_NET_FLIT_SRC_UNIT_ID_LSB `DATA_NET_FLIT_SRC_UNIT_TYPE_MSB + 1

// * Defines the component ID  MSB for the source in the flit
`define DATA_NET_FLIT_SRC_UNIT_ID_MSB `DATA_NET_FLIT_SRC_UNIT_ID_LSB + `DATA_NET_FLIT_UNIT_ID_w - 1

// * Defines the message type LSB in the flit
`define DATA_NET_FLIT_MSG_TYPE_LSB `DATA_NET_FLIT_SRC_MSB + 1

// * Defines the message type MSB in the flit
`define DATA_NET_FLIT_MSG_TYPE_MSB `DATA_NET_FLIT_MSG_TYPE_LSB + `DATA_NET_FLIT_MSG_TYPE_w - 1



//************************ In between Router<->Router or Inject->Router bus signals: DEFINITIONS and RANGES when phit = flit *****************************


// * defines the number of bits required between datanet routers when using flits
`define DATA_NET_FLIT_NUM_WIRES `DATA_NET_FLIT_w + `DATA_NET_NUM_CONTROL_SIGNALS

// * defines the bus range for the signals between routers using flits 
`define DATA_NET_FLIT_SIGNALS_RANGE `DATA_NET_FLIT_NUM_WIRES-1:0

// * defines the bus range for the flit in the signals bus between routers using flits 
`define DATA_NET_FLIT_RANGE `DATA_NET_FLIT_w-1:0

// * defines the bus range for FT in the signals bus between routers using flits 
`define DATA_NET_FLIT_FT_RANGE `DATA_NET_FLIT_w + `DATA_NET_FT_MSB :`DATA_NET_FLIT_w + `DATA_NET_FT_LSB

// * defines the bus range for GO in the signals bus between routers using flits 
`define DATA_NET_FLIT_GO_RANGE `DATA_NET_FLIT_w + `DATA_NET_GO_MSB : `DATA_NET_FLIT_w + `DATA_NET_GO_LSB

// * defines the bus range for VALID in the signals bus between routers using flits 
`define DATA_NET_FLIT_VALID_RANGE `DATA_NET_FLIT_w + `DATA_NET_VALID_MSB : `DATA_NET_FLIT_w + `DATA_NET_VALID_LSB

// * defines the bus range for BC in the signals bus between routers using flits 
`define DATA_NET_FLIT_BC_RANGE `DATA_NET_FLIT_w + `DATA_NET_BC_MSB : `DATA_NET_FLIT_w + `DATA_NET_BC_LSB

// * defines the bus range for VN_X_VC in the signals bus between routers using flits 
`define DATA_NET_FLIT_VC_RANGE `DATA_NET_FLIT_w + `DATA_NET_VC_MSB : `DATA_NET_FLIT_w + `DATA_NET_VC_LSB



//********************** In between Router<->Router bus signals: PHIT DEFINITIONS and ranges *******************************


// * defines the number of bits required between datanet routers when using phits
`define DATA_NET_PHIT_NUM_WIRES `DATA_NET_PHIT_w + `DATA_NET_NUM_CONTROL_SIGNALS

// * defines the bus range for the signals between routers using phits
`define DATA_NET_PHIT_SIGNALS_RANGE `DATA_NET_PHIT_NUM_WIRES-1:0

// * defines the bus range for the phit in the signals bus between routers using phits 
`define DATA_NET_PHIT_RANGE `DATA_NET_PHIT_w-1 : 0

// * defines the bus range for FT in the signals bus between routers using phits 
`define DATA_NET_PHIT_FT_RANGE `DATA_NET_PHIT_w + `DATA_NET_FT_MSB : `DATA_NET_PHIT_w + `DATA_NET_FT_LSB

// * defines the bus range for GO in the signals bus between routers using phits 
`define DATA_NET_PHIT_GO_RANGE `DATA_NET_PHIT_w + `DATA_NET_GO_MSB : `DATA_NET_PHIT_w + `DATA_NET_GO_LSB

// * defines the bus range for VALID in the signals bus between routers using phits 
`define DATA_NET_PHIT_VALID_RANGE `DATA_NET_PHIT_w + `DATA_NET_VALID_MSB : `DATA_NET_PHIT_w + `DATA_NET_VALID_LSB

// * defines the bus range for BC in the signals bus between routers using phits 
`define DATA_NET_PHIT_BC_RANGE `DATA_NET_PHIT_w + `DATA_NET_BC_MSB : `DATA_NET_PHIT_w + `DATA_NET_BC_LSB

// * defines the bus range for VC in the signals bus between routers using phits 
`define DATA_NET_PHIT_VC_RANGE `DATA_NET_PHIT_w + `DATA_NET_VC_MSB : `DATA_NET_PHIT_w + `DATA_NET_VC_LSB




`endif // file header
