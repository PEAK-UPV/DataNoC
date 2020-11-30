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
// File Name: random_seed.v
// Module Name: LFSR_seed
// Project Name: DataNoC
// Target Devices: 
// Description: 
// 
//  This is a 13-bit pseudo random sequence generator with input seed. 
//  This random generator uses a Linear-feedback shift register.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module LFSR_seed (
    input clock,
    input rst_p,
    input [3:0] seed,
    output [12:0] rnd
    );
 
wire feedback = random[12] ^ random[3] ^ random[2] ^ random[0];
 
reg [12:0] random, random_next, random_done;
reg [3:0] count, count_next; //to keep track of the shifts
 
always @ (posedge clock or posedge rst_p)
begin
 if (rst_p)
 begin
  random <= 13'hF; //An LFSR cannot have an all 0 state, thus rst_p to FF
  count <= seed;
 end
  
 else
 begin
  random <= random_next;
  if (count_next == 13)
    count <= seed;
  else
    count <= count_next;
 end
end
 
always @ (*)
begin
 random_next = random; //default state stays the same
 count_next = count;
   
  random_next = {random[11:0], feedback}; //shift left the xor'd every posedge clock
  count_next = count + 1;
 
 if (count_next == 13) begin
  random_done = random; //assign the random number to output after 13 shifts
 end else begin
   random_done = {(random << count) | (random >> (13-count))};
 end
  
end
 
 
assign rnd = random_done;
 
endmodule