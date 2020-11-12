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
// Create Date: 09/03/2014
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
`include "network/net_common.h"


module SERIALIZER_NI #(
  parameter FLIT_SIZE          = 64,
  parameter FLIT_TYPE_SIZE     = 2,
  parameter INPUT_WIDTH        = 0,
  localparam NUM_MSG	       = INPUT_WIDTH/FLIT_SIZE,	//Must be an integer number
  localparam no_padding_zone   = (INPUT_WIDTH - (NUM_MSG*FLIT_SIZE)),
  localparam padding           = FLIT_SIZE - no_padding_zone,
  localparam padding_needed    = (padding != FLIT_SIZE),
  localparam QUEUE_WIDTH       = (~padding_needed) ? INPUT_WIDTH/FLIT_SIZE : (INPUT_WIDTH/FLIT_SIZE)+1,
  localparam bits_QUEUE_WIDTH  = Log2_w(QUEUE_WIDTH)     //Number of bits needed to code QUEUE_WIDTH number
)(
  input                           clk,
  input                           rst_p,
  input                           req_in,
  input                           avail_in,
  input [INPUT_WIDTH-1:0]         data_in,
  input [3:0]                     num_flits,
  input                           BroadcastL2_VN0_in,
  output reg                      BroadcastL2_VN0_out,
  output reg                      req_out,
  output                          avail_out,     
  output  /*reg*/ [FLIT_SIZE-1:0] data_out,
  output  [FLIT_TYPE_SIZE-1:0]    data_type_out
);

`include "common_functions.vh"

  reg [bits_QUEUE_WIDTH-1:0] read_ptr;
  reg [INPUT_WIDTH-1:0] queue;
  reg queue_with_msg;
  reg [3:0] buff_num_flits;
  reg header;
  wire is_header;
  wire is_tail;
    
  assign avail_out = ~req_in & ~queue_with_msg;
  assign data_out  = /*(req_out & (read_ptr==NUM_MSG) & padding_needed) ? {{(padding){1'b0}},{queue[(INPUT_WIDTH-1)-:no_padding_zone]}} :*/
                     (req_out) ? queue[(FLIT_SIZE*read_ptr)+(FLIT_SIZE-1)-:FLIT_SIZE] : `V_ZERO(FLIT_SIZE);
  assign data_type_out = (is_header & buff_num_flits==4'd1) ? `header_tail:
                         (is_header) ? `header:
                         (is_tail) ? `tail:`payload;
    
  assign is_header = req_out & read_ptr==0;
  assign is_tail = req_out & read_ptr==(buff_num_flits-1);
    
  always @ (posedge clk)
    if (rst_p) begin
      read_ptr 	 <= `V_ZERO(bits_QUEUE_WIDTH);
      queue_with_msg <= 1'b0;
      req_out <= 1'b0;
      buff_num_flits<= `V_ZERO(4);
      //data_out <=`V_ZERO(FLIT_SIZE);
      BroadcastL2_VN0_out <= 1'b0;
      header <= 1'b0;
    end else begin
      if(req_in)begin
        queue <= data_in;
        read_ptr <= `V_ZERO(bits_QUEUE_WIDTH);
        queue_with_msg <= 1'b1;
        buff_num_flits <= num_flits;
        BroadcastL2_VN0_out <= BroadcastL2_VN0_in;
        header <= 1'b1;
        //req_out <= avail_in; 
      end
        
      if(queue_with_msg) begin
        if(avail_in)begin
          req_out <= 1'b1;
          //data_out <= (read_ptr==(buff_num_flits-1) & padding_needed) ? {{(padding){1'b0}},{queue[(FLIT_SIZE*read_ptr)+(no_padding_zone-1)-:no_padding_zone]}} : queue[(FLIT_SIZE*read_ptr)+(FLIT_SIZE-1)-:FLIT_SIZE];
          if (header) begin
            header <= 1'b0;
          end else if ((read_ptr<(buff_num_flits-1))) begin
            read_ptr <= read_ptr + `V_ONE(bits_QUEUE_WIDTH);
          end else begin
            //queue_with_msg <= 1'b0;
            queue_with_msg <= req_in;
            //req_out <= 1'b0;
            req_out <= (req_in) ? avail_in : 1'b0;
          end
        end else begin
          req_out <= 1'b0;
        end
      end else if(req_in) begin
        req_out <= avail_in;
        header <= ~avail_in;
      end else begin
        req_out <= 1'b0;
      end  
    end
  
endmodule 
