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

module ROT_RIGHT_NUM_VC #(
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3                  // Number of Virtual Networks supported

)(
    input [NUM_VC-1:0] vector_in,
    input [bits_VC-1:0] shift,
    output [NUM_VC-1:0] vector_out
    );
    
`include "common_functions.vh"   
localparam bits_VC = Log2(NUM_VC);                       // Number of bits needed to code NUM_VC number
localparam NUM_VN_X_VC = NUM_VC * NUM_VN;
localparam NUM_VC_AND_PORTS = NUM_VC * 5;                  // Number of signals per port and each signal have one bit per VC
localparam bits_VC_AND_PORTS = Log2(NUM_VC_AND_PORTS);    // Number of bits needed to code NUM_VC number   	


    assign vector_out = (vector_in >> shift) | (vector_in << (NUM_VC-shift));
    
endmodule
