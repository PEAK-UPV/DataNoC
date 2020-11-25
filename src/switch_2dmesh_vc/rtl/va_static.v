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
// File Name: va_static.v
// Module Name: VA_STATIC
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

//STATIC IMPLEMENTATION
module VA_STATIC #(

parameter FLIT_SIZE          = 64,
parameter FLIT_TYPE_SIZE     = 2,
parameter BROADCAST_SIZE     = 5,
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3,                  // Number of Virtual Networks supported
parameter VN_WEIGHT_VECTOR_w = 20
)(id,/*Port,*/
		  clk,
          rst_p,
          REQ_E,        //request to allocate an output VC signal (from rt at east)
          REQ_S,
          REQ_W,
          REQ_N,
	      REQ_L,
		  free_VC_in,		// There is one VC released from output VC ?
		  VC_released_in,  // VC released from output VC
		  VC_assigns_out,	// VC assignations, each port is using one VC {E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}
          GRANTS); 		//Grant access to output VC signal

`include "common_functions.vh"
`include "data_net_virtual_channel.vh"



    input [bits_VN-1:0] id;			//Id of this VN
    //input [2:0] Port;
    input clk;
    input rst_p;
    input [NUM_VC-1:0] REQ_E;						//Request VC grant for east port
    input [NUM_VC-1:0] REQ_S;
    input [NUM_VC-1:0] REQ_W;
    input [NUM_VC-1:0] REQ_N;
    input [NUM_VC-1:0] REQ_L;
	input  free_VC_in;
	input [bits_VN_X_VC-1:0] VC_released_in;

	output reg [long_VC_assigns_per_VN-1:0] VC_assigns_out; 			//[bits_VN_X_VC_AND_PORTS-1:0] VC_assigns [NUM_VC-1:0] --> {E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}
    output reg [NUM_VC_AND_PORTS-1 : 0] GRANTS;

    wire free_VC = ((VC_released_in < ((id*NUM_VC) + (NUM_VC))) &
    			   		 (VC_released_in >= (id*NUM_VC)) & free_VC_in);
    wire [bits_VC-1:0] VC_released = free_VC ? (VC_released_in-(id*NUM_VC)) : `V_ZERO(bits_VC);

//assign GRANTS = (|grants_not_zeros) ? grants_out : `V_ZERO(NUM_VC_AND_PORTS);
//reg [NUM_VC_AND_PORTS-1:0] grants_out;
reg [NUM_VC-1:0] STATS;										//Status of each channel free=0, bussy=1
wire [NUM_VC-1:0] grants_not_zeros;// = (|grants_in);
wire [NUM_VC-1:0] STATS_in_the_same_stat;
wire [long_VC_assigns_per_VN-1:0] VC_assigns_out_temp;
wire [NUM_VC_AND_PORTS-1:0] grants_out_temp;
wire [NUM_VC-1:0] vector_releaseds;
wire [(NUM_VC*3)-1:0]vector_grants_in_id;

genvar j;
   generate
    for (j=0; j<NUM_VC; j=j+1)begin : VC
    wire [4:0] GRANTS_IN_RR;
    wire [4:0] grants_in;									//Grants incomming from Arbiter
    wire [2:0] grants_in_id;								//Position of incomming grant
    wire stat_free;											//This channel is free
    wire is_released;
    wire grants_in_not_zeros;               				//There is one grant for this channel
    //wire STAT;
    //wire [2:0] VC_assign;
    wire [4:0] grant_out;
    //wire [NUM_VC_AND_PORTS-1:0] grants_temp;
	end
endgenerate

genvar i;
   generate
    for (i=0; i<NUM_VC; i=i+1)begin

  	 /*	ROUND_ROBIN_ARB_5_IN  #(
      .NUM_VC             ( NUM_VC                   ),
      .NUM_VN             ( NUM_VN                   )
      )round_robin_arb0(
  		.vector_in({REQ_E[i], REQ_S[i], REQ_W[i], REQ_N[i], REQ_L[i]}),
  		.clk(clk),
  		.rst_p(rst_p),
  		.GRANTS_IN(VC[i].GRANTS_IN_RR),
  		.vector_out(VC[i].grants_in),
  		.grant_id(VC[i].grants_in_id));*/

      RR_X_IN #(
      //
      .IO_SIZE(NUM_PORTS),
      .IO_w(NUM_PORTS_w),
      .OUTPUT_ID("yes"),
      .SHUFFLE("no"),
      .SUFFLE_DIM_1(1),
      .SUFFLE_DIM_2(1)

      )round_robin_PORTS_IN(
      .vector_in({REQ_E[i], REQ_S[i], REQ_W[i], REQ_N[i], REQ_L[i]}),
      .clk(clk),
      .rst_p(rst_p),
      .GRANTS_IN(VC[i].GRANTS_IN_RR),
      .vector_out(VC[i].grants_in),
      .grant_id(VC[i].grants_in_id));


    assign VC[i].stat_free = (~(STATS[i]));	//This channel is free
    assign VC[i].is_released = (free_VC & VC_released == i);                  //This channel is released in this cycle
 		assign VC[i].grants_in_not_zeros = (|VC[i].grants_in);
 		assign VC[i].GRANTS_IN_RR = ((VC[i].stat_free | VC[i].is_released) & VC[i].grants_in_not_zeros) ? VC[i].grants_in : `V_ZERO(5);	//Realimentation of grants_out to update token in RR
 		assign VC[i].grant_out = ((VC[i].stat_free | VC[i].is_released) & VC[i].grants_in_not_zeros) ? VC[i].grants_in : `V_ZERO(5);
 		/*for (j=0; j<5; j=j+1)begin
      		assign VC[i].grants_temp = (VC[i].grants_in_not_zeros) ? ((1'b1 << (VC[i].grants_in_id * NUM_VC)) |`V_ZERO(NUM_VC_AND_PORTS)) : `V_ZERO(NUM_VC_AND_PORTS);//To translate in {REQ_E[i], REQ_S[i], REQ_W[i], REQ_N[i], REQ_L[i]} format.
    	end*/

 		//Vectors
 		assign grants_not_zeros[i] = VC[i].grants_in_not_zeros;
    assign STATS_in_the_same_stat[i] = (VC[i].grants_in_not_zeros) ? ~(VC[i].stat_free | VC[i].is_released) :      //Available or not with request to use
                               			  ~(VC[i].is_released);      			  									  //Is released
    assign vector_releaseds[i] = VC[i].is_released;
    assign vector_grants_in_id[((i*3)+(3-1))-:3] = VC[i].grants_in_id;
    /*assign VC_assigns_out_temp[((i*bits_VN_X_VC_AND_PORTS)+(bits_VN_X_VC_AND_PORTS-1))-:bits_VN_X_VC_AND_PORTS] = ((VC[i].stat_free | VC[i].is_released) & VC[i].grants_in_not_zeros)  ? ((VC[i].grants_in_id*NUM_VN_X_VC) + ((id*NUM_VC)+i) ) : //Se asigna
                                                                                                                  (~VC[i].grants_in_not_zeros & VC[i].is_released) ? `V_ZERO(bits_VN_X_VC_AND_PORTS)	:											 //Se libera
                                                                                                                  (STATS_in_the_same_stat[i]) ? VC_assigns_out[((i*bits_VN_X_VC_AND_PORTS)+(bits_VN_X_VC_AND_PORTS-1))-:bits_VN_X_VC_AND_PORTS] : //Se mantiene
                                                                                                                   `V_ZERO(bits_VN_X_VC_AND_PORTS);  */
                                                                                                                                                                                                          //Se pone a cero
	    for (j=0; j<5; j=j+1)begin
	      assign grants_out_temp[(j*NUM_VC) +i] = VC[i].grant_out[j];//To translate in {REQ_E[i], REQ_S[i], REQ_W[i], REQ_N[i], REQ_L[i]} format.
	    end
    	//assign grants_out_temp = (VC[0].grants_in_not_zeros) ? VC[0].grants_temp : `V_ZERO(NUM_VC_AND_PORTS);//To translate in {REQ_E[i], REQ_S[i], REQ_W[i], REQ_N[i], REQ_L[i]} format.
	end
endgenerate

wire [NUM_VC-1:0] grant_and_assigned = (grants_not_zeros & (~STATS | vector_releaseds));
wire [NUM_VC-1:0] no_grant_and_released = (~grants_not_zeros & vector_releaseds);
wire [NUM_VC-1:0] remains_in_the_same_stat = ~(grant_and_assigned | no_grant_and_released);
wire [NUM_VC-1:0] final_stats = (remains_in_the_same_stat & STATS) | grant_and_assigned;

generate
    for (i=0; i<NUM_VC; i=i+1)begin
      assign VC_assigns_out_temp[((i*(bits_VN_X_VC_AND_PORTS+1))+(bits_VN_X_VC_AND_PORTS))-:(bits_VN_X_VC_AND_PORTS+1)] = (grant_and_assigned[i]) ? ((vector_grants_in_id[((i*3)+(3-1))-:3]*NUM_VN_X_VC) + ((id*NUM_VC)+i) ) :
                                                                                                                    (no_grant_and_released[i]) ? {(bits_VN_X_VC_AND_PORTS+1){1'b1}} : VC_assigns_out[((i*(bits_VN_X_VC_AND_PORTS+1))+(bits_VN_X_VC_AND_PORTS))-:(bits_VN_X_VC_AND_PORTS+1)]/*((prueba_vector_grants_in_id[((i*3)+(3-1))-:3]*NUM_VN_X_VC) + ((id*NUM_VC)+i) )*/;
    end
endgenerate

reg [(NUM_VC*3)-1:0] prueba_vector_grants_in_id;
reg [NUM_VC-1:0] prueba_STATS;

always @(posedge clk) begin
	if (rst_p) begin
		STATS <= `V_ZERO(NUM_VC);
    	prueba_STATS <= `V_ZERO(NUM_VC);
		  VC_assigns_out <= {long_VC_assigns_per_VN{1'b1}}; //All entries bits to one
    	prueba_vector_grants_in_id <= `V_ZERO((NUM_VC*3));
		GRANTS <= `V_ZERO(NUM_VC_AND_PORTS);
	end else /*if(~(&remains_in_the_same_stat))*/begin
		STATS <= final_stats;/*STATS_temp;*/
    	prueba_STATS <= STATS;
    	VC_assigns_out <= VC_assigns_out_temp;
    	prueba_vector_grants_in_id <= vector_grants_in_id;
		GRANTS <= grants_out_temp;
	end
end
endmodule


