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
// Engineer: J. Flich (jflich@disca.upv.es)
//
// Create Date: 09/03/2014
// Design Name:
// Module Name:
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//  RTG: XY + XY-based broadcast synchronous Switch. All the flits cross the routing unit
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "macro_functions.h"
`include "net_common.h"
`include "net_2dmesh.h"
`include "data_net_virtual_channel.h"

module switch_2dmesh_vc #(
  parameter ID                 = 0,
  //
  parameter FPGA_DIMX          = 2,                 // FPGA number of Tiles in X-dimension
  parameter FPGA_DIMY          = 1,                 // FPGA number of Tiles in Y-dimension
  parameter FPGA_N_NxT         = 1,                 // FPGA number of Nodes per tile
  parameter FPGA_N_Nodes       = 2,                 // FPGA number of Total nodes in the topology
  parameter FPGA_DIMX_w        = 1,                 // FPGA X-Dim width
  parameter FPGA_DIMY_w        = 0,                 // FPGA Y-Dim width
  parameter FPGA_N_NxT_w       = 0,                 // FPGA Nodes per tile width
  parameter FPGA_N_Nodes_w     = 1,                 // FPGA Total nodes width
  parameter FPGA_SWITCH_ID_w   = 1,                 // ID width for switches
  parameter GLBL_DIMX          = 2,                 // Global number of tiles in X-dimension
  parameter GLBL_DIMY          = 1,                 // Global number of Tiles in Y-dimension
  parameter GLBL_N_NxT         = 1,                 // Global number of Nodes per tile
  parameter GLBL_N_Nodes       = 2,                 // Global number of Total nodes in the topology
  parameter GLBL_DIMX_w        = 1,                 // Global  X-Dim width
  parameter GLBL_DIMY_w        = 0,                 // Global  Y-Dim width
  parameter GLBL_N_NxT_w       = 0,                 // Global Nodes per tile width
  parameter GLBL_N_Nodes_w     = 1,                 // Total nodes width
  parameter GLBL_SWITCH_ID_w   = 1,                 // ID width for switches
  //
  parameter FLIT_SIZE          = 64,
  parameter PHIT_SIZE_L        = 64,
  parameter PHIT_SIZE_N        = 64,
  parameter PHIT_SIZE_E        = 64,
  parameter PHIT_SIZE_W        = 64,
  parameter PHIT_SIZE_S        = 64,
  parameter FLIT_TYPE_SIZE     = 2,
  parameter BROADCAST_SIZE     = 5,
  parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
  parameter NUM_VN             = 3,                 // Number of Virtual Networks supported
  //
  parameter IB_QUEUE_SIZE      = 8,
  parameter IB_SG_UPPER_THOLD  = 6,
  parameter IB_SG_LOWER_THOLD  = 4,
  //
  parameter DATA_NET_FLIT_DST_UNIT_ID_LSB = 0,
  parameter DATA_NET_FLIT_DST_UNIT_ID_MSB = 0,
  parameter ENABLE_VN_WEIGHTS_SUPPORT = "no",
  parameter VN_WEIGHT_VECTOR_w = 20
) (

  clk,
  rst_p,
  WeightsVector_in,               // New weights vector to guarante various bandwidths to different virtual networks. It vector is going to SA Routing arbiters

  debug_signals_o,

  FlitFromE,
  FlitFromN,
  FlitFromNI,
  FlitFromS,
  FlitFromW,

  FlitTypeFromE,    //Flit type (header, body, tail, header_tail). We need lines because of it is not coded in the flit structure
  FlitTypeFromN,
  FlitTypeFromNI,
  FlitTypeFromS,
  FlitTypeFromW,

  BroadcastFlitFromE,                    //Broadcast signal. It indicates that the flit comming from east has to be broadcasted. Again, it is not coded in the flit structure, that's way an additional line is required
  BroadcastFlitFromN,
  BroadcastFlitFromNI,
  BroadcastFlitFromS,
  BroadcastFlitFromW,
  GoBitFromE,                            //Flow control signals (S&G). For the wires routed from the downstream switch
  GoBitFromN,
  GoBitFromNI,
  GoBitFromS,
  GoBitFromW,
  ValidBitFromE,
  ValidBitFromN,
  ValidBitFromNI,
  ValidBitFromS,
  ValidBitFromW,
  VC_FromE,
  VC_FromN,
  VC_FromNI,
  VC_FromS,
  VC_FromW,

  FlitToE,                 //Outputs for flits, connections to neighbour switches (phit/flit depending on the parameter size)
  FlitToN,
  FlitToNI,
  FlitToS,
  FlitToW,

  FlitTypeToE,
  FlitTypeToN,
  FlitTypeToNI,
  FlitTypeToS,
  FlitTypeToW,

  BroadcastFlitToE,
  BroadcastFlitToN,
  BroadcastFlitToS,
  BroadcastFlitToW,
  BroadcastFlitToNI,

  GoBitToE,                                //flow control signal (S&G). For routing wires to the upstream switch
  GoBitToN,
  GoBitToNIC,
  GoBitToS,
  GoBitToW,

  ValidBitToE,                             //Asserted when the switch is forwarding a flit
  ValidBitToN,
  ValidBitToNI,
  ValidBitToS,
  ValidBitToW,
  VC_ToE,
  VC_ToN,
  VN_ToNI,
  VC_ToS,
  VC_ToW
);

  `include "common_functions.vh"
  `include "data_net_virtual_channel.vh"

  input clk;
  input rst_p;
  input [VN_WEIGHT_VECTOR_w-1:0] WeightsVector_in;               // New weights vector to guarante various bandwidths to different virtual networks. It vector is going to SA Routing arbiters

  output[31 : 0] debug_signals_o;

  input [PHIT_SIZE_E-1:0] FlitFromE;
  input [PHIT_SIZE_N-1:0] FlitFromN;
  input [PHIT_SIZE_L-1:0] FlitFromNI;
  input [PHIT_SIZE_S-1:0] FlitFromS;
  input [PHIT_SIZE_W-1:0] FlitFromW;

  input [FLIT_TYPE_SIZE-1:0] FlitTypeFromE;    //Flit type (header, body, tail, header_tail). We need lines because of it is not coded in the flit structure
  input [FLIT_TYPE_SIZE-1:0] FlitTypeFromN;
  input [FLIT_TYPE_SIZE-1:0] FlitTypeFromNI;
  input [FLIT_TYPE_SIZE-1:0] FlitTypeFromS;
  input [FLIT_TYPE_SIZE-1:0] FlitTypeFromW;

  input BroadcastFlitFromE;                   //Broadcast signal. It indicates that the flit comming from east has to be broadcasted. Again, it is not coded in the flit structure, that's way an additional line is required
  input BroadcastFlitFromN;
  input BroadcastFlitFromNI;
  input BroadcastFlitFromS;
  input BroadcastFlitFromW;
  input [NUM_VN_X_VC-1 : 0] GoBitFromE;                            //Flow control signals (S&G). For the wires routed from the downstream switch
  input [NUM_VN_X_VC-1 : 0] GoBitFromN;
  input [NUM_VN-1 : 0]      GoBitFromNI;
  input [NUM_VN_X_VC-1 : 0] GoBitFromS;
  input [NUM_VN_X_VC-1 : 0] GoBitFromW;
  input ValidBitFromE;
  input ValidBitFromN;
  input ValidBitFromNI;
  input ValidBitFromS;
  input ValidBitFromW;
  input [bits_VN_X_VC-1:0] VC_FromE;
  input [bits_VN_X_VC-1:0] VC_FromN;
  input [bits_VN_X_VC-1:0] VC_FromNI;
  input [bits_VN_X_VC-1:0] VC_FromS;
  input [bits_VN_X_VC-1:0] VC_FromW;

  output [PHIT_SIZE_E-1:0] FlitToE;                 //Outputs for flits, connections to neighbour switches (phit/flit depending on the parameter size)
  output [PHIT_SIZE_N-1:0] FlitToN;
  output [PHIT_SIZE_L-1:0] FlitToNI;
  output [PHIT_SIZE_S-1:0] FlitToS;
  output [PHIT_SIZE_W-1:0] FlitToW;

  output [FLIT_TYPE_SIZE-1:0] FlitTypeToE;
  output [FLIT_TYPE_SIZE-1:0] FlitTypeToN;
  output [FLIT_TYPE_SIZE-1:0] FlitTypeToNI;
  output [FLIT_TYPE_SIZE-1:0] FlitTypeToS;
  output [FLIT_TYPE_SIZE-1:0] FlitTypeToW;

  output BroadcastFlitToE;
  output BroadcastFlitToN;
  output BroadcastFlitToS;
  output BroadcastFlitToW;
  output BroadcastFlitToNI;

  output [NUM_VN_X_VC-1 : 0] GoBitToE;                                //flow control signal (S&G). For routing wires to the upstream switch
  output [NUM_VN_X_VC-1 : 0] GoBitToN;
  output [NUM_VN_X_VC-1 : 0] GoBitToNIC;
  output [NUM_VN_X_VC-1 : 0] GoBitToS;
  output [NUM_VN_X_VC-1 : 0] GoBitToW;

  output ValidBitToE;                             //Asserted when the switch is forwarding a flit
  output ValidBitToN;
  output ValidBitToNI;
  output ValidBitToS;
  output ValidBitToW;
  output [bits_VN_X_VC-1:0] VC_ToE;
  output [bits_VN_X_VC-1:0] VC_ToN;
  output [bits_VN-1:0] VN_ToNI;
  output [bits_VN_X_VC-1:0] VC_ToS;
  output [bits_VN_X_VC-1:0] VC_ToW;

  `define SWITCH_ID_RANGE  GLBL_SWITCH_ID_w-1:0

   wire [bits_VN_X_VC-1:0] VC_ToNI;
   assign VN_ToNI = VC_ToNI / NUM_VC;

  genvar i;

   generate
    for (i=0; i<NUM_VN_X_VC; i=i+1)begin : VN_X_VC

                //Internal connections for each VC
         //routing request wires between Input Units and Routing Engines
     wire REQ__FROM__IU_N__TO__RT_N;
     wire REQ__FROM__IU_E__TO__RT_E;
     wire REQ__FROM__IU_L__TO__RT_L;
     wire REQ__FROM__IU_S__TO__RT_S;
     wire REQ__FROM__IU_W__TO__RT_W;

     //broadcast wires between input units and routing engines
     wire  BCFLIT__FROM__IU_E__TO__RT_E;
     wire  BCFLIT__FROM__IU_S__TO__RT_S;
     wire  BCFLIT__FROM__IU_W__TO__RT_W;
     wire  BCFLIT__FROM__IU_N__TO__RT_N;
     wire  BCFLIT__FROM__IU_L__TO__RT_L;

     //flit type wires between input units and routing engines
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__IU_E__TO__RT_E;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__IU_S__TO__RT_S;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__IU_W__TO__RT_W;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__IU_N__TO__RT_N;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__IU_L__TO__RT_L;

     //flit wires between input units and routing engines
     wire [FLIT_SIZE-1:0] FLIT__FROM__IU_E__TO__RT_E;
     wire [FLIT_SIZE-1:0] FLIT__FROM__IU_S__TO__RT_S;
     wire [FLIT_SIZE-1:0] FLIT__FROM__IU_W__TO__RT_W;
     wire [FLIT_SIZE-1:0] FLIT__FROM__IU_N__TO__RT_N;
     wire [FLIT_SIZE-1:0] FLIT__FROM__IU_L__TO__RT_L;

     //wires between routing engine and buffer
     wire RT_READYFORREQ__FROM__RT_N__TO__IU_N;
     wire RT_READYFORREQ__FROM__RT_E__TO__IU_E;
     wire RT_READYFORREQ__FROM__RT_L__TO__IU_L;
     wire RT_READYFORREQ__FROM__RT_S__TO__IU_S;
     wire RT_READYFORREQ__FROM__RT_W__TO__IU_W;

     //broadcast wires from RT_M__TO__O(Output)_K
     wire BCFLIT__FROM__RT_E__TO__O_N;
     wire BCFLIT__FROM__RT_E__TO__O_S;
     wire BCFLIT__FROM__RT_E__TO__O_W;
     wire BCFLIT__FROM__RT_E__TO__O_L;
     wire BCFLIT__FROM__RT_L__TO__O_E;
     wire BCFLIT__FROM__RT_L__TO__O_N;
     wire BCFLIT__FROM__RT_L__TO__O_S;
     wire BCFLIT__FROM__RT_L__TO__O_W;
     wire BCFLIT__FROM__RT_N__TO__O_E;
     wire BCFLIT__FROM__RT_N__TO__O_S;
     wire BCFLIT__FROM__RT_N__TO__O_W;
     wire BCFLIT__FROM__RT_N__TO__O_L;
     wire BCFLIT__FROM__RT_S__TO__O_E;
     wire BCFLIT__FROM__RT_S__TO__O_N;
     wire BCFLIT__FROM__RT_S__TO__O_W;
     wire BCFLIT__FROM__RT_S__TO__O_L;
     wire BCFLIT__FROM__RT_W__TO__O_E;
     wire BCFLIT__FROM__RT_W__TO__O_N;
     wire BCFLIT__FROM__RT_W__TO__O_S;
     wire BCFLIT__FROM__RT_W__TO__O_L;
     //wire BCFLIT__FROM__RT_L__TO__O_L;

     //flits and flit type wires between RT and Output (X). Connects FlitOut and FlitType at RTs to Flit_{E,W,L,N,S} and FlitType_{...} at OUTPUTs, respectively

     wire [FLIT_SIZE-1:0] FLIT__FROM__RT_E__TO__O_ALL;
     wire [FLIT_SIZE-1:0] FLIT__FROM__RT_L__TO__O_ALL;
     wire [FLIT_SIZE-1:0] FLIT__FROM__RT_N__TO__O_ALL;
     wire [FLIT_SIZE-1:0] FLIT__FROM__RT_S__TO__O_ALL;
     wire [FLIT_SIZE-1:0] FLIT__FROM__RT_W__TO__O_ALL;


     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__RT_E__TO__O_ALL;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__RT_L__TO__O_ALL;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__RT_N__TO__O_ALL;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__RT_S__TO__O_ALL;
     wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__RT_W__TO__O_ALL;

     //grants
     //SA to RT to Output (X) grant wires.
     wire GRANT__FROM__SA_E__TO__RT_L;
     wire GRANT__FROM__SA_E__TO__RT_E;
     wire GRANT__FROM__SA_E__TO__RT_N;
     wire GRANT__FROM__SA_E__TO__RT_S;
     wire GRANT__FROM__SA_E__TO__RT_W;
     wire GRANT__FROM__SA_L__TO__RT_E;
     wire GRANT__FROM__SA_L__TO__RT_L;
     wire GRANT__FROM__SA_L__TO__RT_N;
     wire GRANT__FROM__SA_L__TO__RT_S;
     wire GRANT__FROM__SA_L__TO__RT_W;
     wire GRANT__FROM__SA_N__TO__RT_E;
     wire GRANT__FROM__SA_N__TO__RT_N;
     wire GRANT__FROM__SA_N__TO__RT_L;
     wire GRANT__FROM__SA_N__TO__RT_S;
     wire GRANT__FROM__SA_N__TO__RT_W;
     wire GRANT__FROM__SA_S__TO__RT_E;
     wire GRANT__FROM__SA_S__TO__RT_S;
     wire GRANT__FROM__SA_S__TO__RT_L;
     wire GRANT__FROM__SA_S__TO__RT_N;
     wire GRANT__FROM__SA_S__TO__RT_W;
     wire GRANT__FROM__SA_W__TO__RT_E;
     wire GRANT__FROM__SA_W__TO__RT_W;
     wire GRANT__FROM__SA_W__TO__RT_L;
     wire GRANT__FROM__SA_W__TO__RT_N;
     wire GRANT__FROM__SA_W__TO__RT_S;

     //VA to RT to VC (X) grant wires.

     wire GRANT__FROM__VA_L__TO__RT_E;
     wire GRANT__FROM__VA_E__TO__RT_E;
     wire GRANT__FROM__VA_N__TO__RT_E;
     wire GRANT__FROM__VA_S__TO__RT_E;
     wire GRANT__FROM__VA_W__TO__RT_E;
     wire GRANT__FROM__VA_L__TO__RT_N;
     wire GRANT__FROM__VA_E__TO__RT_N;
     wire GRANT__FROM__VA_N__TO__RT_N;
     wire GRANT__FROM__VA_S__TO__RT_N;
     wire GRANT__FROM__VA_W__TO__RT_N;
     wire GRANT__FROM__VA_L__TO__RT_S;
     wire GRANT__FROM__VA_E__TO__RT_S;
     wire GRANT__FROM__VA_N__TO__RT_S;
     wire GRANT__FROM__VA_S__TO__RT_S;
     wire GRANT__FROM__VA_W__TO__RT_S;
     wire GRANT__FROM__VA_L__TO__RT_W;
     wire GRANT__FROM__VA_E__TO__RT_W;
     wire GRANT__FROM__VA_N__TO__RT_W;
     wire GRANT__FROM__VA_S__TO__RT_W;
     wire GRANT__FROM__VA_W__TO__RT_W;
     wire GRANT__FROM__VA_L__TO__RT_L;
     wire GRANT__FROM__VA_N__TO__RT_L;
     wire GRANT__FROM__VA_S__TO__RT_L;
     wire GRANT__FROM__VA_E__TO__RT_L;
     wire GRANT__FROM__VA_W__TO__RT_L;

     //requests
     //SA request wires between routing engine and SA.
     wire REQ__FROM__RT_E__TO__SA_L;
     wire REQ__FROM__RT_E__TO__SA_N;
     wire REQ__FROM__RT_E__TO__SA_S;
     wire REQ__FROM__RT_E__TO__SA_W;
     wire REQ__FROM__RT_L__TO__SA_E;
     wire REQ__FROM__RT_L__TO__SA_N;
     wire REQ__FROM__RT_L__TO__SA_S;
     wire REQ__FROM__RT_L__TO__SA_W;
     wire REQ__FROM__RT_N__TO__SA_E;
     wire REQ__FROM__RT_N__TO__SA_L;
     wire REQ__FROM__RT_N__TO__SA_S;
     wire REQ__FROM__RT_N__TO__SA_W;
     wire REQ__FROM__RT_S__TO__SA_E;
     wire REQ__FROM__RT_S__TO__SA_L;
     wire REQ__FROM__RT_S__TO__SA_N;
     wire REQ__FROM__RT_S__TO__SA_W;
     wire REQ__FROM__RT_W__TO__SA_E;
     wire REQ__FROM__RT_W__TO__SA_L;
     wire REQ__FROM__RT_W__TO__SA_N;
     wire REQ__FROM__RT_W__TO__SA_S;

    //VC request wires between routing engine and VA.
     wire REQ__FROM__RT_E__TO__VA_L;
     wire REQ__FROM__RT_E__TO__VA_N;
     wire REQ__FROM__RT_E__TO__VA_S;
     wire REQ__FROM__RT_E__TO__VA_W;
     wire REQ__FROM__RT_L__TO__VA_N;
     wire REQ__FROM__RT_L__TO__VA_S;
     wire REQ__FROM__RT_L__TO__VA_E;
     wire REQ__FROM__RT_L__TO__VA_W;
     wire REQ__FROM__RT_N__TO__VA_L;
     wire REQ__FROM__RT_N__TO__VA_S;
     wire REQ__FROM__RT_N__TO__VA_E;
     wire REQ__FROM__RT_N__TO__VA_W;
     wire REQ__FROM__RT_S__TO__VA_L;
     wire REQ__FROM__RT_S__TO__VA_N;
     wire REQ__FROM__RT_S__TO__VA_E;
     wire REQ__FROM__RT_S__TO__VA_W;
     wire REQ__FROM__RT_W__TO__VA_L;
     wire REQ__FROM__RT_W__TO__VA_E;
     wire REQ__FROM__RT_W__TO__VA_N;
     wire REQ__FROM__RT_W__TO__VA_S;

     //these wires connect RT to SA. They are asserted when a tail is going to cross the X. In that way the SA can deallocate resources and advance according to its policy
     wire TAILFLIT__FROM__RT_N__TO__SA_ALL;
     wire TAILFLIT__FROM__RT_E__TO__SA_ALL;
     wire TAILFLIT__FROM__RT_W__TO__SA_ALL;
     wire TAILFLIT__FROM__RT_S__TO__SA_ALL;
     wire TAILFLIT__FROM__RT_L__TO__SA_ALL;

     //these wires connect SW to IB
    wire [PHIT_SIZE_E-1:0] FlitFromE__FROM__SW__TO__IU_E;
    wire [PHIT_SIZE_L-1:0] FlitFromNI__FROM__SW__TO__IU_L;
    wire [PHIT_SIZE_N-1:0] FlitFromN__FROM__SW__TO__IU_N;
    wire [PHIT_SIZE_S-1:0] FlitFromS__FROM__SW__TO__IU_S;
    wire [PHIT_SIZE_W-1:0] FlitFromW__FROM__SW__TO__IU_W;
    wire [FLIT_TYPE_SIZE-1:0] FlitTypeFromE__FROM__SW__TO__IU_E;
    wire [FLIT_TYPE_SIZE-1:0] FlitTypeFromNI__FROM__SW__TO__IU_L;
    wire [FLIT_TYPE_SIZE-1:0] FlitTypeFromN__FROM__SW__TO__IU_N;
    wire [FLIT_TYPE_SIZE-1:0] FlitTypeFromS__FROM__SW__TO__IU_S;
    wire [FLIT_TYPE_SIZE-1:0] FlitTypeFromW__FROM__SW__TO__IU_W;

    wire BroadcastFlitFromE__FROM__SW__TO__IU_E;
    wire BroadcastFlitFromNI__FROM__SW__TO__IU_L;
    wire BroadcastFlitFromN__FROM__SW__TO__IU_N;
    wire BroadcastFlitFromS__FROM__SW__TO__IU_S;
    wire BroadcastFlitFromW__FROM__SW__TO__IU_W;

    wire ValidBitFromE__FROM__SW__TO__IU_E;
    wire ValidBitFromNI__FROM__SW__TO__IU_L;
    wire ValidBitFromN__FROM__SW__TO__IU_N;
    wire ValidBitFromS__FROM__SW__TO__IU_S;
    wire ValidBitFromW__FROM__SW__TO__IU_W;

     // flow control due to flit -> phit conversion between OUTPUT and SA
    wire GoBitToN;
    wire GoBitToNIC;
    wire GoBitToE;
    wire GoBitToS;
    wire GoBitToW;



    end //end for
    endgenerate

    /*generate
    for (i=0; i<NUM_VN; i=i+1)begin : VN
      wire GoBitToNIC;
      //wire ValidBitFromNI__FROM__SW__TO__IU_L;
    end //end for
    endgenerate

    generate
    for (i=0; i<NUM_VN; i=i+1)begin : VN
      //assign VN[i].ValidBitFromNI__FROM__SW__TO__IU_L = (VN_FromNI == i) & ValidBitFromNI;
      assign GoBitToNIC[i] = VN[i].GoBitToNIC;
    end //end for
    endgenerate*/

    genvar j;
    //Assigns the values to the respective signals only when the respective VC incoming is the same as the VC to which the signal belongs.
    generate
    for(j=0; j<NUM_VN_X_VC;j = j+1)begin

    //DEMULTIPLEXORS
      assign VN_X_VC[j].FlitFromE__FROM__SW__TO__IU_E = FlitFromE;
      assign VN_X_VC[j].FlitFromNI__FROM__SW__TO__IU_L = FlitFromNI;
      assign VN_X_VC[j].FlitFromN__FROM__SW__TO__IU_N = FlitFromN;
      assign VN_X_VC[j].FlitFromS__FROM__SW__TO__IU_S = FlitFromS;
      assign VN_X_VC[j].FlitFromW__FROM__SW__TO__IU_W = FlitFromW;

      assign VN_X_VC[j].FlitTypeFromE__FROM__SW__TO__IU_E = FlitTypeFromE;
      assign VN_X_VC[j].FlitTypeFromNI__FROM__SW__TO__IU_L = FlitTypeFromNI;
      assign VN_X_VC[j].FlitTypeFromN__FROM__SW__TO__IU_N = FlitTypeFromN;
      assign VN_X_VC[j].FlitTypeFromS__FROM__SW__TO__IU_S = FlitTypeFromS;
      assign VN_X_VC[j].FlitTypeFromW__FROM__SW__TO__IU_W = FlitTypeFromW;

      assign VN_X_VC[j].BroadcastFlitFromE__FROM__SW__TO__IU_E = BroadcastFlitFromE;
      assign VN_X_VC[j].BroadcastFlitFromNI__FROM__SW__TO__IU_L = BroadcastFlitFromNI;
      assign VN_X_VC[j].BroadcastFlitFromN__FROM__SW__TO__IU_N = BroadcastFlitFromN;
      assign VN_X_VC[j].BroadcastFlitFromS__FROM__SW__TO__IU_S = BroadcastFlitFromS;
      assign VN_X_VC[j].BroadcastFlitFromW__FROM__SW__TO__IU_W = BroadcastFlitFromW;

      assign VN_X_VC[j].ValidBitFromE__FROM__SW__TO__IU_E = (VC_FromE == j) & ValidBitFromE;
      assign VN_X_VC[j].ValidBitFromNI__FROM__SW__TO__IU_L = (VC_FromNI == j) & ValidBitFromNI;
      assign VN_X_VC[j].ValidBitFromN__FROM__SW__TO__IU_N = (VC_FromN == j) & ValidBitFromN;
      assign VN_X_VC[j].ValidBitFromS__FROM__SW__TO__IU_S = (VC_FromS == j) & ValidBitFromS;
      assign VN_X_VC[j].ValidBitFromW__FROM__SW__TO__IU_W = (VC_FromW == j) & ValidBitFromW;

      //MULTIPLEXOR
      assign GoBitToN[j] =   VN_X_VC[j].GoBitToN;
      assign GoBitToNIC[j] = VN_X_VC[j].GoBitToNIC;
      assign GoBitToE[j] =   VN_X_VC[j].GoBitToE;
      assign GoBitToS[j] =   VN_X_VC[j].GoBitToS;
      assign GoBitToW[j] =   VN_X_VC[j].GoBitToW;



    end
  endgenerate

  generate
    for (i=0; i<NUM_VN_X_VC; i=i+1)begin

      assign debug_signals_o[i*5 +: 5] = {VN_X_VC[i].REQ__FROM__IU_N__TO__RT_N,
                                          VN_X_VC[i].REQ__FROM__IU_E__TO__RT_E,
                                          VN_X_VC[i].REQ__FROM__IU_W__TO__RT_W,
                                          VN_X_VC[i].REQ__FROM__IU_S__TO__RT_S,
                                          VN_X_VC[i].REQ__FROM__IU_L__TO__RT_L};

     IBUFFER_VC  #(
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE_E              ),
     .QUEUE_SIZE         ( IB_QUEUE_SIZE            ),
     .SG_UPPER_THOLD     ( IB_SG_UPPER_THOLD        ),
     .SG_LOWER_THOLD     ( IB_SG_LOWER_THOLD        ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   )
     ) IBUFFER_EAST (
     .clk(clk),
     .rst_p(rst_p),
     .Flit( VN_X_VC[i].FlitFromE__FROM__SW__TO__IU_E[PHIT_SIZE_E-1:0]),
     .FlitType(VN_X_VC[i].FlitTypeFromE__FROM__SW__TO__IU_E[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlit(VN_X_VC[i].BroadcastFlitFromE__FROM__SW__TO__IU_E),
     .Valid(VN_X_VC[i].ValidBitFromE__FROM__SW__TO__IU_E),
     .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_E__TO__IU_E),
     .FlitOut(VN_X_VC[i].FLIT__FROM__IU_E__TO__RT_E[FLIT_SIZE-1:0]),
     .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__IU_E__TO__RT_E[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlitOut(VN_X_VC[i].BCFLIT__FROM__IU_E__TO__RT_E),
     .Go(VN_X_VC[i].GoBitToE),
     .Req_RT(VN_X_VC[i].REQ__FROM__IU_E__TO__RT_E));

     IBUFFER_VC #(
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE_L              ),
     .QUEUE_SIZE         ( IB_QUEUE_SIZE            ),
     .SG_UPPER_THOLD     ( IB_SG_UPPER_THOLD        ),
     .SG_LOWER_THOLD     ( IB_SG_LOWER_THOLD        ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   )
     ) IBUFFER_LOCAL (
     .clk(clk),
     .rst_p(rst_p),
     .Flit( VN_X_VC[i].FlitFromNI__FROM__SW__TO__IU_L[PHIT_SIZE_L-1:0]),
     .FlitType(VN_X_VC[i].FlitTypeFromNI__FROM__SW__TO__IU_L[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlit(VN_X_VC[i].BroadcastFlitFromNI__FROM__SW__TO__IU_L),
     .Valid(VN_X_VC[i].ValidBitFromNI__FROM__SW__TO__IU_L),
     .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_L__TO__IU_L),
     .FlitOut(VN_X_VC[i].FLIT__FROM__IU_L__TO__RT_L[FLIT_SIZE-1:0]),
     .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__IU_L__TO__RT_L[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlitOut(VN_X_VC[i].BCFLIT__FROM__IU_L__TO__RT_L),
     .Go(VN_X_VC[i].GoBitToNIC),
     .Req_RT(VN_X_VC[i].REQ__FROM__IU_L__TO__RT_L));

     IBUFFER_VC #(
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE_N              ),
     .QUEUE_SIZE         ( IB_QUEUE_SIZE            ),
     .SG_UPPER_THOLD     ( IB_SG_UPPER_THOLD        ),
     .SG_LOWER_THOLD     ( IB_SG_LOWER_THOLD        ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   )
     ) IBUFFER_NORTH (
     .clk(clk),
     .rst_p(rst_p),
     .Flit( VN_X_VC[i].FlitFromN__FROM__SW__TO__IU_N[PHIT_SIZE_N-1:0]),
     .FlitType(VN_X_VC[i].FlitTypeFromN__FROM__SW__TO__IU_N[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlit(VN_X_VC[i].BroadcastFlitFromN__FROM__SW__TO__IU_N),
     .Valid(VN_X_VC[i].ValidBitFromN__FROM__SW__TO__IU_N),
     .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_N__TO__IU_N),
     .FlitOut(VN_X_VC[i].FLIT__FROM__IU_N__TO__RT_N[FLIT_SIZE-1:0]),
     .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__IU_N__TO__RT_N[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlitOut(VN_X_VC[i].BCFLIT__FROM__IU_N__TO__RT_N),
     .Go(VN_X_VC[i].GoBitToN),
     .Req_RT(VN_X_VC[i].REQ__FROM__IU_N__TO__RT_N));

     IBUFFER_VC #(
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE_S              ),
     .QUEUE_SIZE         ( IB_QUEUE_SIZE            ),
     .SG_UPPER_THOLD     ( IB_SG_UPPER_THOLD        ),
     .SG_LOWER_THOLD     ( IB_SG_LOWER_THOLD        ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   )
     ) IBUFFER_SOUTH (
     .clk(clk),
     .rst_p(rst_p),
     .Flit( VN_X_VC[i].FlitFromS__FROM__SW__TO__IU_S[PHIT_SIZE_S-1:0]),
     .FlitType(VN_X_VC[i].FlitTypeFromS__FROM__SW__TO__IU_S[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlit(VN_X_VC[i].BroadcastFlitFromS__FROM__SW__TO__IU_S),
     .Valid(VN_X_VC[i].ValidBitFromS__FROM__SW__TO__IU_S),
     .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_S__TO__IU_S),
     .FlitOut(VN_X_VC[i].FLIT__FROM__IU_S__TO__RT_S[FLIT_SIZE-1:0]),
     .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__IU_S__TO__RT_S[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlitOut(VN_X_VC[i].BCFLIT__FROM__IU_S__TO__RT_S),
     .Go(VN_X_VC[i].GoBitToS),
     .Req_RT(VN_X_VC[i].REQ__FROM__IU_S__TO__RT_S));

     IBUFFER_VC #(
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE_W              ),
     .QUEUE_SIZE         ( IB_QUEUE_SIZE            ),
     .SG_UPPER_THOLD     ( IB_SG_UPPER_THOLD        ),
     .SG_LOWER_THOLD     ( IB_SG_LOWER_THOLD        ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   )
     ) IBUFFER_WEST  (
     .clk(clk),
     .rst_p(rst_p),
     .Flit( VN_X_VC[i].FlitFromW__FROM__SW__TO__IU_W[PHIT_SIZE_W-1:0]),
     .FlitType(VN_X_VC[i].FlitTypeFromW__FROM__SW__TO__IU_W[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlit(VN_X_VC[i].BroadcastFlitFromW__FROM__SW__TO__IU_W),
     .Valid(VN_X_VC[i].ValidBitFromW__FROM__SW__TO__IU_W),
     .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_W__TO__IU_W),
     .FlitOut(VN_X_VC[i].FLIT__FROM__IU_W__TO__RT_W[FLIT_SIZE-1:0]),
     .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__IU_W__TO__RT_W[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlitOut(VN_X_VC[i].BCFLIT__FROM__IU_W__TO__RT_W),
     .Go(VN_X_VC[i].GoBitToW),
     .Req_RT(VN_X_VC[i].REQ__FROM__IU_W__TO__RT_W));

     //TO FINALISE
     ROUTING_VC #(
    .FPGA_DIMX               ( FPGA_DIMX                         ),
    .FPGA_DIMY               ( FPGA_DIMY                         ),
    .FPGA_N_NxT              ( FPGA_N_NxT                        ),
    .FPGA_N_Nodes            ( FPGA_N_Nodes                      ),
    .FPGA_DIMX_w             ( FPGA_DIMX_w                       ),
    .FPGA_DIMY_w             ( FPGA_DIMY_w                       ),
    .FPGA_N_NxT_w            ( FPGA_N_NxT_w                      ),
    .FPGA_N_Nodes_w          ( FPGA_N_Nodes_w                    ),
    .FPGA_SWITCH_ID_w        ( FPGA_SWITCH_ID_w                  ),
    .GLBL_DIMX               ( GLBL_DIMX                         ),
    .GLBL_DIMY               ( GLBL_DIMY                         ),
    .GLBL_N_NxT              ( GLBL_N_NxT                        ),
    .GLBL_N_Nodes            ( GLBL_N_Nodes                      ),
    .GLBL_DIMX_w             ( GLBL_DIMX_w                       ),
    .GLBL_DIMY_w             ( GLBL_DIMY_w                       ),
    .GLBL_N_NxT_w            ( GLBL_N_NxT_w                      ),
    .GLBL_N_Nodes_w          ( GLBL_N_Nodes_w                    ),
    .GLBL_SWITCH_ID_w        ( GLBL_SWITCH_ID_w                  ),
    //
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .DATA_NET_FLIT_DST_UNIT_ID_LSB ( DATA_NET_FLIT_DST_UNIT_ID_LSB ),
    .DATA_NET_FLIT_DST_UNIT_ID_MSB ( DATA_NET_FLIT_DST_UNIT_ID_MSB )
  ) ROUTING_EAST (
    .clk(clk),
    .rst_p(rst_p),
    .Cur(ID[`SWITCH_ID_RANGE]),
    .Port(`PORT_E),
    .Req(VN_X_VC[i].REQ__FROM__IU_E__TO__RT_E),
    .Flit(VN_X_VC[i].FLIT__FROM__IU_E__TO__RT_E[FLIT_SIZE-1:0]),
    .FlitType(VN_X_VC[i].FLITTYPE__FROM__IU_E__TO__RT_E[FLIT_TYPE_SIZE-1:0]),
    .BroadcastFlit(VN_X_VC[i].BCFLIT__FROM__IU_E__TO__RT_E),
    .Grant_VA_FromN(VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_E),
    .Grant_VA_FromE(1'b0),
    .Grant_VA_FromW(VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_E),
    .Grant_VA_FromS(VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_E),
    .Grant_VA_FromL(VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_E),
    .Grant_SA_FromN(VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_E),
    .Grant_SA_FromE(1'b0),
    .Grant_SA_FromW(VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_E),
    .Grant_SA_FromS(VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_E),
    .Grant_SA_FromL(VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_E),
    .FlitOut(VN_X_VC[i].FLIT__FROM__RT_E__TO__O_ALL[FLIT_SIZE-1:0]),
    .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__RT_E__TO__O_ALL[FLIT_TYPE_SIZE-1:0]),
    .TailFlit(VN_X_VC[i].TAILFLIT__FROM__RT_E__TO__SA_ALL),
    .BroadcastFlitE(),
    .BroadcastFlitS(VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_S),
    .BroadcastFlitW(VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_W),
    .BroadcastFlitN(VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_N),
    .BroadcastFlitL(VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_L),
    .Request_VA_E(),
    .Request_VA_L(VN_X_VC[i].REQ__FROM__RT_E__TO__VA_L),
    .Request_VA_N(VN_X_VC[i].REQ__FROM__RT_E__TO__VA_N),
    .Request_VA_S(VN_X_VC[i].REQ__FROM__RT_E__TO__VA_S),
    .Request_VA_W(VN_X_VC[i].REQ__FROM__RT_E__TO__VA_W),
    .Request_SA_E(),
    .Request_SA_L(VN_X_VC[i].REQ__FROM__RT_E__TO__SA_L),
    .Request_SA_N(VN_X_VC[i].REQ__FROM__RT_E__TO__SA_N),
    .Request_SA_S(VN_X_VC[i].REQ__FROM__RT_E__TO__SA_S),
    .Request_SA_W(VN_X_VC[i].REQ__FROM__RT_E__TO__SA_W),
    .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_E__TO__IU_E));

     ROUTING_VC #(
    .FPGA_DIMX               ( FPGA_DIMX                         ),
    .FPGA_DIMY               ( FPGA_DIMY                         ),
    .FPGA_N_NxT              ( FPGA_N_NxT                        ),
    .FPGA_N_Nodes            ( FPGA_N_Nodes                      ),
    .FPGA_DIMX_w             ( FPGA_DIMX_w                       ),
    .FPGA_DIMY_w             ( FPGA_DIMY_w                       ),
    .FPGA_N_NxT_w            ( FPGA_N_NxT_w                      ),
    .FPGA_N_Nodes_w          ( FPGA_N_Nodes_w                    ),
    .FPGA_SWITCH_ID_w        ( FPGA_SWITCH_ID_w                  ),
    .GLBL_DIMX               ( GLBL_DIMX                         ),
    .GLBL_DIMY               ( GLBL_DIMY                         ),
    .GLBL_N_NxT              ( GLBL_N_NxT                        ),
    .GLBL_N_Nodes            ( GLBL_N_Nodes                      ),
    .GLBL_DIMX_w             ( GLBL_DIMX_w                       ),
    .GLBL_DIMY_w             ( GLBL_DIMY_w                       ),
    .GLBL_N_NxT_w            ( GLBL_N_NxT_w                      ),
    .GLBL_N_Nodes_w          ( GLBL_N_Nodes_w                    ),
    .GLBL_SWITCH_ID_w        ( GLBL_SWITCH_ID_w                  ),
    //
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .DATA_NET_FLIT_DST_UNIT_ID_LSB ( DATA_NET_FLIT_DST_UNIT_ID_LSB ),
    .DATA_NET_FLIT_DST_UNIT_ID_MSB ( DATA_NET_FLIT_DST_UNIT_ID_MSB )
  ) ROUTING_LOCAL (
    .clk(clk),
    .rst_p(rst_p),
    .Cur(ID[`SWITCH_ID_RANGE]),
    .Port(`PORT_L),
    .Req(VN_X_VC[i].REQ__FROM__IU_L__TO__RT_L),
    .Flit(VN_X_VC[i].FLIT__FROM__IU_L__TO__RT_L[FLIT_SIZE-1:0]),
    .FlitType(VN_X_VC[i].FLITTYPE__FROM__IU_L__TO__RT_L[FLIT_TYPE_SIZE-1:0]),
    .BroadcastFlit(VN_X_VC[i].BCFLIT__FROM__IU_L__TO__RT_L),
    .Grant_VA_FromN(VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_L),
    .Grant_VA_FromE(VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_L),
    .Grant_VA_FromW(VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_L),
    .Grant_VA_FromS(VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_L),
    .Grant_VA_FromL(1'b0),
    .Grant_SA_FromN(VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_L),
    .Grant_SA_FromE(VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_L),
    .Grant_SA_FromW(VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_L),
    .Grant_SA_FromS(VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_L),
    .Grant_SA_FromL(1'b0),
    .FlitOut(VN_X_VC[i].FLIT__FROM__RT_L__TO__O_ALL[FLIT_SIZE-1:0]),
    .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__RT_L__TO__O_ALL[FLIT_TYPE_SIZE-1:0]),
    .TailFlit(VN_X_VC[i].TAILFLIT__FROM__RT_L__TO__SA_ALL),
    .BroadcastFlitE(VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_E),
    .BroadcastFlitS(VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_S),
    .BroadcastFlitW(VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_W),
    .BroadcastFlitN(VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_N),
    .BroadcastFlitL(),
    .Request_VA_E(VN_X_VC[i].REQ__FROM__RT_L__TO__VA_E),
    .Request_VA_L(),
    .Request_VA_N(VN_X_VC[i].REQ__FROM__RT_L__TO__VA_N),
    .Request_VA_S(VN_X_VC[i].REQ__FROM__RT_L__TO__VA_S),
    .Request_VA_W(VN_X_VC[i].REQ__FROM__RT_L__TO__VA_W),
    .Request_SA_E(VN_X_VC[i].REQ__FROM__RT_L__TO__SA_E),
    .Request_SA_L(),
    .Request_SA_N(VN_X_VC[i].REQ__FROM__RT_L__TO__SA_N),
    .Request_SA_S(VN_X_VC[i].REQ__FROM__RT_L__TO__SA_S),
    .Request_SA_W(VN_X_VC[i].REQ__FROM__RT_L__TO__SA_W),
    .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_L__TO__IU_L));

     ROUTING_VC #(
    .FPGA_DIMX               ( FPGA_DIMX                         ),
    .FPGA_DIMY               ( FPGA_DIMY                         ),
    .FPGA_N_NxT              ( FPGA_N_NxT                        ),
    .FPGA_N_Nodes            ( FPGA_N_Nodes                      ),
    .FPGA_DIMX_w             ( FPGA_DIMX_w                       ),
    .FPGA_DIMY_w             ( FPGA_DIMY_w                       ),
    .FPGA_N_NxT_w            ( FPGA_N_NxT_w                      ),
    .FPGA_N_Nodes_w          ( FPGA_N_Nodes_w                    ),
    .FPGA_SWITCH_ID_w        ( FPGA_SWITCH_ID_w                  ),
    .GLBL_DIMX               ( GLBL_DIMX                         ),
    .GLBL_DIMY               ( GLBL_DIMY                         ),
    .GLBL_N_NxT              ( GLBL_N_NxT                        ),
    .GLBL_N_Nodes            ( GLBL_N_Nodes                      ),
    .GLBL_DIMX_w             ( GLBL_DIMX_w                       ),
    .GLBL_DIMY_w             ( GLBL_DIMY_w                       ),
    .GLBL_N_NxT_w            ( GLBL_N_NxT_w                      ),
    .GLBL_N_Nodes_w          ( GLBL_N_Nodes_w                    ),
    .GLBL_SWITCH_ID_w        ( GLBL_SWITCH_ID_w                  ),
    //
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .DATA_NET_FLIT_DST_UNIT_ID_LSB ( DATA_NET_FLIT_DST_UNIT_ID_LSB ),
    .DATA_NET_FLIT_DST_UNIT_ID_MSB ( DATA_NET_FLIT_DST_UNIT_ID_MSB )
  ) ROUTING_NORTH (
    .clk(clk),
    .rst_p(rst_p),
    .Cur(ID[`SWITCH_ID_RANGE]),
    .Port(`PORT_N),
    .Req(VN_X_VC[i].REQ__FROM__IU_N__TO__RT_N),
    .Flit(VN_X_VC[i].FLIT__FROM__IU_N__TO__RT_N[FLIT_SIZE-1:0]),
    .FlitType(VN_X_VC[i].FLITTYPE__FROM__IU_N__TO__RT_N[FLIT_TYPE_SIZE-1:0]),
    .BroadcastFlit(VN_X_VC[i].BCFLIT__FROM__IU_N__TO__RT_N),
    .Grant_VA_FromN(1'b0),
    .Grant_VA_FromE(VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_N),
    .Grant_VA_FromW(VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_N),
    .Grant_VA_FromS(VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_N),
    .Grant_VA_FromL(VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_N),
    .Grant_SA_FromN(1'b0),
    .Grant_SA_FromE(VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_N),
    .Grant_SA_FromW(VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_N),
    .Grant_SA_FromS(VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_N),
    .Grant_SA_FromL(VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_N),
    .FlitOut(VN_X_VC[i].FLIT__FROM__RT_N__TO__O_ALL[FLIT_SIZE-1:0]),
    .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__RT_N__TO__O_ALL[FLIT_TYPE_SIZE-1:0]),
    .TailFlit(VN_X_VC[i].TAILFLIT__FROM__RT_N__TO__SA_ALL),
    .BroadcastFlitE(VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_E),
    .BroadcastFlitS(VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_S),
    .BroadcastFlitW(VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_W),
    .BroadcastFlitN(),
    .BroadcastFlitL(VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_L),
    .Request_VA_E(VN_X_VC[i].REQ__FROM__RT_N__TO__VA_E),
    .Request_VA_L(VN_X_VC[i].REQ__FROM__RT_N__TO__VA_L),
    .Request_VA_N(),
    .Request_VA_S(VN_X_VC[i].REQ__FROM__RT_N__TO__VA_S),
    .Request_VA_W(VN_X_VC[i].REQ__FROM__RT_N__TO__VA_W),
    .Request_SA_E(VN_X_VC[i].REQ__FROM__RT_N__TO__SA_E),
    .Request_SA_L(VN_X_VC[i].REQ__FROM__RT_N__TO__SA_L),
    .Request_SA_N(),
    .Request_SA_S(VN_X_VC[i].REQ__FROM__RT_N__TO__SA_S),
    .Request_SA_W(VN_X_VC[i].REQ__FROM__RT_N__TO__SA_W),
    .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_N__TO__IU_N));


     ROUTING_VC #(
    .FPGA_DIMX               ( FPGA_DIMX                         ),
    .FPGA_DIMY               ( FPGA_DIMY                         ),
    .FPGA_N_NxT              ( FPGA_N_NxT                        ),
    .FPGA_N_Nodes            ( FPGA_N_Nodes                      ),
    .FPGA_DIMX_w             ( FPGA_DIMX_w                       ),
    .FPGA_DIMY_w             ( FPGA_DIMY_w                       ),
    .FPGA_N_NxT_w            ( FPGA_N_NxT_w                      ),
    .FPGA_N_Nodes_w          ( FPGA_N_Nodes_w                    ),
    .FPGA_SWITCH_ID_w        ( FPGA_SWITCH_ID_w                  ),
    .GLBL_DIMX               ( GLBL_DIMX                         ),
    .GLBL_DIMY               ( GLBL_DIMY                         ),
    .GLBL_N_NxT              ( GLBL_N_NxT                        ),
    .GLBL_N_Nodes            ( GLBL_N_Nodes                      ),
    .GLBL_DIMX_w             ( GLBL_DIMX_w                       ),
    .GLBL_DIMY_w             ( GLBL_DIMY_w                       ),
    .GLBL_N_NxT_w            ( GLBL_N_NxT_w                      ),
    .GLBL_N_Nodes_w          ( GLBL_N_Nodes_w                    ),
    .GLBL_SWITCH_ID_w        ( GLBL_SWITCH_ID_w                  ),
    //
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .DATA_NET_FLIT_DST_UNIT_ID_LSB ( DATA_NET_FLIT_DST_UNIT_ID_LSB ),
    .DATA_NET_FLIT_DST_UNIT_ID_MSB ( DATA_NET_FLIT_DST_UNIT_ID_MSB )
  ) ROUTING_SOUTH (
    .clk(clk),
    .rst_p(rst_p),
    .Cur(ID[`SWITCH_ID_RANGE]),
    .Port(`PORT_S),
    .Req(VN_X_VC[i].REQ__FROM__IU_S__TO__RT_S),
    .Flit(VN_X_VC[i].FLIT__FROM__IU_S__TO__RT_S[FLIT_SIZE-1:0]),
    .FlitType(VN_X_VC[i].FLITTYPE__FROM__IU_S__TO__RT_S[FLIT_TYPE_SIZE-1:0]),
    .BroadcastFlit(VN_X_VC[i].BCFLIT__FROM__IU_S__TO__RT_S),
    .Grant_VA_FromN(VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_S),
    .Grant_VA_FromE(VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_S),
    .Grant_VA_FromW(VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_S),
    .Grant_VA_FromS(1'b0),
    .Grant_VA_FromL(VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_S),
    .Grant_SA_FromN(VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_S),
    .Grant_SA_FromE(VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_S),
    .Grant_SA_FromW(VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_S),
    .Grant_SA_FromS(1'b0),
    .Grant_SA_FromL(VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_S),
    .FlitOut(VN_X_VC[i].FLIT__FROM__RT_S__TO__O_ALL[FLIT_SIZE-1:0]),
    .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__RT_S__TO__O_ALL[FLIT_TYPE_SIZE-1:0]),
    .TailFlit(VN_X_VC[i].TAILFLIT__FROM__RT_S__TO__SA_ALL),
    .BroadcastFlitE(VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_E),
    .BroadcastFlitS(),
    .BroadcastFlitW(VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_W),
    .BroadcastFlitN(VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_N),
    .BroadcastFlitL(VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_L),
    .Request_VA_E(VN_X_VC[i].REQ__FROM__RT_S__TO__VA_E),
    .Request_VA_L(VN_X_VC[i].REQ__FROM__RT_S__TO__VA_L),
    .Request_VA_N(VN_X_VC[i].REQ__FROM__RT_S__TO__VA_N),
    .Request_VA_S(),
    .Request_VA_W(VN_X_VC[i].REQ__FROM__RT_S__TO__VA_W),
    .Request_SA_E(VN_X_VC[i].REQ__FROM__RT_S__TO__SA_E),
    .Request_SA_L(VN_X_VC[i].REQ__FROM__RT_S__TO__SA_L),
    .Request_SA_N(VN_X_VC[i].REQ__FROM__RT_S__TO__SA_N),
    .Request_SA_S(),
    .Request_SA_W(VN_X_VC[i].REQ__FROM__RT_S__TO__SA_W),
    .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_S__TO__IU_S));

     ROUTING_VC #(
    .FPGA_DIMX               ( FPGA_DIMX                         ),
    .FPGA_DIMY               ( FPGA_DIMY                         ),
    .FPGA_N_NxT              ( FPGA_N_NxT                        ),
    .FPGA_N_Nodes            ( FPGA_N_Nodes                      ),
    .FPGA_DIMX_w             ( FPGA_DIMX_w                       ),
    .FPGA_DIMY_w             ( FPGA_DIMY_w                       ),
    .FPGA_N_NxT_w            ( FPGA_N_NxT_w                      ),
    .FPGA_N_Nodes_w          ( FPGA_N_Nodes_w                    ),
    .FPGA_SWITCH_ID_w        ( FPGA_SWITCH_ID_w                  ),
    .GLBL_DIMX               ( GLBL_DIMX                         ),
    .GLBL_DIMY               ( GLBL_DIMY                         ),
    .GLBL_N_NxT              ( GLBL_N_NxT                        ),
    .GLBL_N_Nodes            ( GLBL_N_Nodes                      ),
    .GLBL_DIMX_w             ( GLBL_DIMX_w                       ),
    .GLBL_DIMY_w             ( GLBL_DIMY_w                       ),
    .GLBL_N_NxT_w            ( GLBL_N_NxT_w                      ),
    .GLBL_N_Nodes_w          ( GLBL_N_Nodes_w                    ),
    .GLBL_SWITCH_ID_w        ( GLBL_SWITCH_ID_w                  ),
    //
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .DATA_NET_FLIT_DST_UNIT_ID_LSB ( DATA_NET_FLIT_DST_UNIT_ID_LSB ),
    .DATA_NET_FLIT_DST_UNIT_ID_MSB ( DATA_NET_FLIT_DST_UNIT_ID_MSB )
  ) ROUTING_WEST  (
    .clk(clk),
    .rst_p(rst_p),
    .Cur(ID[`SWITCH_ID_RANGE]),
    .Port(`PORT_W),
    .Req(VN_X_VC[i].REQ__FROM__IU_W__TO__RT_W),
    .Flit(VN_X_VC[i].FLIT__FROM__IU_W__TO__RT_W[FLIT_SIZE-1:0]),
    .FlitType(VN_X_VC[i].FLITTYPE__FROM__IU_W__TO__RT_W[FLIT_TYPE_SIZE-1:0]),
    .BroadcastFlit(VN_X_VC[i].BCFLIT__FROM__IU_W__TO__RT_W),
    .Grant_VA_FromN(VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_W),
    .Grant_VA_FromE(VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_W),
    .Grant_VA_FromW(1'b0),
    .Grant_VA_FromS(VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_W),
    .Grant_VA_FromL(VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_W),
    .Grant_SA_FromN(VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_W),
    .Grant_SA_FromE(VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_W),
    .Grant_SA_FromW(1'b0),
    .Grant_SA_FromS(VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_W),
    .Grant_SA_FromL(VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_W),
    .FlitOut(VN_X_VC[i].FLIT__FROM__RT_W__TO__O_ALL[FLIT_SIZE-1:0]),
    .FlitTypeOut(VN_X_VC[i].FLITTYPE__FROM__RT_W__TO__O_ALL[FLIT_TYPE_SIZE-1:0]),
    .TailFlit(VN_X_VC[i].TAILFLIT__FROM__RT_W__TO__SA_ALL),
    .BroadcastFlitE(VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_E),
    .BroadcastFlitS(VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_S),
    .BroadcastFlitW(),
    .BroadcastFlitN(VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_N),
    .BroadcastFlitL(VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_L),
    .Request_VA_E(VN_X_VC[i].REQ__FROM__RT_W__TO__VA_E),
    .Request_VA_L(VN_X_VC[i].REQ__FROM__RT_W__TO__VA_L),
    .Request_VA_N(VN_X_VC[i].REQ__FROM__RT_W__TO__VA_N),
    .Request_VA_S(VN_X_VC[i].REQ__FROM__RT_W__TO__VA_S),
    .Request_VA_W(),
    .Request_SA_E(VN_X_VC[i].REQ__FROM__RT_W__TO__SA_E),
    .Request_SA_L(VN_X_VC[i].REQ__FROM__RT_W__TO__SA_L),
    .Request_SA_N(VN_X_VC[i].REQ__FROM__RT_W__TO__SA_N),
    .Request_SA_S(VN_X_VC[i].REQ__FROM__RT_W__TO__SA_S),
    .Request_SA_W(),
    .Avail(VN_X_VC[i].RT_READYFORREQ__FROM__RT_W__TO__IU_W));
    end //end for
    endgenerate

//wires to connect Output to SA
wire GOPHIT__FROM_O_E__TO__SA_E;
wire GOPHIT__FROM_O_L__TO__SA_L;
wire GOPHIT__FROM_O_N__TO__SA_N;
wire GOPHIT__FROM_O_S__TO__SA_S;
wire GOPHIT__FROM_O_W__TO__SA_W;
                                                    //Vector wires to connect SA and grup each signal of multiple VN_X_VC in one.
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__SA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__SA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__SA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__SA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__SA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__SA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__SA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__SA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__SA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__SA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__SA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__SA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__SA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__SA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__SA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__SA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__SA_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__SA_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__SA_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__SA_W;

wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_E__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_E__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_E__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_E__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_E__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_L__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_L__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_L__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_L__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_L__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_N__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_N__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_N__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_N__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_N__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_S__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_S__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_S__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_S__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_S__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_W__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_W__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_W__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_W__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__SA_W__TO__RT_W;


                                                          //Vector wires to connect VA and grup each signal of multiple VN_X_VC in one.
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__VA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__VA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__VA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__VA_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__VA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__VA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__VA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__VA_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__VA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__VA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__VA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__VA_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__VA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_W__TO__VA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__VA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__VA_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_S__TO__VA_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_E__TO__VA_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_N__TO__VA_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_REQ__FROM__RT_L__TO__VA_W;

wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_E__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_E__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_E__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_E__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_E__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_L__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_L__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_L__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_L__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_L__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_N__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_N__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_N__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_N__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_N__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_S__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_S__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_S__TO__RT_W;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_S__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_S__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_W__TO__RT_S;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_W__TO__RT_E;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_W__TO__RT_N;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_W__TO__RT_L;
wire [NUM_VN_X_VC-1 : 0] VECTOR_GRANT__FROM__VA_W__TO__RT_W;



                                                          //Vector wires to connect RT to OUTPUT signals for each signal of multiple VN_X_VC in one.
wire [FLIT_SIZE_VC-1:0] VECTOR_FLIT__FROM__RT_E__TO__O_ALL;
wire [FLIT_SIZE_VC-1:0] VECTOR_FLIT__FROM__RT_L__TO__O_ALL;
wire [FLIT_SIZE_VC-1:0] VECTOR_FLIT__FROM__RT_N__TO__O_ALL;
wire [FLIT_SIZE_VC-1:0] VECTOR_FLIT__FROM__RT_S__TO__O_ALL;
wire [FLIT_SIZE_VC-1:0] VECTOR_FLIT__FROM__RT_W__TO__O_ALL;
wire [FLIT_TYPE_SIZE_VC-1:0] VECTOR_FLITTYPE__FROM__RT_E__TO__O_ALL;
wire [FLIT_TYPE_SIZE_VC-1:0] VECTOR_FLITTYPE__FROM__RT_L__TO__O_ALL;
wire [FLIT_TYPE_SIZE_VC-1:0] VECTOR_FLITTYPE__FROM__RT_N__TO__O_ALL;
wire [FLIT_TYPE_SIZE_VC-1:0] VECTOR_FLITTYPE__FROM__RT_S__TO__O_ALL;
wire [FLIT_TYPE_SIZE_VC-1:0] VECTOR_FLITTYPE__FROM__RT_W__TO__O_ALL;

 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_E__TO__O_N;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_E__TO__O_S;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_E__TO__O_W;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_E__TO__O_L;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_L__TO__O_E;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_L__TO__O_N;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_L__TO__O_S;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_L__TO__O_W;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_N__TO__O_E;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_N__TO__O_S;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_N__TO__O_W;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_N__TO__O_L;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_S__TO__O_E;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_S__TO__O_N;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_S__TO__O_W;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_S__TO__O_L;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_W__TO__O_E;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_W__TO__O_N;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_W__TO__O_S;
 wire [NUM_VN_X_VC-1:0] VECTOR_BCFLIT__FROM__RT_W__TO__O_L;


for (i=0; i<NUM_VN_X_VC; i=i+1) begin

//we assign the wire values from each VN_X_VC in the vectors
 assign VECTOR_REQ__FROM__RT_S__TO__SA_E[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__SA_E;
 assign VECTOR_REQ__FROM__RT_W__TO__SA_E[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__SA_E;
 assign VECTOR_REQ__FROM__RT_N__TO__SA_E[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__SA_E;
 assign VECTOR_REQ__FROM__RT_L__TO__SA_E[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__SA_E;
 assign VECTOR_REQ__FROM__RT_S__TO__SA_L[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__SA_L;
 assign VECTOR_REQ__FROM__RT_W__TO__SA_L[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__SA_L;
 assign VECTOR_REQ__FROM__RT_N__TO__SA_L[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__SA_L;
 assign VECTOR_REQ__FROM__RT_E__TO__SA_L[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__SA_L;
 assign VECTOR_REQ__FROM__RT_S__TO__SA_N[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__SA_N;
 assign VECTOR_REQ__FROM__RT_W__TO__SA_N[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__SA_N;
 assign VECTOR_REQ__FROM__RT_E__TO__SA_N[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__SA_N;
 assign VECTOR_REQ__FROM__RT_L__TO__SA_N[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__SA_N;
 assign VECTOR_REQ__FROM__RT_E__TO__SA_S[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__SA_S;
 assign VECTOR_REQ__FROM__RT_W__TO__SA_S[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__SA_S;
 assign VECTOR_REQ__FROM__RT_N__TO__SA_S[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__SA_S;
 assign VECTOR_REQ__FROM__RT_L__TO__SA_S[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__SA_S;
 assign VECTOR_REQ__FROM__RT_S__TO__SA_W[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__SA_W;
 assign VECTOR_REQ__FROM__RT_E__TO__SA_W[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__SA_W;
 assign VECTOR_REQ__FROM__RT_N__TO__SA_W[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__SA_W;
 assign VECTOR_REQ__FROM__RT_L__TO__SA_W[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__SA_W;

 assign VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_S = VECTOR_GRANT__FROM__SA_E__TO__RT_S[i];
 assign VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_W = VECTOR_GRANT__FROM__SA_E__TO__RT_W[i];
 assign VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_N = VECTOR_GRANT__FROM__SA_E__TO__RT_N[i];
 assign VN_X_VC[i].GRANT__FROM__SA_E__TO__RT_L = VECTOR_GRANT__FROM__SA_E__TO__RT_L[i];
 assign VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_S = VECTOR_GRANT__FROM__SA_L__TO__RT_S[i];
 assign VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_W = VECTOR_GRANT__FROM__SA_L__TO__RT_W[i];
 assign VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_N = VECTOR_GRANT__FROM__SA_L__TO__RT_N[i];
 assign VN_X_VC[i].GRANT__FROM__SA_L__TO__RT_E = VECTOR_GRANT__FROM__SA_L__TO__RT_E[i];
 assign VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_S = VECTOR_GRANT__FROM__SA_N__TO__RT_S[i];
 assign VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_W = VECTOR_GRANT__FROM__SA_N__TO__RT_W[i];
 assign VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_E = VECTOR_GRANT__FROM__SA_N__TO__RT_E[i];
 assign VN_X_VC[i].GRANT__FROM__SA_N__TO__RT_L = VECTOR_GRANT__FROM__SA_N__TO__RT_L[i];
 assign VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_E = VECTOR_GRANT__FROM__SA_S__TO__RT_E[i];
 assign VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_W = VECTOR_GRANT__FROM__SA_S__TO__RT_W[i];
 assign VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_N = VECTOR_GRANT__FROM__SA_S__TO__RT_N[i];
 assign VN_X_VC[i].GRANT__FROM__SA_S__TO__RT_L = VECTOR_GRANT__FROM__SA_S__TO__RT_L[i];
 assign VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_S = VECTOR_GRANT__FROM__SA_W__TO__RT_S[i];
 assign VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_E = VECTOR_GRANT__FROM__SA_W__TO__RT_E[i];
 assign VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_N = VECTOR_GRANT__FROM__SA_W__TO__RT_N[i];
 assign VN_X_VC[i].GRANT__FROM__SA_W__TO__RT_L = VECTOR_GRANT__FROM__SA_W__TO__RT_L[i];

 assign VECTOR_REQ__FROM__RT_S__TO__VA_E[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__VA_E;
 assign VECTOR_REQ__FROM__RT_W__TO__VA_E[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__VA_E;
 assign VECTOR_REQ__FROM__RT_N__TO__VA_E[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__VA_E;
 assign VECTOR_REQ__FROM__RT_L__TO__VA_E[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__VA_E;
 assign VECTOR_REQ__FROM__RT_S__TO__VA_L[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__VA_L;
 assign VECTOR_REQ__FROM__RT_W__TO__VA_L[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__VA_L;
 assign VECTOR_REQ__FROM__RT_N__TO__VA_L[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__VA_L;
 assign VECTOR_REQ__FROM__RT_E__TO__VA_L[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__VA_L;
 assign VECTOR_REQ__FROM__RT_S__TO__VA_N[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__VA_N;
 assign VECTOR_REQ__FROM__RT_W__TO__VA_N[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__VA_N;
 assign VECTOR_REQ__FROM__RT_E__TO__VA_N[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__VA_N;
 assign VECTOR_REQ__FROM__RT_L__TO__VA_N[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__VA_N;
 assign VECTOR_REQ__FROM__RT_E__TO__VA_S[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__VA_S;
 assign VECTOR_REQ__FROM__RT_W__TO__VA_S[i] = VN_X_VC[i].REQ__FROM__RT_W__TO__VA_S;
 assign VECTOR_REQ__FROM__RT_N__TO__VA_S[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__VA_S;
 assign VECTOR_REQ__FROM__RT_L__TO__VA_S[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__VA_S;
 assign VECTOR_REQ__FROM__RT_S__TO__VA_W[i] = VN_X_VC[i].REQ__FROM__RT_S__TO__VA_W;
 assign VECTOR_REQ__FROM__RT_E__TO__VA_W[i] = VN_X_VC[i].REQ__FROM__RT_E__TO__VA_W;
 assign VECTOR_REQ__FROM__RT_N__TO__VA_W[i] = VN_X_VC[i].REQ__FROM__RT_N__TO__VA_W;
 assign VECTOR_REQ__FROM__RT_L__TO__VA_W[i] = VN_X_VC[i].REQ__FROM__RT_L__TO__VA_W;


 assign  VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_S = VECTOR_GRANT__FROM__VA_E__TO__RT_S[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_W = VECTOR_GRANT__FROM__VA_E__TO__RT_W[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_N = VECTOR_GRANT__FROM__VA_E__TO__RT_N[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_E__TO__RT_L = VECTOR_GRANT__FROM__VA_E__TO__RT_L[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_S = VECTOR_GRANT__FROM__VA_L__TO__RT_S[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_W = VECTOR_GRANT__FROM__VA_L__TO__RT_W[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_N = VECTOR_GRANT__FROM__VA_L__TO__RT_N[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_L__TO__RT_E = VECTOR_GRANT__FROM__VA_L__TO__RT_E[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_S = VECTOR_GRANT__FROM__VA_N__TO__RT_S[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_W = VECTOR_GRANT__FROM__VA_N__TO__RT_W[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_E = VECTOR_GRANT__FROM__VA_N__TO__RT_E[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_N__TO__RT_L = VECTOR_GRANT__FROM__VA_N__TO__RT_L[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_E = VECTOR_GRANT__FROM__VA_S__TO__RT_E[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_W = VECTOR_GRANT__FROM__VA_S__TO__RT_W[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_N = VECTOR_GRANT__FROM__VA_S__TO__RT_N[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_S__TO__RT_L = VECTOR_GRANT__FROM__VA_S__TO__RT_L[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_S = VECTOR_GRANT__FROM__VA_W__TO__RT_S[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_E = VECTOR_GRANT__FROM__VA_W__TO__RT_E[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_N = VECTOR_GRANT__FROM__VA_W__TO__RT_N[i];
 assign  VN_X_VC[i].GRANT__FROM__VA_W__TO__RT_L = VECTOR_GRANT__FROM__VA_W__TO__RT_L[i];

assign VECTOR_FLIT__FROM__RT_E__TO__O_ALL[(i*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] = VN_X_VC[i].FLIT__FROM__RT_E__TO__O_ALL;
assign VECTOR_FLIT__FROM__RT_L__TO__O_ALL[(i*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] = VN_X_VC[i].FLIT__FROM__RT_L__TO__O_ALL;
assign VECTOR_FLIT__FROM__RT_N__TO__O_ALL[(i*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] = VN_X_VC[i].FLIT__FROM__RT_N__TO__O_ALL;
assign VECTOR_FLIT__FROM__RT_S__TO__O_ALL[(i*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] = VN_X_VC[i].FLIT__FROM__RT_S__TO__O_ALL;
assign VECTOR_FLIT__FROM__RT_W__TO__O_ALL[(i*FLIT_SIZE+(FLIT_SIZE-1))-:FLIT_SIZE] = VN_X_VC[i].FLIT__FROM__RT_W__TO__O_ALL;
assign VECTOR_FLITTYPE__FROM__RT_E__TO__O_ALL[(i*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] = VN_X_VC[i].FLITTYPE__FROM__RT_E__TO__O_ALL;
assign VECTOR_FLITTYPE__FROM__RT_L__TO__O_ALL[(i*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] = VN_X_VC[i].FLITTYPE__FROM__RT_L__TO__O_ALL;
assign VECTOR_FLITTYPE__FROM__RT_N__TO__O_ALL[(i*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] = VN_X_VC[i].FLITTYPE__FROM__RT_N__TO__O_ALL;
assign VECTOR_FLITTYPE__FROM__RT_S__TO__O_ALL[(i*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] = VN_X_VC[i].FLITTYPE__FROM__RT_S__TO__O_ALL;
assign VECTOR_FLITTYPE__FROM__RT_W__TO__O_ALL[(i*FLIT_TYPE_SIZE+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE] = VN_X_VC[i].FLITTYPE__FROM__RT_W__TO__O_ALL;

 assign VECTOR_BCFLIT__FROM__RT_E__TO__O_N[i] = VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_N;
 assign VECTOR_BCFLIT__FROM__RT_E__TO__O_S[i] = VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_S;
 assign VECTOR_BCFLIT__FROM__RT_E__TO__O_W[i] = VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_W;
 assign VECTOR_BCFLIT__FROM__RT_E__TO__O_L[i] = VN_X_VC[i].BCFLIT__FROM__RT_E__TO__O_L;
 assign VECTOR_BCFLIT__FROM__RT_L__TO__O_E[i] = VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_E;
 assign VECTOR_BCFLIT__FROM__RT_L__TO__O_N[i] = VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_N;
 assign VECTOR_BCFLIT__FROM__RT_L__TO__O_S[i] = VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_S;
 assign VECTOR_BCFLIT__FROM__RT_L__TO__O_W[i] = VN_X_VC[i].BCFLIT__FROM__RT_L__TO__O_W;
 assign VECTOR_BCFLIT__FROM__RT_N__TO__O_E[i] = VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_E;
 assign VECTOR_BCFLIT__FROM__RT_N__TO__O_S[i] = VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_S;
 assign VECTOR_BCFLIT__FROM__RT_N__TO__O_W[i] = VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_W;
 assign VECTOR_BCFLIT__FROM__RT_N__TO__O_L[i] = VN_X_VC[i].BCFLIT__FROM__RT_N__TO__O_L;
 assign VECTOR_BCFLIT__FROM__RT_S__TO__O_E[i] = VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_E;
 assign VECTOR_BCFLIT__FROM__RT_S__TO__O_N[i] = VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_N;
 assign VECTOR_BCFLIT__FROM__RT_S__TO__O_W[i] = VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_W;
 assign VECTOR_BCFLIT__FROM__RT_S__TO__O_L[i] = VN_X_VC[i].BCFLIT__FROM__RT_S__TO__O_L;
 assign VECTOR_BCFLIT__FROM__RT_W__TO__O_E[i] = VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_E;
 assign VECTOR_BCFLIT__FROM__RT_W__TO__O_N[i] = VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_N;
 assign VECTOR_BCFLIT__FROM__RT_W__TO__O_S[i] = VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_S;
 assign VECTOR_BCFLIT__FROM__RT_W__TO__O_L[i] = VN_X_VC[i].BCFLIT__FROM__RT_W__TO__O_L;

end //end for

wire FREE_VC__FROM_O_E__TO__VA_E;
wire FREE_VC__FROM_O_L__TO__VA_L;
wire FREE_VC__FROM_O_N__TO__VA_N;
wire FREE_VC__FROM_O_S__TO__VA_S;
wire FREE_VC__FROM_O_W__TO__VA_W;

wire [bits_VN_X_VC-1:0] VC_TO_RELEASE__FROM_O_N__TO__VA_N;
wire [bits_VN_X_VC-1:0] VC_TO_RELEASE__FROM_O_E__TO__VA_E;
wire [bits_VN_X_VC-1:0] VC_TO_RELEASE__FROM_O_W__TO__VA_W;
wire [bits_VN_X_VC-1:0] VC_TO_RELEASE__FROM_O_S__TO__VA_S;
wire [bits_VN_X_VC-1:0] VC_TO_RELEASE__FROM_O_L__TO__VA_L;

wire [long_VC_assigns-1:0] VC_ASSIGNS__FROM_VA_E__TO__SA_E;
wire [long_VC_assigns-1:0] VC_ASSIGNS__FROM_VA_S__TO__SA_S;
wire [long_VC_assigns-1:0] VC_ASSIGNS__FROM_VA_W__TO__SA_W;
wire [long_VC_assigns-1:0] VC_ASSIGNS__FROM_VA_N__TO__SA_N;
wire [long_VC_assigns-1:0] VC_ASSIGNS__FROM_VA_L__TO__SA_L;

wire [bits_VN_X_VC-1:0] VC_SELECTED__FROM_SA_E__TO__O_E;
wire [bits_VN_X_VC-1:0] VC_SELECTED__FROM_SA_S__TO__O_S;
wire [bits_VN_X_VC-1:0] VC_SELECTED__FROM_SA_W__TO__O_W;
wire [bits_VN_X_VC-1:0] VC_SELECTED__FROM_SA_N__TO__O_N;
wire [bits_VN_X_VC-1:0] VC_SELECTED__FROM_SA_L__TO__O_L;


for (j=0; j<NUM_VN; j=j+1) begin

   `ifdef VC_STATIC_WAY   VA_STATIC
   `elsif VC_DYNAMIC_WAY  VA_DYNAMIC
   `else                  VA_DYNAMIC `endif
  #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            ),
    .VN_WEIGHT_VECTOR_w      ( VN_WEIGHT_VECTOR_w                )
  ) VA_EAST (
    .clk(clk),
    .rst_p(rst_p),
    .id(j[bits_VN-1:0]),
    .REQ_E(`V_ZERO(NUM_VC)),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__VA_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__VA_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__VA_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__VA_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .free_VC_in(FREE_VC__FROM_O_E__TO__VA_E),
    .VC_released_in(VC_TO_RELEASE__FROM_O_E__TO__VA_E),
    .VC_assigns_out(VC_ASSIGNS__FROM_VA_E__TO__SA_E[(j*long_VC_assigns_per_VN+(long_VC_assigns_per_VN-1))-:long_VC_assigns_per_VN]),
    .GRANTS({VECTOR_GRANT__FROM__VA_E__TO__RT_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_E__TO__RT_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_E__TO__RT_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_E__TO__RT_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_E__TO__RT_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]}));

   /*`ifdef VC_STATIC_WAY   VA_LOCAL_STATIC
   `elsif VC_DYNAMIC_WAY  VA_LOCAL_DYNAMIC
   `else                  */VA_LOCAL_DYNAMIC /*`endif*/
   #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            ),
    .VN_WEIGHT_VECTOR_w      ( VN_WEIGHT_VECTOR_w                )
  )VA_LOCAL (
    .clk(clk),
    .rst_p(rst_p),
    .id(j[bits_VN-1:0]),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__VA_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__VA_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__VA_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__VA_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_L(`V_ZERO(NUM_VC)),
    .free_VC_in(FREE_VC__FROM_O_L__TO__VA_L),
    .VC_released_in(VC_TO_RELEASE__FROM_O_L__TO__VA_L),
    .VC_assigns_out(VC_ASSIGNS__FROM_VA_L__TO__SA_L[(j*long_VC_assigns_per_VN+(long_VC_assigns_per_VN-1))-:long_VC_assigns_per_VN]),
    .GRANTS({VECTOR_GRANT__FROM__VA_L__TO__RT_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_L__TO__RT_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_L__TO__RT_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_L__TO__RT_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_L__TO__RT_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]}));

   `ifdef VC_STATIC_WAY   VA_STATIC
   `elsif VC_DYNAMIC_WAY  VA_DYNAMIC
   `else                  VA_DYNAMIC `endif
   #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            )
  )VA_NORTH (
    .clk(clk),
    .rst_p(rst_p),
    .id(j[bits_VN-1:0]),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__VA_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__VA_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__VA_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_N(`V_ZERO(NUM_VC)),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__VA_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .free_VC_in(FREE_VC__FROM_O_N__TO__VA_N),
    .VC_released_in(VC_TO_RELEASE__FROM_O_N__TO__VA_N),
    .VC_assigns_out(VC_ASSIGNS__FROM_VA_N__TO__SA_N[(j*long_VC_assigns_per_VN+(long_VC_assigns_per_VN-1))-:long_VC_assigns_per_VN]),
    .GRANTS({VECTOR_GRANT__FROM__VA_N__TO__RT_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_N__TO__RT_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_N__TO__RT_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_N__TO__RT_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_N__TO__RT_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]}));

   `ifdef VC_STATIC_WAY   VA_STATIC
   `elsif VC_DYNAMIC_WAY  VA_DYNAMIC
   `else                  VA_DYNAMIC `endif
   #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            )
  )VA_SOUTH (
    .clk(clk),
    .rst_p(rst_p),
    .id(j[bits_VN-1:0]),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__VA_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_S(`V_ZERO(NUM_VC)),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__VA_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__VA_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__VA_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .free_VC_in(FREE_VC__FROM_O_S__TO__VA_S),
    .VC_released_in(VC_TO_RELEASE__FROM_O_S__TO__VA_S),
    .VC_assigns_out(VC_ASSIGNS__FROM_VA_S__TO__SA_S[(j*long_VC_assigns_per_VN+(long_VC_assigns_per_VN-1))-:long_VC_assigns_per_VN]),
    .GRANTS({VECTOR_GRANT__FROM__VA_S__TO__RT_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_S__TO__RT_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_S__TO__RT_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_S__TO__RT_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_S__TO__RT_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]}));

   `ifdef VC_STATIC_WAY   VA_STATIC
   `elsif VC_DYNAMIC_WAY  VA_DYNAMIC
   `else                  VA_DYNAMIC `endif
   #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            )
  )VA_WEST (
    .clk(clk),
    .rst_p(rst_p),
    .id(j[bits_VN-1:0]),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__VA_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__VA_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_W(`V_ZERO(NUM_VC)),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__VA_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__VA_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]),
    .free_VC_in(FREE_VC__FROM_O_W__TO__VA_W),
    .VC_released_in(VC_TO_RELEASE__FROM_O_W__TO__VA_W),
    .VC_assigns_out(VC_ASSIGNS__FROM_VA_W__TO__SA_W[(j*long_VC_assigns_per_VN+(long_VC_assigns_per_VN-1))-:long_VC_assigns_per_VN]),
    .GRANTS({VECTOR_GRANT__FROM__VA_W__TO__RT_E[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_W__TO__RT_S[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_W__TO__RT_W[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_W__TO__RT_N[(j*NUM_VC+(NUM_VC-1))-:NUM_VC],
     VECTOR_GRANT__FROM__VA_W__TO__RT_L[(j*NUM_VC+(NUM_VC-1))-:NUM_VC]}));

end //end for NUM_VN


  SA_VC  #(
    .Port                      (`PORT_E                            ),
    .FLIT_SIZE                 ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE            ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE            ( BROADCAST_SIZE                    ),
    .NUM_VC                    ( NUM_VC                            ),
    .NUM_VN                    ( NUM_VN                            ),
    .ENABLE_VN_WEIGHTS_SUPPORT ( ENABLE_VN_WEIGHTS_SUPPORT       )
    ) SA_EAST (.clk(clk),
    .rst_p(rst_p),
    .SG(GoBitFromE[NUM_VN_X_VC-1 : 0]),
    .WeightsVector_in(WeightsVector_in),
    .GoPhit(GOPHIT__FROM_O_E__TO__SA_E),
    .REQ_E(`V_ZERO(NUM_VN_X_VC)),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__SA_E[NUM_VN_X_VC-1 : 0]),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__SA_E[NUM_VN_X_VC-1 : 0]),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__SA_E[NUM_VN_X_VC-1 : 0]),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__SA_E[NUM_VN_X_VC-1 : 0]),
    .VC_assigns_in(VC_ASSIGNS__FROM_VA_E__TO__SA_E[long_VC_assigns-1 : 0]),
    .GRANTS({VECTOR_GRANT__FROM__SA_E__TO__RT_E,VECTOR_GRANT__FROM__SA_E__TO__RT_S,VECTOR_GRANT__FROM__SA_E__TO__RT_W,VECTOR_GRANT__FROM__SA_E__TO__RT_N,VECTOR_GRANT__FROM__SA_E__TO__RT_L}),
    .vc_selected_out(VC_SELECTED__FROM_SA_E__TO__O_E[bits_VN_X_VC-1:0]));

  SA_VC    #(
    .Port                    (`PORT_L                            ),
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            ),
    .ENABLE_VN_WEIGHTS_SUPPORT ( ENABLE_VN_WEIGHTS_SUPPORT       )
    ) SA_LOCAL (.clk(clk),
    .rst_p(rst_p),
    .SG(GoBitFromNI[NUM_VN-1 : 0]),
    .WeightsVector_in(WeightsVector_in),
    .GoPhit(GOPHIT__FROM_O_L__TO__SA_L),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__SA_L[NUM_VN_X_VC-1 : 0]),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__SA_L[NUM_VN_X_VC-1 : 0]),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__SA_L[NUM_VN_X_VC-1 : 0]),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__SA_L[NUM_VN_X_VC-1 : 0]),
    .REQ_L(`V_ZERO(NUM_VN_X_VC)),
    .VC_assigns_in(VC_ASSIGNS__FROM_VA_L__TO__SA_L[long_VC_assigns-1 : 0]),
    .GRANTS({VECTOR_GRANT__FROM__SA_L__TO__RT_E,VECTOR_GRANT__FROM__SA_L__TO__RT_S,VECTOR_GRANT__FROM__SA_L__TO__RT_W,VECTOR_GRANT__FROM__SA_L__TO__RT_N,VECTOR_GRANT__FROM__SA_L__TO__RT_L}),
    .vc_selected_out(VC_SELECTED__FROM_SA_L__TO__O_L[bits_VN_X_VC-1:0]));

  SA_VC   #(
    .Port                    (`PORT_N                            ),
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            ),
    .ENABLE_VN_WEIGHTS_SUPPORT ( ENABLE_VN_WEIGHTS_SUPPORT       )
    ) SA_NORTH (.clk(clk),
    .rst_p(rst_p),
    .SG(GoBitFromN[NUM_VN_X_VC-1 : 0]),
    .WeightsVector_in(WeightsVector_in),
    .GoPhit(GOPHIT__FROM_O_N__TO__SA_N),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__SA_N[NUM_VN_X_VC-1 : 0]),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__SA_N[NUM_VN_X_VC-1 : 0]),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__SA_N[NUM_VN_X_VC-1 : 0]),
    .REQ_N(`V_ZERO(NUM_VN_X_VC)),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__SA_N[NUM_VN_X_VC-1 : 0]),
    .VC_assigns_in(VC_ASSIGNS__FROM_VA_N__TO__SA_N[long_VC_assigns-1 : 0]),
    .GRANTS({VECTOR_GRANT__FROM__SA_N__TO__RT_E,VECTOR_GRANT__FROM__SA_N__TO__RT_S,VECTOR_GRANT__FROM__SA_N__TO__RT_W,VECTOR_GRANT__FROM__SA_N__TO__RT_N,VECTOR_GRANT__FROM__SA_N__TO__RT_L}),
    .vc_selected_out(VC_SELECTED__FROM_SA_N__TO__O_N[bits_VN_X_VC-1:0]));

 SA_VC   #(
    .Port                    (`PORT_S                            ),
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            ),
    .ENABLE_VN_WEIGHTS_SUPPORT ( ENABLE_VN_WEIGHTS_SUPPORT       )
    ) SA_SOUTH (.clk(clk),
    .rst_p(rst_p),
    .SG(GoBitFromS[NUM_VN_X_VC-1 : 0]),
    .WeightsVector_in(WeightsVector_in),
    .GoPhit(GOPHIT__FROM_O_S__TO__SA_S),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__SA_S[NUM_VN_X_VC-1 : 0]),
    .REQ_S(`V_ZERO(NUM_VN_X_VC)),
    .REQ_W(VECTOR_REQ__FROM__RT_W__TO__SA_S[NUM_VN_X_VC-1 : 0]),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__SA_S[NUM_VN_X_VC-1 : 0]),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__SA_S[NUM_VN_X_VC-1 : 0]),
    .VC_assigns_in(VC_ASSIGNS__FROM_VA_S__TO__SA_S[long_VC_assigns-1 : 0]),
    .GRANTS({VECTOR_GRANT__FROM__SA_S__TO__RT_E,VECTOR_GRANT__FROM__SA_S__TO__RT_S,VECTOR_GRANT__FROM__SA_S__TO__RT_W,VECTOR_GRANT__FROM__SA_S__TO__RT_N,VECTOR_GRANT__FROM__SA_S__TO__RT_L}),
    .vc_selected_out(VC_SELECTED__FROM_SA_S__TO__O_S[bits_VN_X_VC-1:0]));

  SA_VC   #(
    .Port                    (`PORT_W                            ),
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            ),
    .ENABLE_VN_WEIGHTS_SUPPORT ( ENABLE_VN_WEIGHTS_SUPPORT       )
    ) SA_WEST (.clk(clk),
    .rst_p(rst_p),
    .SG(GoBitFromW[NUM_VN_X_VC-1 : 0]),
    .WeightsVector_in(WeightsVector_in),
    .GoPhit(GOPHIT__FROM_O_W__TO__SA_W),
    .REQ_E(VECTOR_REQ__FROM__RT_E__TO__SA_W[NUM_VN_X_VC-1 : 0]),
    .REQ_S(VECTOR_REQ__FROM__RT_S__TO__SA_W[NUM_VN_X_VC-1 : 0]),
    .REQ_W(`V_ZERO(NUM_VN_X_VC)),
    .REQ_N(VECTOR_REQ__FROM__RT_N__TO__SA_W[NUM_VN_X_VC-1 : 0]),
    .REQ_L(VECTOR_REQ__FROM__RT_L__TO__SA_W[NUM_VN_X_VC-1 : 0]),
    .VC_assigns_in(VC_ASSIGNS__FROM_VA_W__TO__SA_W[long_VC_assigns-1 : 0]),
    .GRANTS({VECTOR_GRANT__FROM__SA_W__TO__RT_E,VECTOR_GRANT__FROM__SA_W__TO__RT_S,VECTOR_GRANT__FROM__SA_W__TO__RT_W,VECTOR_GRANT__FROM__SA_W__TO__RT_N,VECTOR_GRANT__FROM__SA_W__TO__RT_L}),
    .vc_selected_out(VC_SELECTED__FROM_SA_W__TO__O_W[bits_VN_X_VC-1:0]));

  OUTPUT_VC #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .PHIT_SIZE               ( PHIT_SIZE_E                       ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            ),
    .VN_WEIGHT_VECTOR_w      ( VN_WEIGHT_VECTOR_w                )
    ) OUTPUT_EAST (.clk(clk),
                          .rst_p(rst_p),
                          .Pre_Flit_E({FLIT_SIZE_VC{1'b0}}),
                          .Pre_Flit_L(VECTOR_FLIT__FROM__RT_L__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_N(VECTOR_FLIT__FROM__RT_N__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_S(VECTOR_FLIT__FROM__RT_S__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_W(VECTOR_FLIT__FROM__RT_W__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_FlitType_E({FLIT_TYPE_SIZE_VC{1'b0}}),
                          .Pre_FlitType_L(VECTOR_FLITTYPE__FROM__RT_L__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_N(VECTOR_FLITTYPE__FROM__RT_N__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_S(VECTOR_FLITTYPE__FROM__RT_S__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_W(VECTOR_FLITTYPE__FROM__RT_W__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_BroadcastFlit_E({NUM_VN_X_VC{1'b0}}),
                          .Pre_BroadcastFlit_L(VECTOR_BCFLIT__FROM__RT_L__TO__O_E[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_N(VECTOR_BCFLIT__FROM__RT_N__TO__O_E[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_S(VECTOR_BCFLIT__FROM__RT_S__TO__O_E[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_W(VECTOR_BCFLIT__FROM__RT_W__TO__O_E[NUM_VN_X_VC-1:0]),
                          .GRANTS({VECTOR_GRANT__FROM__SA_E__TO__RT_E,VECTOR_GRANT__FROM__SA_E__TO__RT_S,VECTOR_GRANT__FROM__SA_E__TO__RT_W,VECTOR_GRANT__FROM__SA_E__TO__RT_N,VECTOR_GRANT__FROM__SA_E__TO__RT_L}),
                          .vc_selected(VC_SELECTED__FROM_SA_E__TO__O_E[bits_VN_X_VC-1:0]),
                          .free_VC(FREE_VC__FROM_O_E__TO__VA_E),
                          .vc_to_release(VC_TO_RELEASE__FROM_O_E__TO__VA_E),
                          .VC_out(VC_ToE[bits_VN_X_VC-1:0]),
                          .GoPhit(GOPHIT__FROM_O_E__TO__SA_E),
                          .FlitOut(FlitToE[PHIT_SIZE_E-1:0]),
                          .FlitTypeOut(FlitTypeToE[FLIT_TYPE_SIZE-1:0]),
                          .BroadcastFlitOut(BroadcastFlitToE),
                          .Valid(ValidBitToE));

     OUTPUT_VC #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .PHIT_SIZE               ( PHIT_SIZE_L                       ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            )
    ) OUTPUT_LOCAL (.clk(clk),
                          .rst_p(rst_p),
                          .Pre_Flit_E(VECTOR_FLIT__FROM__RT_E__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_L({FLIT_SIZE_VC{1'b0}}),
                          .Pre_Flit_N(VECTOR_FLIT__FROM__RT_N__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_S(VECTOR_FLIT__FROM__RT_S__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_W(VECTOR_FLIT__FROM__RT_W__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_FlitType_E(VECTOR_FLITTYPE__FROM__RT_E__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_L({FLIT_TYPE_SIZE_VC{1'b0}}),
                          .Pre_FlitType_N(VECTOR_FLITTYPE__FROM__RT_N__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_S(VECTOR_FLITTYPE__FROM__RT_S__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_W(VECTOR_FLITTYPE__FROM__RT_W__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_BroadcastFlit_E(VECTOR_BCFLIT__FROM__RT_E__TO__O_L[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_L({NUM_VN_X_VC{1'b0}}),
                          .Pre_BroadcastFlit_N(VECTOR_BCFLIT__FROM__RT_N__TO__O_L[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_S(VECTOR_BCFLIT__FROM__RT_S__TO__O_L[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_W(VECTOR_BCFLIT__FROM__RT_W__TO__O_L[NUM_VN_X_VC-1:0]),
                          .GRANTS({VECTOR_GRANT__FROM__SA_L__TO__RT_E,VECTOR_GRANT__FROM__SA_L__TO__RT_S,VECTOR_GRANT__FROM__SA_L__TO__RT_W,VECTOR_GRANT__FROM__SA_L__TO__RT_N,VECTOR_GRANT__FROM__SA_L__TO__RT_L}),
                          .vc_selected(VC_SELECTED__FROM_SA_L__TO__O_L[bits_VN_X_VC-1:0]),
                          .free_VC(FREE_VC__FROM_O_L__TO__VA_L),
                          .vc_to_release(VC_TO_RELEASE__FROM_O_L__TO__VA_L),
                          .VC_out(VC_ToNI[bits_VN_X_VC-1:0]), //CAMBIAR A VC_ToNI / NUM_VC
                          .GoPhit(GOPHIT__FROM_O_L__TO__SA_L),
                          .FlitOut(FlitToNI[PHIT_SIZE_L-1:0]),
                          .FlitTypeOut(FlitTypeToNI[FLIT_TYPE_SIZE-1:0]),
                          .BroadcastFlitOut(BroadcastFlitToNI),
                          .Valid(ValidBitToNI));

     OUTPUT_VC #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .PHIT_SIZE               ( PHIT_SIZE_N                       ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            )
    ) OUTPUT_NORTH (.clk(clk),
                          .rst_p(rst_p),
                          .Pre_Flit_E(VECTOR_FLIT__FROM__RT_E__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_L(VECTOR_FLIT__FROM__RT_L__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_N({FLIT_SIZE_VC{1'b0}}),
                          .Pre_Flit_S(VECTOR_FLIT__FROM__RT_S__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_W(VECTOR_FLIT__FROM__RT_W__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_FlitType_E(VECTOR_FLITTYPE__FROM__RT_E__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_L(VECTOR_FLITTYPE__FROM__RT_L__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_N({FLIT_TYPE_SIZE_VC{1'b0}}),
                          .Pre_FlitType_S(VECTOR_FLITTYPE__FROM__RT_S__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_W(VECTOR_FLITTYPE__FROM__RT_W__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_BroadcastFlit_E(VECTOR_BCFLIT__FROM__RT_E__TO__O_N[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_L(VECTOR_BCFLIT__FROM__RT_L__TO__O_N[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_N({NUM_VN_X_VC{1'b0}}),
                          .Pre_BroadcastFlit_S(VECTOR_BCFLIT__FROM__RT_S__TO__O_N[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_W(VECTOR_BCFLIT__FROM__RT_W__TO__O_N[NUM_VN_X_VC-1:0]),
                          .GRANTS({VECTOR_GRANT__FROM__SA_N__TO__RT_E,VECTOR_GRANT__FROM__SA_N__TO__RT_S,VECTOR_GRANT__FROM__SA_N__TO__RT_W,VECTOR_GRANT__FROM__SA_N__TO__RT_N,VECTOR_GRANT__FROM__SA_N__TO__RT_L}),
                          .vc_selected(VC_SELECTED__FROM_SA_N__TO__O_N[bits_VN_X_VC-1:0]),
                          .free_VC(FREE_VC__FROM_O_N__TO__VA_N),
                          .vc_to_release(VC_TO_RELEASE__FROM_O_N__TO__VA_N),
                          .VC_out(VC_ToN[bits_VN_X_VC-1:0]),
                          .GoPhit(GOPHIT__FROM_O_N__TO__SA_N),
                          .FlitOut(FlitToN[PHIT_SIZE_N-1:0]),
                          .FlitTypeOut(FlitTypeToN[FLIT_TYPE_SIZE-1:0]),
                          .BroadcastFlitOut(BroadcastFlitToN),
                          .Valid(ValidBitToN));

     OUTPUT_VC #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .PHIT_SIZE               ( PHIT_SIZE_S                       ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            )
    ) OUTPUT_SOUTH (.clk(clk),
                          .rst_p(rst_p),
                          .Pre_Flit_E(VECTOR_FLIT__FROM__RT_E__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_L(VECTOR_FLIT__FROM__RT_L__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_N(VECTOR_FLIT__FROM__RT_N__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_S({FLIT_SIZE_VC{1'b0}}),
                          .Pre_Flit_W(VECTOR_FLIT__FROM__RT_W__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_FlitType_E(VECTOR_FLITTYPE__FROM__RT_E__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_L(VECTOR_FLITTYPE__FROM__RT_L__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_N(VECTOR_FLITTYPE__FROM__RT_N__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_S({FLIT_TYPE_SIZE_VC{1'b0}}),
                          .Pre_FlitType_W(VECTOR_FLITTYPE__FROM__RT_W__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_BroadcastFlit_E(VECTOR_BCFLIT__FROM__RT_E__TO__O_S[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_L(VECTOR_BCFLIT__FROM__RT_L__TO__O_S[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_N(VECTOR_BCFLIT__FROM__RT_N__TO__O_S[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_S({NUM_VN_X_VC{1'b0}}),
                          .Pre_BroadcastFlit_W(VECTOR_BCFLIT__FROM__RT_W__TO__O_S[NUM_VN_X_VC-1:0]),
                          .GRANTS({VECTOR_GRANT__FROM__SA_S__TO__RT_E,VECTOR_GRANT__FROM__SA_S__TO__RT_S,VECTOR_GRANT__FROM__SA_S__TO__RT_W,VECTOR_GRANT__FROM__SA_S__TO__RT_N,VECTOR_GRANT__FROM__SA_S__TO__RT_L}),
                          .vc_selected(VC_SELECTED__FROM_SA_S__TO__O_S[bits_VN_X_VC-1:0]),
                          .free_VC(FREE_VC__FROM_O_S__TO__VA_S),
                          .vc_to_release(VC_TO_RELEASE__FROM_O_S__TO__VA_S),
                          .VC_out(VC_ToS[bits_VN_X_VC-1:0]),
                          .GoPhit(GOPHIT__FROM_O_S__TO__SA_S),
                          .FlitOut(FlitToS[PHIT_SIZE_S-1:0]),
                          .FlitTypeOut(FlitTypeToS[FLIT_TYPE_SIZE-1:0]),
                          .BroadcastFlitOut(BroadcastFlitToS),
                          .Valid(ValidBitToS));

     OUTPUT_VC #(
    .FLIT_SIZE               ( FLIT_SIZE                         ),
    .FLIT_TYPE_SIZE          ( FLIT_TYPE_SIZE                    ),
    .BROADCAST_SIZE          ( BROADCAST_SIZE                    ),
    .PHIT_SIZE               ( PHIT_SIZE_W                       ),
    .NUM_VC                  ( NUM_VC                            ),
    .NUM_VN                  ( NUM_VN                            )
    ) OUTPUT_WEST (.clk(clk),
                          .rst_p(rst_p),
                          .Pre_Flit_E(VECTOR_FLIT__FROM__RT_E__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_L(VECTOR_FLIT__FROM__RT_L__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_N(VECTOR_FLIT__FROM__RT_N__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_S(VECTOR_FLIT__FROM__RT_S__TO__O_ALL[FLIT_SIZE_VC-1:0]),
                          .Pre_Flit_W({FLIT_SIZE_VC{1'b0}}),
                          .Pre_FlitType_E(VECTOR_FLITTYPE__FROM__RT_E__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_L(VECTOR_FLITTYPE__FROM__RT_L__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_N(VECTOR_FLITTYPE__FROM__RT_N__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_S(VECTOR_FLITTYPE__FROM__RT_S__TO__O_ALL[FLIT_TYPE_SIZE_VC-1:0]),
                          .Pre_FlitType_W({FLIT_TYPE_SIZE_VC{1'b0}}),
                          .Pre_BroadcastFlit_E(VECTOR_BCFLIT__FROM__RT_E__TO__O_W[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_L(VECTOR_BCFLIT__FROM__RT_L__TO__O_W[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_N(VECTOR_BCFLIT__FROM__RT_N__TO__O_W[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_S(VECTOR_BCFLIT__FROM__RT_S__TO__O_W[NUM_VN_X_VC-1:0]),
                          .Pre_BroadcastFlit_W({NUM_VN_X_VC{1'b0}}),
                          .GRANTS({VECTOR_GRANT__FROM__SA_W__TO__RT_E,VECTOR_GRANT__FROM__SA_W__TO__RT_S,VECTOR_GRANT__FROM__SA_W__TO__RT_W,VECTOR_GRANT__FROM__SA_W__TO__RT_N,VECTOR_GRANT__FROM__SA_W__TO__RT_L}),
                          .vc_selected(VC_SELECTED__FROM_SA_W__TO__O_W[bits_VN_X_VC-1:0]),
                          .free_VC(FREE_VC__FROM_O_W__TO__VA_W),
                          .vc_to_release(VC_TO_RELEASE__FROM_O_W__TO__VA_W),
                          .VC_out(VC_ToW[bits_VN_X_VC-1:0]),
                          .GoPhit(GOPHIT__FROM_O_W__TO__SA_W),
                          .FlitOut(FlitToW[PHIT_SIZE_W-1:0]),
                          .FlitTypeOut(FlitTypeToW[FLIT_TYPE_SIZE-1:0]),
                          .BroadcastFlitOut(BroadcastFlitToW),
                          .Valid(ValidBitToW));
endmodule
