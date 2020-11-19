`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// (c) Copyright 2012 - 2017  Parallel Architectures Group (GAP)
// Department of Computing Engineering (DISCA)
// Universitat Politecnica de Valencia (UPV)
// Valencia, Spain
// All rights reserved.
//
// All code contained herein is, and remains the property of
// Parallel Architectures Group. The intellectual and technical concepts
// contained herein are proprietary to Parallel Architectures Group and
// are protected by trade secret or copyright law.
// Dissemination of this code or reproduction of this material is
// strictly forbidden unless prior written permission is obtained
// from Parallel Architectures Group.
//
// THIS SOFTWARE IS MADE AVAILABLE "AS IS" AND IT IS NOT INTENDED FOR USE
// IN WHICH THE FAILURE OF THE SOFTWARE COULD LEAD TO DEATH, PERSONAL INJURY,
// OR SEVERE PHYSICAL OR ENVIRONMENTAL DAMAGE.
//
// contact: jflich@disca.upv.es
//-----------------------------------------------------------------------------
//
// Company:  GAP (UPV)
// Engineer: J. Flich (jflich@disca.upv.es)
//
// Create Date: 07/17/2013
// Design Name:
// Module Name:
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

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
