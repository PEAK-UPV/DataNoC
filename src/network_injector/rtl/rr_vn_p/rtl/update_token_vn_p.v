`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
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
// Engineer: T. Piconell (tompic@gap.upv.es)
// 
// Create Date: 
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
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

`include "macro_functions.h"

module UPDATE_TOKEN_VN_P #(
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3                  // Number of Virtual Networks supported

)(
    input clk,
    input rst_p,
    input [NUM_VN_X_VC-1:0] vector_in,
    input [bits_VN-1:0] WEIGTH,
    output reg [bits_VN_X_VC-1:0] token
    );

`include "common_functions.vh"
localparam bits_VC = Log2(NUM_VC);                      // Number of bits needed to code NUM_VC number
localparam bits_VN = Log2(NUM_VN);                        // Number of bits needed to code NUM_VN number
localparam NUM_VN_X_VC = NUM_VC * NUM_VN;                    
localparam bits_VN_X_VC = Log2(NUM_VN_X_VC);              // Number of bits needed to code NUM_VN_X_VC number

wire [bits_VN_X_VC-1:0] vector_id;
encoder #(
     .lenght_in(NUM_VN_X_VC),
     .lenght_out( bits_VN_X_VC)       
     ) encoder_64 (
        .enable(|(64'd0+vector_in)), 
        .vector_in(vector_in),
        .vector_id(vector_id)
    );

//If the weighted VN is the same that was in the last grant, the token vc will be one more, if not the token vc will be zero.
wire [bits_VN_X_VC-1:0] next_vc_token = (WEIGTH==(vector_id/NUM_VC)) ? ((vector_id%NUM_VC)+1) : `V_ZERO(bits_VN_X_VC) ;
wire [bits_VN_X_VC-1:0] next_temp_token = (WEIGTH*NUM_VC)+next_vc_token;


always @(posedge clk)
begin
    if(rst_p) 
    begin
        token <= WEIGTH*NUM_VC;    //The Virtual Network with priority
    end
    else
    begin
        if(|vector_in)begin
            token <= next_temp_token;
        end
    end
end
    
    
endmodule
