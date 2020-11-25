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
// Engineer: T. Picornell (tompic@gap.upv.es)
// Contact: J.Flich (jflich@disca.upv.es)
// Create Date:
// File Name: update_token_x_in.v
// Module Name: round-robin parametric arbiter
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

module UPDATE_TOKEN_X_IN #(
parameter IO_SIZE            = 5,
parameter IO_w               = 3

)(
    input clk,
    input rst_p,
    input [IO_SIZE-1:0] vector_in,
    output reg [IO_w-1:0] token
    );
 wire [IO_w-1:0] vector_id;
encoder #(
     .lenght_in(IO_SIZE),
     .lenght_out(IO_w)
     ) encoder_64 (
        .enable(|(64'd0+vector_in)),
        .vector_in(vector_in),
        .vector_id(vector_id)
    );

always @(posedge clk)
begin
    if(rst_p)
    begin
        token <= `V_ZERO(IO_w);
    end
    else
    begin
        if(|vector_in)begin
            token <= (vector_id == (IO_SIZE-1)) ? `V_ZERO(IO_w) : vector_id + 1;
        end
    end
end


endmodule
