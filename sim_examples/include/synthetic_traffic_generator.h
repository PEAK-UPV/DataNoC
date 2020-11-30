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
//-----------------------------------------------------------------------------
//
// Company:   GAP (UPV)
// Engineer:  R. Tornero (ratorga@disca.upv.es)
// Contact:   J. Flich (jflich@disca.upv.es)
//
// Create Date: 11.10.2016 16:43:24
// File Name: peak_synthetic_traffic_generator.h
// Design Name:
// Module Name:
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
//   This file defines parameters for MESSAGE_SYSTEM
//   The following macros or parameters must be predefined:
//     `MS_DST_w or MS_DST_w, Tile identifier width
//     `MS_VNID_w or MS_VNID_w, Virtual Network identifier width
//
//   The format of a message between the TR and the NI (MS_tonet) is:
//
//      DST (DST_w) | Req (MS_REQ_w) | synth_function (MS_FUNC_w) | Size (MS_MSG_size_w) | VN (MS_VNID_w) | Rate (MS_RATE_w)
//
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef __PEAK_SYNTHETIC_TRAFFIC_GENERATOR_H__
`define __PEAK_SYNTHETIC_TRAFFIC_GENERATOR_H__

// * Defines the code for synthetic function 1 random VN and destination to inject
`define SYNTH_FUNCTION              4'b0010

// * Defines the code for synthetic function 2 with defined VN and destination to inject
`define SYNTH2_FUNCTION             4'b0100

// * Defines the code for synthetic function with random VN and destination to inject
`define MS_SYNTH_DST_AND_VN_RND 	  4'b0000

// * Defines the code for synthetic function with random destination to inject
`define MS_SYNTH_DST_RND           	4'b0001

// * Defines the code for synthetic function with random virtual network to inject
`define MS_SYNTH_VN_RND           	4'b0010

// * Defines the code for synthetic function with defined VN and destination to inject
`define MS_SYNTH_DST_AND_VN_DEF 	  4'b0011

// * Defines the size of the internal MS queue
`define MESSAGE_SYSTEM_QUEUE_SIZE   16

// * Defines the size of the timestamp in the MS message
`define MS_TIMESTAMP_w 9

// * Defines the LSB position of the timestamp field in the MS message
`define MS_OUT_TIMESTAMP_LSB 53

// * Defines the MSB position of the timestamp field in the MS message
`define MS_OUT_TIMESTAMP_MSB 61


//************** MS MSG format expected by the NI (MS_tonet) ********************
// * Defines the traffic rate width
// * !!!!! modify MS_tonet accordingly
`define MS_RATE_w 7

// * Defines the destination width
// * !!!!! modify MS_tonet accordingly
`ifndef MS_DST_w
  `define MS_DST_w  9
`endif

// * Defines the Virtual network identifier width
// * !!!!! modify MS_tonet accordingly
`ifndef MS_VNID_w
  `define MS_VNID_w 2
`endif

// * Defines the function width
// * !!!!! modify MS_tonet accordingly
`define MS_FUNC_w 4

// * Defines the message size width
// * !!!!! modify MS_tonet accordingly
`define MS_MSG_SIZE_w 16

// * Defines the Request width
// * !!!!! modify MS_tonet accordingly
`define MS_REQ_w 1

// * Defines the MS width
// * !!!!! modify MS_tonet accordingly
`define MS_w (`MS_DST_w + `MS_REQ_w + `MS_FUNC_w + `MS_MSG_SIZE_w + `MS_VNID_w + `MS_RATE_w)

// * Defines the LSB position of the Rate field in the MS message
`define MS_RATE_LSB 0

// * Defines the MSB position of the Rate field in the MS message
`define MS_RATE_MSB (`MS_RATE_LSB + `MS_RATE_w - 1)

// * Defines the LSB position of the VN field in the MS message
`define MS_VNID_LSB (`MS_RATE_MSB + 1)

// * Defines the MSB position of the VN field in the MS message
`define MS_VNID_MSB (`MS_VNID_LSB + `MS_VNID_w - 1)

// * Defines the LSB position of the MSG_SIZE field in the MS message
`define MS_MSG_SIZE_LSB (`MS_VNID_MSB + 1)

// * Defines the MSB position of the MSG_SIZE field in the MS message
`define MS_MSG_SIZE_MSB (`MS_MSG_SIZE_LSB + `MS_MSG_SIZE_w - 1)

// * Defines the LSB position of the FUNCTION field in the MS message
`define MS_FUNC_LSB (`MS_MSG_SIZE_MSB + 1)

// * Defines the MSB position of the FUNCTION field in the MS message
`define MS_FUNC_MSB (`MS_FUNC_LSB + `MS_FUNC_w - 1)

// * Defines the LSB position of the REQ field in the MS message
`define MS_REQ_LSB (`MS_FUNC_MSB + 1)

// * Defines the MSB position of the DST field in the MS message
`define MS_REQ_MSB (`MS_REQ_LSB + `MS_REQ_w - 1)

// * Defines the LSB position of the DST field in the MS message
`define MS_DST_LSB (`MS_REQ_MSB + 1)

// * Defines the MSB position of the DST field in the MS message
`define MS_DST_MSB (`MS_DST_LSB + `MS_DST_w - 1)


// ****************** RANGES generation *******************************
`define MS_RATE_RANGE `MS_RATE_MSB:`MS_RATE_LSB

`define MS_VNID_RANGE `MS_VNID_MSB:`MS_VNID_LSB

`define MS_MSG_SIZE_RANGE `MS_MSG_SIZE_MSB:`MS_MSG_SIZE_LSB

`define MS_FUNC_RANGE `MS_FUNC_MSB:`MS_FUNC_LSB

`define MS_REQ_RANGE `MS_REQ_MSB:`MS_REQ_LSB

`define MS_DST_RANGE `MS_DST_MSB:`MS_DST_LSB

`define MS_DST_RANGE_DST_REG (`MS_DST_w-1):0

`endif
