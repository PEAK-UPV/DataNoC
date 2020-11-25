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
// Engineer: R. Tornero (ratorga@disca.upv.es)
// Contact: J.Flich (jflich@disca.upv.es)
// Create Date: April 14, 2016
// File Name: encoder.v
// Module Name: encoder
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
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

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
