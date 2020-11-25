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
// File Name: fpga_vn_p.v
// Module Name: FPA_VN_P
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

module FPA_VN_P #(
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3                  // Number of Virtual Networks supported

)(
    input [NUM_VN_X_VC-1:0] vector_in,
    output [NUM_VN_X_VC-1:0] vector_out
    );

`include "common_functions.vh"
localparam bits_VC = Log2(NUM_VC);                      // Number of bits needed to code NUM_VC number
localparam bits_VN = Log2(NUM_VN);                        // Number of bits needed to code NUM_VN number
localparam NUM_VN_X_VC = NUM_VC * NUM_VN;                    
localparam bits_VN_X_VC = Log2(NUM_VN_X_VC);              // Number of bits needed to code NUM_VN_X_VC number

genvar j;
generate
    for( j=0; j<NUM_VN_X_VC;j = j+1) begin : LOOP
	    assign vector_out[j] = (j==0) ? vector_in[0] : ((vector_in[j]) & (~|vector_in[(j-1) -: j]));
    end
    
 endgenerate
 
 
 
endmodule
