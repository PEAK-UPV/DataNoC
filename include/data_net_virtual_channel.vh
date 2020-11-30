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
// Create Date: November 2, 2016
// File Name: data_net_virtual_channel.vh
// Module Name:
// Project Name: DataNoC
// Target Devices:
// Description:
//
//  This file provides the parameters required for definining width, offsets and
//  formats of a phit/flit data network with Virtual Channel support. Also, the
//  format of the buses that connect the Imput Sources to injector (INJECT).
//
// Dependencies:
//
//    data_net_virtual_channel.h
//    common_functions.vh
//
// Revision:
//
//  Revision 0.01 - File Created
//  Revision 0.02 - File name changed -- R. Tornero (ratorga@disca.upv.es) -- October 28, 2017
//
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////

//localparam NUM_PORTS = `NUM_PORTS;									  // Number of ports used in this network
localparam NUM_PORTS_w = Log2_w(NUM_PORTS);							  // Number of bits needed to code NUM_PORTS number
localparam bits_VC = Log2_w(NUM_VC);                       // Number of bits needed to code NUM_VC number
localparam bits_VN = Log2_w(NUM_VN);
localparam NUM_VN_X_VC = NUM_VC * NUM_VN;
localparam bits_VN_X_VC = Log2_w(NUM_VN_X_VC);
localparam NUM_VC_AND_PORTS = NUM_VC * NUM_PORTS;                  // Number of signals per port and each signal have one bit per VC
localparam bits_VC_AND_PORTS = Log2_w(NUM_VC_AND_PORTS);    // Number of bits needed to code NUM_VC number
localparam NUM_VN_X_VC_AND_PORTS = NUM_VN_X_VC * NUM_PORTS;                  // Number of signals per port and each signal have one bit per VC
localparam bits_VN_X_VC_AND_PORTS = Log2_w(NUM_VN_X_VC_AND_PORTS);    // Number of bits needed to code NUM_VC number
localparam long_VC_assigns = ((bits_VN_X_VC_AND_PORTS+1) * NUM_VN_X_VC); // Bits neded to store bidimensional array like //{E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}, in Verilog is not supported a I/O bidimensional array port
localparam long_VC_assigns_per_VN = ((bits_VN_X_VC_AND_PORTS+1) * NUM_VC);  // The same last but only for one VN
localparam long_VC_assigns_NI = ((bits_VN_X_VC+1) * NUM_VN_X_VC);   // Bits neded to store which input REQ (expresed in binary) is located in each VC
localparam long_VC_assigns_NI_per_VN = ((bits_VN_X_VC+1) * NUM_VC);  // The same last but only for one VN
//localparam long_WEIGTHS = `DATA_NET_VN_PRIORITY_VECTOR_w;                     // Number of bits needed to code NUM_VC number into weitgths priorities vector
localparam long_WEIGTHS = VN_WEIGHT_VECTOR_w;                     // Number of bits needed to code NUM_VC number into weitgths priorities vector
localparam long_vector_grants_id = NUM_PORTS_w * NUM_VN_X_VC;        // Number of bits needed to save the port id which is granted in each VC

localparam FLIT_SIZE_VC = FLIT_SIZE * NUM_VN_X_VC;               // Size of full bus with all flit signals that belongs to each port
localparam FLIT_TYPE_SIZE_VC = FLIT_TYPE_SIZE * NUM_VN_X_VC;     // Size of full bus with all flit_type signals that belongs to each port

//*************** COMMON DEFINITIONS FOR INJECT AND OUTPUT_NI ******************************************************

localparam FIFO_SIZE = 2;
localparam FIFO_W = Log2_w(FIFO_SIZE);

localparam FLIT_SIZE_VN = FLIT_SIZE * NUM_VN;               	 // Size of full bus with all flit signals that belongs to each VN
localparam FLIT_TYPE_SIZE_VN = FLIT_TYPE_SIZE * NUM_VN;     	 // Size of full bus with all flit_type signals that belongs to each VN
localparam BROADCAST_FLIT_SIZE_VN = BROADCAST_SIZE * NUM_VN;     // Size of full bus with all broadcast signals that belongs to each VN
