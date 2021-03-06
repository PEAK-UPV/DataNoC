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
// File Name: round_robin_arb_vn_p.v
// Module Name: ROUND_ROBIN_ARB_VN_P
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

module ROUND_ROBIN_ARB_VN_P #(
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3                  // Number of Virtual Networks supported

)(
    input [NUM_VN_X_VC-1:0] vector_in,
    input clk,
    input rst_p,
    input [bits_VN-1:0] WEIGTH,
    input [NUM_VN_X_VC-1:0] GRANTS_IN,
    output [bits_VN_X_VC-1:0] grant_id,                
    output [NUM_VN_X_VC-1:0] vector_out
    );

`include "common_functions.vh"
localparam bits_VC = Log2(NUM_VC);                      // Number of bits needed to code NUM_VC number
localparam bits_VN = Log2(NUM_VN);                        // Number of bits needed to code NUM_VN number
localparam NUM_VN_X_VC = NUM_VC * NUM_VN;                    
localparam bits_VN_X_VC = Log2(NUM_VN_X_VC);              // Number of bits needed to code NUM_VN_X_VC number

wire [bits_VN_X_VC-1:0] w_token;

wire [NUM_VN_X_VC-1:0] w_right_to_FPA;
wire [NUM_VN_X_VC-1:0] w_FPA_to_left;
wire [NUM_VN_X_VC-1:0] vector_out_left;

wire [bits_VN_X_VC-1:0] vector_id;
encoder #(
     .lenght_in(NUM_VN_X_VC),
     .lenght_out( bits_VN_X_VC)       
     ) encoder_64 (
        .enable(|(64'd0+vector_out_left)), 
        .vector_in(vector_out_left),
        .vector_id(vector_id)
    );

        assign grant_id = (rst_p) ? `V_ZERO(bits_VN_X_VC) : vector_id;    //Log_base2 of (grants_r) it will get the right position 
        assign vector_out = (rst_p) ? `V_ZERO(NUM_VN_X_VC) : vector_out_left;


ROT_RIGHT_VN_P #(
  .NUM_VC             ( NUM_VC                   ),
  .NUM_VN             ( NUM_VN                   )  
)rot_right_inst0(
    .vector_in(vector_in),
    .shift(w_token),
    .vector_out(w_right_to_FPA)
);

FPA_VN_P #(
  .NUM_VC             ( NUM_VC                   ),
  .NUM_VN             ( NUM_VN                   )  
)FPA_inst0(
    .vector_in(w_right_to_FPA),
    .vector_out(w_FPA_to_left)
    );
    
ROT_LEFT_VN_P #(
  .NUM_VC             ( NUM_VC                   ),
  .NUM_VN             ( NUM_VN                   )  
)rot_left_inst0(
    .vector_in(w_FPA_to_left),
    .shift(w_token),
    .vector_out(vector_out_left)
    );
    
UPDATE_TOKEN_VN_P #(
  .NUM_VC             ( NUM_VC                   ),
  .NUM_VN             ( NUM_VN                   )  
)update_token_inst0(
    .clk(clk),
    .rst_p(rst_p),
    .vector_in(GRANTS_IN),
    .WEIGTH(WEIGTH),
    .token(w_token)
    );
    
 endmodule
     
