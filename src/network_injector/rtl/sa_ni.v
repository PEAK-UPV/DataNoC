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
// Create Date: September 3, 2013
// File Name: sa_ni.v
// Module Name: SA_NI
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
`include "data_net_virtual_channel.h"

module SA_NI #(
  parameter ID                        = 0,
  parameter FLIT_SIZE                 = 64,
  parameter FLIT_TYPE_SIZE            = 2,
  parameter BROADCAST_SIZE            = 5,
  parameter PHIT_SIZE                 = 64,
  parameter NUM_PORTS                 = 5,
  parameter NUM_VC                    = 1,     // Number of Virtual Channels supported for each Virtual Network
  parameter NUM_VN                    = 3,     // Number of Virtual Networks supported
  parameter VN_WEIGHT_VECTOR_w        = 20,
  parameter ENABLE_VN_WEIGHTS_SUPPORT = "no"
)(
  clk,
  rst_p,
  go,           			//go flow control signal (from the downstream switch)
  WeightsVector_in,  // New weights vector to guarante various bandwidths to different virtual networks.
  REQ,        				//request to allocate an output port signal (from rt)
  VC_assigns_in,			// VC assignations, which input REQ (expresed in binary) is located in each VC
  GRANTS, 				//Grant access to output port signal all in one bus(to rt and output)
  vc_selected_out			//Which channel is asigned to it grant_id
);

`include "common_functions.vh"
`include "data_net_virtual_channel.vh"

input                                          clk;
 input                                         rst_p;
 input [NUM_VN_X_VC-1:0]                       go;               //go flow control signal (from the downstream switch)
 input  [VN_WEIGHT_VECTOR_w-1 : 0]             WeightsVector_in;  // New weights vector to guarante various bandwidths to different virtual networks.
 input  [NUM_VN_X_VC-1 : 0]                    REQ;               //request to allocate an output port signal (from rt)
 input [long_VC_assigns_NI-1:0]                VC_assigns_in;     // VC assignations, which input REQ (expresed in binary) is located in each VC
 output reg [NUM_VN_X_VC-1 : 0]                GRANTS;        //Grant access to output port signal all in one bus(to rt and output)
 output reg [bits_VN_X_VC-1:0]                 vc_selected_out;      //Which channel is asigned to it grant_id





  //To get the requests signals that are available to go out, frist we need to be sure that it sg signal is enabled.
  //The go signal that will be checked must be corresponding to the channel assigned by VA for this REQ id in VC_assigns vector.
  wire [NUM_VN_X_VC-1:0] vector_in;
  wire [(bits_VN_X_VC*NUM_VN_X_VC)-1:0] vector_this_vc_selected;
  genvar i,j;
  generate
    for(i=0; i<NUM_VN_X_VC;i = i+1)begin  : ME
      wire [bits_VN_X_VC:0] this_REQ_id;
      wire [NUM_VN_X_VC-1:0] this_channel;
      wire [bits_VN_X_VC-1:0] this_vc_selected;
    end
  endgenerate

  generate
    for (i=0; i<NUM_VN_X_VC;i = i+1)begin
      // Get REQ_id
      assign ME[i].this_REQ_id = (REQ[i])?i:{(bits_VN_X_VC+1){1'b1}};
      //Get matching REQ_id into vector VC_assigns
      for(j=0; j<NUM_VN_X_VC;j = j+1)begin 																//|
        assign ME[i].this_channel[j] = ((VC_assigns_in[(j*(bits_VN_X_VC+1)+(bits_VN_X_VC))-:(bits_VN_X_VC+1)]==ME[i].this_REQ_id) & REQ[i]);//|
      end
      encoder #(//Get this_vc_selected
        .lenght_in(NUM_VN_X_VC),
        .lenght_out(bits_VN_X_VC)
      ) encoder_64 (
        .enable(|(64'd0+ME[i].this_channel)),
        .vector_in(ME[i].this_channel),
        .vector_id(ME[i].this_vc_selected)
      );
      assign vector_this_vc_selected[(i * bits_VN_X_VC) + (bits_VN_X_VC - 1)-:bits_VN_X_VC] = ME[i].this_vc_selected;
      assign vector_in[i] = (REQ[i] & go[ME[i].this_vc_selected]);
    end
  endgenerate

  //----------------------------------------------------------------------------------------------------------------------------------------------------------------
  wire [NUM_VN_X_VC-1:0] GRANTS_IN_RR;

    wire [NUM_VN_X_VC-1:0] grants_in;           //Grants incomming from Arbiter
  wire [bits_VN_X_VC-1:0] grants_in_id;         //Position of incomming grant
  wire [bits_VN_X_VC-1:0] vc_selected;

  wire [long_WEIGTHS-1:0] WEIGTHS;
  reg [3:0] pointer_weigths;
  wire [bits_VN-1:0] WEIGTH;
  // wire [NUM_VN_X_VC-1:0] grants_in_RR_prio;
  // wire [bits_VN_X_VC-1:0] grants_in_id_RR_prio;
  // generate
  //   if (ENABLE_VN_WEIGHTS_SUPPORT == "yes") begin



  //     assign GRANTS_IN_RR = (|grants_in_RR_prio) ? grants_in_RR_prio : `V_ZERO(NUM_VN_X_VC);
  //     assign vc_selected = (|grants_in_RR_prio) ? vector_this_vc_selected[(grants_in_id_RR_prio * bits_VN_X_VC) + (bits_VN_X_VC - 1)-:bits_VN_X_VC] : `V_ZERO(bits_VN_X_VC);
  //   end else begin
  //     assign GRANTS_IN_RR = (|grants_in) ? grants_in : `V_ZERO(NUM_VN_X_VC);
  //     assign vc_selected = (|grants_in) ? vector_this_vc_selected[(grants_in_id * bits_VN_X_VC) + (bits_VN_X_VC - 1)-:bits_VN_X_VC] : `V_ZERO(bits_VN_X_VC);
  //   end
  // endgenerate





  generate
    if (ENABLE_VN_WEIGHTS_SUPPORT == "yes") begin
      // This vector will give priotities for some virtual channels in the round robin arbiter. Its token will be updated with one of the weigths each time gives any grant
      // It vector can be udated via vn_weights command
      assign WEIGTHS = WeightsVector_in;
      assign WEIGTH = WEIGTHS[(pointer_weigths * bits_VN) + (bits_VN - 1)-:bits_VN];

      ROUND_ROBIN_ARB_VN_P #(
        .NUM_VC             ( NUM_VC                   ),
        .NUM_VN             ( NUM_VN                   )
      ) round_robin_arb_prio (
        .vector_in(vector_in),
        .clk(clk),
        .rst_p(rst_p),
        .GRANTS_IN(GRANTS_IN_RR),
        .WEIGTH(WEIGTH),
        .vector_out(grants_in),
        .grant_id(grants_in_id)
      );



    end else begin
      RR_X_IN #(
        .IO_SIZE(NUM_VN_X_VC),
        .IO_w(bits_VN_X_VC),
        .OUTPUT_ID("yes"),
        .SHUFFLE("yes"),
        .SUFFLE_DIM_1(NUM_VN),
        .SUFFLE_DIM_2(NUM_VC)
      ) round_robin_VN (
        .vector_in(vector_in),
        .clk(clk),
        .rst_p(rst_p),
        .GRANTS_IN(GRANTS_IN_RR),
        .vector_out(grants_in),
        .grant_id(grants_in_id));
     end
  endgenerate

  assign GRANTS_IN_RR = (|grants_in) ? grants_in : `V_ZERO(NUM_VN_X_VC);
  assign vc_selected = (|grants_in) ? vector_this_vc_selected[(grants_in_id * bits_VN_X_VC) + (bits_VN_X_VC - 1)-:bits_VN_X_VC] : `V_ZERO(bits_VN_X_VC);


  //----------------------------------------------------------------------------------------------------|
  always @(posedge clk) begin
    if (rst_p) begin
      GRANTS <= `V_ZERO(NUM_VN_X_VC);
      vc_selected_out <= `V_ZERO(bits_VN_X_VC);
      if (ENABLE_VN_WEIGHTS_SUPPORT == "yes") begin
          pointer_weigths <= `V_ZERO(4);
        end
    end else begin
        if ((|grants_in)) begin
          GRANTS <= grants_in; //MAL
          vc_selected_out <= vc_selected;
	        if (ENABLE_VN_WEIGHTS_SUPPORT == "yes") begin
            pointer_weigths <= (pointer_weigths == 4'd9) ? 4'd0 : pointer_weigths + 4'd1;
          end
        end else begin
          GRANTS <= `V_ZERO(NUM_VN_X_VC);
          vc_selected_out <= `V_ZERO(bits_VN_X_VC);
        end//grants_in
    end
  end

endmodule
