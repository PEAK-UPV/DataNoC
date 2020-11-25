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
// Create Date: November 4, 2016
// File Name: net_2dmesh.h
// Module Name: global_includes.h
// Project Name: DataNoC
// Target Devices:
// Description:
//
//  This file provides common definitions for the network 2dmesh switches
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef __NET_2DMESH_H__
`define __NET_2DMESH_H__

//****************************************************************************
//
// * PORTS
//
//****************************************************************************
`define NUM_PORTS               5
`define PORT_L                  3'b000      // Local port id code
`define PORT_E                  3'b001      // East port id code
`define PORT_W                  3'b011      // West port id code
`define PORT_N                  3'b101      // Nort port id code
`define PORT_S                  3'b111      // South port id code


`endif
