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
// Engineer: J.Flich (jflich@disca.upv.es)
// Contact: J. Flich (jflich@disca.upv.es)
// Create Date: July 17, 2013
// File Name: output_ni.v
// Module Name: OUTPUT_NI
// Project Name: DataNoC
// Target Devices:
// Description:
//
//
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`include "macro_functions.h"
`include "net_common.h"
`include "net_2dmesh.h"
`include "data_net_virtual_channel.h"

module OUTPUT_NI #(
parameter ID                 = 0,
parameter FLIT_SIZE          = 64,
parameter FLIT_TYPE_SIZE     = 2,
parameter PHIT_SIZE          = 64,
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3,                  // Number of Virtual Networks supported
parameter BROADCAST_SIZE     = 5,
parameter VN_WEIGHT_VECTOR_w = 1
)(
  clk,
  rst_p,
  Pre_Flit,
  Pre_FlitType,
  Pre_BroadcastFlit,
  GRANTS,
  vc_selected,							//Which channel is asigned to it grant_id

  free_VC,											// There is one VC released to VA?
  VC_out, 							// VC asigned to output flit, these signal will goes out of switch and informs nearby switches and VA
  FlitOut,
  FlitTypeOut,
  BroadcastFlitOut,
  Valid,   //enable transmission signal (asserted when a flit is outgoing from the switch. In this way, the next input unit enables the flit reception logic)
  vc_to_release
);

`include "common_functions.vh"
`include "data_net_virtual_channel.vh"

input clk;
input rst_p;
input [FLIT_SIZE_VN-1:0] Pre_Flit;
input [FLIT_TYPE_SIZE_VN-1:0] Pre_FlitType;
input [BROADCAST_FLIT_SIZE_VN-1:0] Pre_BroadcastFlit;
input [NUM_VN_X_VC-1 : 0] GRANTS;
input [bits_VN_X_VC-1:0] vc_selected;             //Which channel is asigned to it grant_id

output  free_VC;                      // There is one VC released to VA?
output reg [bits_VN_X_VC-1:0] VC_out;               // VC asigned to output flit, these signal will goes out of switch and informs nearby switches and VA
output reg [FLIT_SIZE-1:0] FlitOut;
output reg [FLIT_TYPE_SIZE-1:0] FlitTypeOut;
output reg [BROADCAST_SIZE-1:0] BroadcastFlitOut;
output reg Valid;   //enable transmission signal (asserted when a flit is outgoing from the switch. In this way, the next input unit enables the flit reception logic)
output [bits_VN_X_VC-1:0] vc_to_release;


wire GRANTS_not_zero = (|GRANTS);

wire [bits_VC-1:0] channel_into_current_VN = `WIDTH(GRANTS) % NUM_VC;
wire [bits_VN-1:0] current_VN = (`WIDTH(GRANTS)-channel_into_current_VN) / NUM_VC;

wire [FLIT_SIZE-1:0] Flit;
wire [FLIT_TYPE_SIZE-1:0] FlitType;
wire [BROADCAST_SIZE-1:0] BroadcastFlit;

		assign Flit = GRANTS_not_zero ? Pre_Flit[(current_VN*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] : `V_ZERO(FLIT_SIZE);
		assign FlitType = GRANTS_not_zero ? Pre_FlitType[(current_VN*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] : `V_ZERO(FLIT_TYPE_SIZE);
    assign BroadcastFlit = GRANTS_not_zero ? Pre_BroadcastFlit[(current_VN*BROADCAST_SIZE + (BROADCAST_SIZE-1))-:BROADCAST_SIZE] : `V_ZERO(BROADCAST_SIZE);

    assign free_VC = (FlitType == `tail | FlitType == `header_tail) & GRANTS_not_zero;
    assign vc_to_release =  vc_selected;

  always @ (posedge clk)
    if (rst_p) begin
     FlitOut          <= `V_ZERO(FLIT_SIZE);
     BroadcastFlitOut <= `V_ZERO(BROADCAST_SIZE);
     FlitTypeOut      <= `V_ZERO(FLIT_TYPE_SIZE);
     Valid            <= 1'b0;
     VC_out <= `V_ZERO(bits_VN_X_VC);

    end else begin

        if (GRANTS_not_zero) begin
            FlitOut <= Flit;
            BroadcastFlitOut <= BroadcastFlit;
            FlitTypeOut <= FlitType;
            Valid <= 1'b1;
            VC_out <= vc_selected;
        end else begin
            FlitOut          <= `V_ZERO(FLIT_SIZE);
            BroadcastFlitOut <= `V_ZERO(BROADCAST_SIZE);
            FlitTypeOut      <= `V_ZERO(FLIT_TYPE_SIZE);
            VC_out <= `V_ZERO(bits_VN_X_VC);
            Valid <= 1'b0;
        end
  end
endmodule
