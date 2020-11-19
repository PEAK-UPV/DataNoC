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
// Create Date: 09/03/2013
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

module IBUFFER_VC #(
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
