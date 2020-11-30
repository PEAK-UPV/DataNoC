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
// Create Date: November 9, 2016
// File Name: common_functions.vh
// Module Name:
// Project Name: DataNoC
// Target Devices: 
// Description: 
//
//  This file contains different funcions used by many modules
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////

//
// Gets the log2 of a given number, but for log2(1) = 1, and not 0 as it is the actual result
//
function integer Log2_w;
  input integer value;
begin
  for (Log2_w=0; value>0; Log2_w=Log2_w+1)
    value = value>>1;
  end
endfunction
//
// Gets the log2 of a given number
//
function integer Log2;
  input integer value;
begin
  value = value-1;
  for (Log2=0; value>0; Log2=Log2+1)
    value = value>>1;
  end
endfunction

//
// Gets the first integer divisor of a number 'DIV' when
// the provided divisor 'DIVISOR' is not an integer divisor
//
function integer FIRST_INTEGER_DIVISOR;
  input integer DIV;
  input integer DIVISOR;
  
  integer j;
  integer found;
begin
  found = 0;
  if (DIVISOR <= 1) begin
    FIRST_INTEGER_DIVISOR = DIV;
    found = 1;
  end else begin
    //
    if (DIV <= DIVISOR) begin
      FIRST_INTEGER_DIVISOR = DIV;
      found = 1;
    end else begin
      //
      if (DIV % DIVISOR == 0) begin
        FIRST_INTEGER_DIVISOR = DIVISOR;
        found = 1;
      end else begin
        for (j = 4; j <= DIV; j = j + 1) begin
          if (DIV % j == 0 && found == 0) begin
            FIRST_INTEGER_DIVISOR = j;
            found = 1;
          end
        end
      end // if (DIV % DIVISOR... else ...
      // 
    end
    //
  end // if (DIVISOR <= 1) ... else ...
  
  if (found == 0) begin
    FIRST_INTEGER_DIVISOR = DIV;
  end
end
endfunction  

// * This function returns the number of padding bits required for spliting a bus of ' num signals' wires
// * into chuncks of 'payload_size'
function integer GET_NUM_PADDING_BITS;
  input integer num_signals;
  input integer payload_size;
  
  integer mod;
  integer res;
begin  
  mod = (num_signals % payload_size);
     
  if (mod == 0) begin
    res = 0;
  end else begin
    res = payload_size - mod;
  end
  
  GET_NUM_PADDING_BITS = res;
end  


endfunction


