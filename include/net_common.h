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
// Create Date: Novembre 4, 2016
// File Name: net_common.h
// Module Name: global_includes.h
// Project Name:
// Target Devices:
// Description:
//
//  This file provides common definitions for the network switches
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef __NET_COMMON_H__
`define __NET_COMMON_H__

`define NODE_ID_w               12

//****************************************************************************
//
// * Flit types
//
//****************************************************************************
`define payload                 2'd0        // Flit type: payload
`define tail                    2'd1        // Flit type: tail
`define header_tail             2'd2        // Flit type: header_tail (single flit message)
`define header                  2'd3        // Flit type: header

//*******************************************************************
//
// * Main identificable Component types inside a tile
//
`define L1_cache                3'd0
`define MS                      3'd7

`endif // header file
