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
// File Name: va_ni_dynamic.v
// Module Name:VA_NI_DYNAMIC
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
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`include "macro_functions.h"
`include "net_common.h"
`include "data_net_virtual_channel.h"

//DYNAMIC IMPLEMENTATION
module VA_NI_DYNAMIC #(
parameter ID                 = 0,
parameter FLIT_SIZE          = 64,
parameter FLIT_TYPE_SIZE     = 2,
parameter PHIT_SIZE          = 64,
parameter BROADCAST_SIZE     = 5,
parameter NUM_PORTS          = 5,
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3,                  // Number of Virtual Networks supported
parameter VN_WEIGHT_VECTOR_w = 1
)(id,
  clk,
  rst_p,
  REQ,        //request to allocate an output VC signal (from rt)
  free_VC_in,		// There is one VC released from output VC ?
  VC_released_in,  // VC released from output VC
  VC_assigns_out,	// VC assignations, which input REQ (expresed in binary) is located in each VC
  GRANTS			//Grant access to output VC signal
);

`include "common_functions.vh"
`include "data_net_virtual_channel.vh"

input [bits_VN-1:0] id;			//Id of this VN
input clk;
input rst_p;
input [NUM_VC-1:0] REQ;						//Request VC grant
input  free_VC_in;
input [bits_VN_X_VC-1:0] VC_released_in;

output reg [long_VC_assigns_NI_per_VN-1:0] VC_assigns_out;
output [NUM_VC-1 : 0] GRANTS;

wire free_VC = ((VC_released_in < ((id*NUM_VC) + (NUM_VC))) &
			   		 (VC_released_in >= (id*NUM_VC)) & free_VC_in);
wire [bits_VC-1:0] VC_released = free_VC ? (VC_released_in-(id*NUM_VC)) : `V_ZERO(bits_VC);

wire [NUM_VC-1:0] grants_in;						//Grants incomming from Arbiter
wire grants_in_not_zeros;
wire [bits_VC-1:0] grants_in_id;					//Position of incomming grant
wire stat_free;
wire [NUM_VC-1:0] GRANTS_IN_RR = (grants_in_not_zeros & stat_free) ? grants_in : `V_ZERO(NUM_VC);

/*ROUND_ROBIN_ARB_NUM_VC #(
  .NUM_VC             ( NUM_VC                   ),
  .NUM_VN             ( NUM_VN                   )
)round_robin_NUM_VC_arb0(
.vector_in(REQ),
.clk(clk),
.rst_p(rst_p),
.GRANTS_IN(GRANTS_IN_RR),
.vector_out(grants_in),
.grant_id(grants_in_id));*/


RR_X_IN #(

    .IO_SIZE(NUM_VC),
    .IO_w(bits_VC),
    .OUTPUT_ID("yes"),
    .SHUFFLE("no"),
    .SUFFLE_DIM_1(1),
    .SUFFLE_DIM_2(1)

    )round_robin_NUM_VC(
    .vector_in(REQ),
    .clk(clk),
    .rst_p(rst_p),
    .GRANTS_IN(GRANTS_IN_RR),
    .vector_out(grants_in),
    .grant_id(grants_in_id));


//----------------------------------------------------

reg [NUM_VC-1:0] grants_out;
reg [NUM_VC-1:0] STATS;
assign grants_in_not_zeros = (|grants_in);

wire [bits_VC-1:0] pointer;// = `WIDTH(STATS_selected);		//It will get the corresponding VC to this grant
reg [bits_VC-1:0] last_pointer;
assign GRANTS = /*grants_in_not_zeros ? */grants_out/* : `V_ZERO(NUM_VC)*/;
wire [NUM_VC-1:0] STATS_free;
wire [NUM_VC-1:0] grant_in_id_already_assigned;
wire [NUM_VC-1:0] grant_released;

genvar j;
generate
    for( j=0; j<NUM_VC;j = j+1) begin
	    assign STATS_free[j] = (~(STATS[j])); 	                                                    //It will get a vector with free stats = 1
	    																							//There are any with the same id?
        assign grant_in_id_already_assigned[j] = ((VC_assigns_out[(j*(bits_VN_X_VC+1)+(bits_VN_X_VC))-:(bits_VN_X_VC+1)] == (grants_in_id+(id*NUM_VC))) & (STATS[j]) & grants_in_not_zeros & ~grant_released[j]);
        assign grant_released[j] = (VC_released==j & free_VC);									   //Is released in this cycle
    end
 endgenerate

wire [bits_VC-1:0] vector_id_already_assigned;
encoder #(
     .lenght_in(NUM_VC),
     .lenght_out( bits_VC)
     ) encoder_64 (
        .enable(|(64'd0+grant_in_id_already_assigned)),
        .vector_in(grant_in_id_already_assigned),
        .vector_id(vector_id_already_assigned)
    );

wire [NUM_VC-1:0] STATS_available = //(|grant_in_id_already_assigned) ? (STATS_free & grant_in_id_already_assigned):			//This grant is already assigned
												  			free_VC ? (STATS_free | grant_released) :	//This grant is released in this cycle and it channel is ready to use
														 			   STATS_free;						//There is stats free and no assigned to the same id
wire [NUM_VC-1:0] STATS_selected;
assign stat_free = (free_VC | (|STATS_free) );	//There is one channel released in this cycle or there is one with free status.
wire [NUM_VC-1:0] GRANTS_IN_RR_STATS = (grants_in_not_zeros & stat_free & (|STATS_selected)) ? STATS_selected : `V_ZERO(NUM_VC);
//We use a FPA to fill up one channel if there are someone free.----------------------------------------------------------------------
/*for( j=0; j<NUM_VC;j = j+1) begin
	assign STATS_selected[j] = (j==0) ? STATS_available[0] : ((STATS_available[j]) & (~|STATS_available[(j-1) -: j]));
end*/

/*ROUND_ROBIN_ARB_NUM_VC #(
  .NUM_VC             ( NUM_VC                   ),
  .NUM_VN             ( NUM_VN                   )
)round_robin_NUM_VC_arb1(
.vector_in(STATS_available),
.clk(clk),
.rst_p(rst_p),
.GRANTS_IN(GRANTS_IN_RR_STATS),
.vector_out(STATS_selected),
.grant_id(pointer));*/

RR_X_IN #(
//
.IO_SIZE(NUM_VC),
.IO_w(bits_VC),
.OUTPUT_ID("yes"),
.SHUFFLE("no"),
.SUFFLE_DIM_1(1),
.SUFFLE_DIM_2(1)

)round_robin_NUM_VC_arb1(
.vector_in(STATS_available),
.clk(clk),
.rst_p(rst_p),
.GRANTS_IN(GRANTS_IN_RR_STATS),
.vector_out(STATS_selected),
.grant_id(pointer));
//------------------------------------------------------------------------------------------------------------------------------------

always @(posedge clk) begin
	if (rst_p) begin
		STATS <= `V_ZERO(NUM_VC);
		VC_assigns_out <= {long_VC_assigns_NI_per_VN{1'b1}}; //All entries bits to one
		grants_out <= `V_ZERO(NUM_VC);
	end
	else begin
		if(grants_in_not_zeros & stat_free & (|STATS_selected)) begin
  			STATS <= (STATS_selected & STATS_available) | (~STATS_available);
			VC_assigns_out[((pointer*(bits_VN_X_VC+1)) + (bits_VN_X_VC))-:(bits_VN_X_VC+1)] <= ((id*NUM_VC) + grants_in_id);			//Assign these channel with one grant
			grants_out <= grants_in;
			if(free_VC & ~(pointer==VC_released))begin
            	VC_assigns_out[((VC_released*(bits_VN_X_VC+1)) + (bits_VN_X_VC))-:(bits_VN_X_VC+1)] <= {(bits_VN_X_VC+1){1'b1}}; //Invalidate this entry
        	end
        	if(|grant_in_id_already_assigned & ~((grants_in_id+(id*NUM_VC)) == 0) )begin
            	VC_assigns_out[((vector_id_already_assigned*(bits_VN_X_VC+1)) + (bits_VN_X_VC))-:(bits_VN_X_VC+1)] <= {(bits_VN_X_VC+1){1'b1}}; //Invalidate this entry
        	end
		end else if(free_VC)begin
			STATS[VC_released] <= 1'b0;						//One channel released right now
			VC_assigns_out[((VC_released*(bits_VN_X_VC+1)) + (bits_VN_X_VC))-:(bits_VN_X_VC+1)] <= {(bits_VN_X_VC+1){1'b1}}; //Invalidate this entry
			grants_out <= `V_ZERO(NUM_VC);			//Grants in is zero or there is not vc free
		end else begin
			grants_out <= `V_ZERO(NUM_VC);			//Grants in is zero or there is not vc free
		end
	end//else
end
endmodule
