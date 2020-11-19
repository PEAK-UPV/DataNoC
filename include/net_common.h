`ifndef __NET_COMMON_H__
`define __NET_COMMON_H__
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
// Company:   GAP (UPV)
// Engineer:  R. Tornero (ratorga@disca.upv.es)
//
// Create Date: 04.11.2016
// Design Name:
// Module Name: global_includes.h
// Project Name:
// Target Devices:
// Tool Versions:
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
