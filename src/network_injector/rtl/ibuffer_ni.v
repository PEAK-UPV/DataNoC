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
// Contact: J.Flich (jflich@disca.upv.es) 
// Create Date: September 3, 2013
// File Name: ibuffer_ni.v
// Module Name: IBUFFER_NI
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
//////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`include "macro_functions.h"

module IBUFFER_NI #(
parameter ID                 = 0,
parameter FLIT_SIZE          = 64,
parameter FLIT_TYPE_SIZE     = 2,
parameter PHIT_SIZE          = 64,
parameter BROADCAST_SIZE     = 5,
parameter QUEUE_SIZE         = 8,
parameter SG_UPPER_THOLD     = 5,
parameter SG_LOWER_THOLD     = 4,
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3                  // Number of Virtual Networks supported

)(
  input clk,
  input rst_p,
  input [PHIT_SIZE-1:0] Flit,                //Flit to be stored
  input [FLIT_TYPE_SIZE-1:0] FlitType,       //Flit type, that's because of it is not coded in the flit structure
  input BroadcastFlit,                       //is flit broadcast?
  input Valid,                               //enable reception. ONE when there is a valid flit in the bus 
  input Avail,                                //routing engine ready for routing                                    
  
  output [FLIT_SIZE-1:0] FlitOut,            //flit outgoing the buffer
  output [FLIT_TYPE_SIZE-1:0] FlitTypeOut,   //flit type
  output BroadcastFlitOut,                   //is outgoing flit broadcast? 
  output Go,                                 //S&G protocol signal  
  output Req_RT                              //routing request
);                 


  localparam [6 : 0] NUM_PHITS   = (PHIT_SIZE > 7'b0 ? FLIT_SIZE / PHIT_SIZE : 7'b1);
  localparam [5 : 0] LAST_PHIT   = NUM_PHITS - 7'b1;
  localparam         QUEUE_width = `WIDTH(QUEUE_SIZE);

  reg   [5 : 0]      phit_number;

	//Internal registers for the queue
    reg [QUEUE_width:0] queued_flits;           //counter for the current number of queued flits 
    reg [QUEUE_width-1:0] read_ptr, write_ptr;   
    reg [FLIT_SIZE-1:0] queue [QUEUE_SIZE-1:0]; 
    reg [FLIT_TYPE_SIZE-1:0] queued_flit_type_signals [QUEUE_SIZE-1:0]; 
    reg queued_bcast_signals [QUEUE_SIZE-1:0];
    reg go_mode; 
      
      assign FlitOut          = /*~(queued_flits==0) ?*/ queue[read_ptr] /*: `V_ZERO(FLIT_SIZE)*/;                       //(Valid & (queued_flits == 0)) ? Flit          : queue[read_ptr];
      assign FlitTypeOut      = /*~(queued_flits==0) ?*/ queued_flit_type_signals[read_ptr] /*: `V_ZERO(FLIT_TYPE_SIZE)*/;    //(Valid & (queued_flits == 0)) ? FlitType      : queued_flit_type_signals[read_ptr];
      assign BroadcastFlitOut = /*~(queued_flits==0) ?*/ queued_bcast_signals[read_ptr] /*: 1'b0*/;        //(Valid & (queued_flits == 0)) ? BroadcastFlit : queued_bcast_signals[read_ptr];
      //a request to the routing engine is done when the RT is ready for accepting requests and there is at least a flit in the buffer (queued or not)
      assign Req_RT           = Avail & (queued_flits != 0);                            //(Valid & (queued_flits==0)) | ((queued_flits != 0));
   
    assign Go = go_mode;
    
    wire received_flit_s  = (phit_number == LAST_PHIT) & Valid;    
	
always @ (posedge clk)
if (rst_p) begin
	queued_flits <= `V_ZERO(QUEUE_width+1);
	read_ptr     <= `V_ZERO(QUEUE_width);
	write_ptr    <= `V_ZERO(QUEUE_width);
	go_mode      <= 1'b1;
    phit_number  <= 6'b0;  	
end else begin
    
	if (Req_RT) begin
       read_ptr  <= read_ptr + `V_ONE(QUEUE_width);
        
    	if (~received_flit_s) begin
          // routing request and not new flit arrival, let's decrement queued flits 
          queued_flits  <= queued_flits - `V_ONE(QUEUE_width);          
        end 
	end 

 	// Let's see if we receive a new flit
	if (Valid) begin
        queue[write_ptr][phit_number * PHIT_SIZE +: PHIT_SIZE] <= Flit;
        
  	    if (received_flit_s) begin
          phit_number <= 6'b0;
          if (~Req_RT) begin
            //a new flit arrival and there is not next enabled, let's increment the number of queued flits
            queued_flits <= queued_flits + `V_ONE(QUEUE_width+1);
          end                 
          queued_bcast_signals[write_ptr]     <= BroadcastFlit;
          queued_flit_type_signals[write_ptr] <= FlitType;
          write_ptr                           <= write_ptr  + `V_ONE(QUEUE_width);                      
        end else begin
          // no flit received yet
          phit_number <= phit_number + 6'b1;
        end // if received_flit_s
	end  // if valid
	
	if (go_mode) begin
	  if (queued_flits >= SG_UPPER_THOLD) begin
	    go_mode <= 1'b0;
	  end else begin
	   go_mode <= 1'b1;
	  end
	end else begin
	  if (queued_flits < SG_LOWER_THOLD) begin
	   go_mode <= 1'b1;
	  end else begin
	   go_mode <= 1'b0;
	  end 
	end	
	
end
endmodule
