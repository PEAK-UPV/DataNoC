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
// Engineer: J. Flich (jflich@disca.upv.es)
// Contact: J. Flich (jflich@disca.upv.es)
// Create Date: September 3, 2013
// File Name: output_vc.v
// Module Name: OUTPUT_VC
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

module OUTPUT_VC #(
  parameter FLIT_SIZE          = 64,
  parameter FLIT_TYPE_SIZE     = 2,
  parameter BROADCAST_SIZE     = 5,
  parameter PHIT_SIZE          = 64,
  parameter NUM_PORTS          = 5,
  parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
  parameter NUM_VN             = 3,                  // Number of Virtual Networks supported
  parameter VN_WEIGHT_VECTOR_w = 20
)(
  clk,
  rst_p,
  Pre_Flit_E,
  Pre_Flit_S,
  Pre_Flit_W,
  Pre_Flit_N,
  Pre_Flit_L,
  Pre_FlitType_E,
  Pre_FlitType_S,
  Pre_FlitType_W,
  Pre_FlitType_N,
  Pre_FlitType_L,
  Pre_BroadcastFlit_E ,
  Pre_BroadcastFlit_S ,
  Pre_BroadcastFlit_W ,
  Pre_BroadcastFlit_N ,
  Pre_BroadcastFlit_L ,
  GRANTS,           //{E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}
  vc_selected,             //Which channel is asigned to it grant_id

  free_VC,                      // There is one VC released to VA?
  VC_out,               // VC asigned to output flit, these signal will goes out of switch and informs nearby switches and VA
  GoPhit,                                // flow control to SA
  BroadcastFlitOut,
  FlitOut,
  FlitTypeOut,
  Valid,   //enable transmission signal (asserted when a flit is outgoing from the switch. In this way, the next input unit enables the flit reception logic)
  vc_to_release
);

`include "common_functions.vh"
`include "data_net_virtual_channel.vh"

localparam [6 : 0] NUM_PHITS          = (PHIT_SIZE > 7'd0 ? FLIT_SIZE / PHIT_SIZE : 7'b1);
localparam [6 : 0] LAST_PHIT          = NUM_PHITS - 7'd1;
localparam [6 : 0] BEFORE_LAST_PHIT   = (NUM_PHITS == 7'd1) ? LAST_PHIT : (NUM_PHITS - 7'd2);

input clk;
input rst_p;
input [FLIT_SIZE_VC-1:0] Pre_Flit_E;
input [FLIT_SIZE_VC-1:0] Pre_Flit_S;
input [FLIT_SIZE_VC-1:0] Pre_Flit_W;
input [FLIT_SIZE_VC-1:0] Pre_Flit_N;
input [FLIT_SIZE_VC-1:0] Pre_Flit_L;
input [FLIT_TYPE_SIZE_VC-1:0] Pre_FlitType_E;
input [FLIT_TYPE_SIZE_VC-1:0] Pre_FlitType_S;
input [FLIT_TYPE_SIZE_VC-1:0] Pre_FlitType_W;
input [FLIT_TYPE_SIZE_VC-1:0] Pre_FlitType_N;
input [FLIT_TYPE_SIZE_VC-1:0] Pre_FlitType_L;
input [NUM_VN_X_VC-1:0] Pre_BroadcastFlit_E ;
input [NUM_VN_X_VC-1:0] Pre_BroadcastFlit_S ;
input [NUM_VN_X_VC-1:0] Pre_BroadcastFlit_W ;
input [NUM_VN_X_VC-1:0] Pre_BroadcastFlit_N ;
input [NUM_VN_X_VC-1:0] Pre_BroadcastFlit_L ;
input [NUM_VN_X_VC_AND_PORTS-1 : 0] GRANTS;           //{E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}
input [bits_VN_X_VC-1:0] vc_selected;             //Which channel is asigned to it grant_id

output  free_VC;                      // There is one VC released to VA?
output reg [bits_VN_X_VC-1:0] VC_out;               // VC asigned to output flit, these signal will goes out of switch and informs nearby switches and VA
output GoPhit;                                // flow control to SA
output reg BroadcastFlitOut;
output [PHIT_SIZE-1:0] FlitOut;
output reg [FLIT_TYPE_SIZE-1:0] FlitTypeOut;
output reg Valid;   //enable transmission signal (asserted when a flit is outgoing from the switch. In this way, the next input unit enables the flit reception logic)
output [bits_VN_X_VC-1:0] vc_to_release;


wire [NUM_VN_X_VC-1:0] GRANTS_E = GRANTS[(NUM_VN_X_VC*4 + NUM_VN_X_VC-1) -: NUM_VN_X_VC];  //{E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}
wire [NUM_VN_X_VC-1:0] GRANTS_S = GRANTS[(NUM_VN_X_VC*3 + NUM_VN_X_VC-1) -: NUM_VN_X_VC];
wire [NUM_VN_X_VC-1:0] GRANTS_W = GRANTS[(NUM_VN_X_VC*2 + NUM_VN_X_VC-1) -: NUM_VN_X_VC];
wire [NUM_VN_X_VC-1:0] GRANTS_N = GRANTS[(NUM_VN_X_VC*1 + NUM_VN_X_VC-1) -: NUM_VN_X_VC];
wire [NUM_VN_X_VC-1:0] GRANTS_L = GRANTS[(NUM_VN_X_VC*0 + NUM_VN_X_VC-1) -: NUM_VN_X_VC];

wire Grant_to_E = (|GRANTS_E);
wire Grant_to_S = (|GRANTS_S);
wire Grant_to_W = (|GRANTS_W);
wire Grant_to_N = (|GRANTS_N);
wire Grant_to_L = (|GRANTS_L);

wire [FLIT_SIZE-1:0] Flit_E;
wire [FLIT_SIZE-1:0] Flit_S;
wire [FLIT_SIZE-1:0] Flit_W;
wire [FLIT_SIZE-1:0] Flit_N;
wire [FLIT_SIZE-1:0] Flit_L;
wire [FLIT_TYPE_SIZE-1:0] FlitType_E;
wire [FLIT_TYPE_SIZE-1:0] FlitType_S;
wire [FLIT_TYPE_SIZE-1:0] FlitType_W;
wire [FLIT_TYPE_SIZE-1:0] FlitType_N;
wire [FLIT_TYPE_SIZE-1:0] FlitType_L;
wire BroadcastFlit_E;
wire BroadcastFlit_S;
wire BroadcastFlit_W;
wire BroadcastFlit_N;
wire BroadcastFlit_L;


  generate
    genvar i;
    for (i = 0; i < NUM_VN_X_VC; i = i + 1) begin
      assign Flit_E = (|GRANTS_E) ? Pre_Flit_E[(`WIDTH(GRANTS_E)*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] : `V_ZERO(FLIT_SIZE);
      assign Flit_S = (|GRANTS_S) ? Pre_Flit_S[(`WIDTH(GRANTS_S)*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] : `V_ZERO(FLIT_SIZE);
      assign Flit_W = (|GRANTS_W) ? Pre_Flit_W[(`WIDTH(GRANTS_W)*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] : `V_ZERO(FLIT_SIZE);
      assign Flit_N = (|GRANTS_N) ? Pre_Flit_N[(`WIDTH(GRANTS_N)*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] : `V_ZERO(FLIT_SIZE);
      assign Flit_L = (|GRANTS_L) ? Pre_Flit_L[(`WIDTH(GRANTS_L)*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] : `V_ZERO(FLIT_SIZE);
      assign FlitType_E = (|GRANTS_E) ? Pre_FlitType_E[(`WIDTH(GRANTS_E)*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] : `V_ZERO(FLIT_TYPE_SIZE);
      assign FlitType_S = (|GRANTS_S) ? Pre_FlitType_S[(`WIDTH(GRANTS_S)*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] : `V_ZERO(FLIT_TYPE_SIZE);
      assign FlitType_W = (|GRANTS_W) ? Pre_FlitType_W[(`WIDTH(GRANTS_W)*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] : `V_ZERO(FLIT_TYPE_SIZE);
      assign FlitType_N = (|GRANTS_N) ? Pre_FlitType_N[(`WIDTH(GRANTS_N)*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] : `V_ZERO(FLIT_TYPE_SIZE);
      assign FlitType_L = (|GRANTS_L) ? Pre_FlitType_L[(`WIDTH(GRANTS_L)*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] : `V_ZERO(FLIT_TYPE_SIZE);
      assign BroadcastFlit_E = (|GRANTS_E) ? Pre_BroadcastFlit_E[`WIDTH(GRANTS_E)] : 1'b0;
      assign BroadcastFlit_S = (|GRANTS_S) ? Pre_BroadcastFlit_S[`WIDTH(GRANTS_S)] : 1'b0;
      assign BroadcastFlit_W = (|GRANTS_W) ? Pre_BroadcastFlit_W[`WIDTH(GRANTS_W)] : 1'b0;
      assign BroadcastFlit_N = (|GRANTS_N) ? Pre_BroadcastFlit_N[`WIDTH(GRANTS_N)] : 1'b0;
      assign BroadcastFlit_L = (|GRANTS_L) ? Pre_BroadcastFlit_L[`WIDTH(GRANTS_L)] : 1'b0;
    end
    endgenerate

    assign free_VC = Grant_to_N?(FlitType_N == `tail | FlitType_N == `header_tail):
                     Grant_to_E?(FlitType_E == `tail | FlitType_E == `header_tail):
                     Grant_to_W?(FlitType_W == `tail | FlitType_W == `header_tail):
                     Grant_to_S?(FlitType_S == `tail | FlitType_S == `header_tail):
                     Grant_to_L?(FlitType_L == `tail | FlitType_L == `header_tail):
                     1'b0;

    assign vc_to_release =  vc_selected;


  reg   [FLIT_SIZE-1 : 0] flit;
  reg   [6 : 0]           phit_number;

  assign FlitOut = flit[phit_number * PHIT_SIZE +: PHIT_SIZE];
  //assign GoPhit  = (phit_number >= LAST_PHIT);

  if (NUM_PHITS > 1) begin
    assign GoPhit  = (phit_number >= LAST_PHIT) & ~(Grant_to_N | Grant_to_E | Grant_to_W | Grant_to_S | Grant_to_L);
  end else begin
    assign GoPhit = 1'b1;
  end

  always @ (posedge clk)
    if (rst_p) begin
     flit             <= `V_ZERO(FLIT_SIZE);
     phit_number      <= LAST_PHIT;
     BroadcastFlitOut <= 1'b0;
     FlitTypeOut      <= 2'b0;
     Valid            <= 1'b0;
     VC_out <= `V_ZERO(bits_VN_X_VC);

    end else begin

        if (Grant_to_N) begin
            flit <= Flit_N;
            BroadcastFlitOut <= BroadcastFlit_N;
            FlitTypeOut <= FlitType_N;
            Valid <= 1'b1;
            phit_number <= 7'b0;
            VC_out <= vc_selected;
        end else if (Grant_to_E) begin
            flit <= Flit_E;
            BroadcastFlitOut <= BroadcastFlit_E;
            FlitTypeOut <= FlitType_E;
            Valid <= 1'b1;
            phit_number <= 7'b0;
            VC_out <= vc_selected;
        end else if (Grant_to_W) begin
            flit <= Flit_W;
            BroadcastFlitOut <= BroadcastFlit_W;
            FlitTypeOut <= FlitType_W;
            Valid <= 1'b1;
            phit_number <= 7'b0;
            VC_out <= vc_selected;
        end else if (Grant_to_S) begin
            flit <= Flit_S;
            BroadcastFlitOut <= BroadcastFlit_S;
            FlitTypeOut <= FlitType_S;
            Valid <= 1'b1;
            phit_number <= 7'b0;
            VC_out <= vc_selected;
        end else if (Grant_to_L) begin
            flit <= Flit_L;
            BroadcastFlitOut <= BroadcastFlit_L;
            FlitTypeOut <= FlitType_L;
            Valid <= 1'b1;
            phit_number <= 7'b0;
            VC_out <= vc_selected;
        end else begin
            if (phit_number < LAST_PHIT) begin
              Valid       <= 1'b1;
              phit_number <= phit_number + 7'b1;
//              VC_out <= vc_selected;
            end else begin
//            VC_out <= vc_selected;
              Valid <= 1'b0;
            end
        end
  end
endmodule
