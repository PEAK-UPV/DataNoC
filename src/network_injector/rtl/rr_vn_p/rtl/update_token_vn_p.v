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
// Engineer: T. Picornell (tompic@gap.upv.es
// Contact: J.Flich (jflich@disca.upv.es)
// Create Date: 
// File Name: update_token_vn_p.v
// Module Name: UPDATE_TOKEN_VN_P
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
