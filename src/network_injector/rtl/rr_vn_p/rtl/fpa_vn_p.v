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
