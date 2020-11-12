////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 13.2
//  \   \         Application : 
//  /   /         Filename : xil_DAxti8
// /___/   /\     Timestamp : 08/31/2013 09:49:06
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: 
//Design Name: 
//
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