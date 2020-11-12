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
// Engineer: R. Tornero (ratorga@disca.upv.es)
// 
// Create Date: 04/14/2016 02:55:24 PM
// Design Name: 
// Module Name: encoder
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


module encoder #(
	parameter lenght_in = 64,
	parameter lenght_out = 6)
(
	input  enable,
	input [lenght_in-1:0] vector_in, 
	output [lenght_out-1:0] vector_id  
);
  genvar k, i;
  for (i = 0; i < lenght_out; i = i + 1) begin : gen_mux_index
    wire [lenght_in - 1 : 0] data_aux;
    for (k = 0; k < lenght_in; k = k + 1) begin : gen_mux_vc1
      assign data_aux[k] = vector_in[k] & k[i];
    end // end for k
    assign vector_id[i] = |data_aux;
  end // end for i
endmodule 
