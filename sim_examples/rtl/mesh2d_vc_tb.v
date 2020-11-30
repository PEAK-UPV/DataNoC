`timescale 1ns / 1ps
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
//-----------------------------------------------------------------------------
//
// Company:  GAP (UPV)
// Engineer: T. Picornell (tompic@gap.upv.es)
// Contact:  J. Flich (jflich@disca.upv.es)
//
// Create Date: 23/11/2020
// File Name: mesh2d_vc_tb.v
// Module Name: mesh2d_vc_tb
// Project Name: DataNoC
// Target Devices: 
// Description: 
//  Example to interconnect DataNoC routers creating a 2D mesh.
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
`include "data_net_message_format.h"
`include "synthetic_traffic_generator.h"

module mesh2d_vc_tb;

`include "common_functions.vh"
`include "data_net_virtual_channel.vh"

//**************************************************
// * DATA_NET, some of them are architecture specific
//**************************************************

`define MESSAGE_SYSTEM
`define VC_DYNAMIC_WAY
`define VN_WITH_PRIORITIES
`define DATA_NET_NUM_VC_PER_VN                1                // Number of Virtual Channels per Virtual networ
`define DATA_NET_NUM_VN                       3                // Number of Virtual Networks
`define DATA_NET_FLIT_w                       64               // Flit size for the data network
`define DATA_NET_PHIT_w                       `DATA_NET_FLIT_w // Phit size (for FPGA boundary routers)
`define DATA_NET_VNID_VECTOR                  2'd2,2'd1,2'd0   // Vector of virtual network identefiers
`define DATA_NET_VN_PRIORITY_VECTOR_w         20               // Virtual network priority vector size. !!!!! Modify TR accordingly
`define VN_WEIGHT_PRIORITIES                  2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0,2'd1,2'd2,2'd0  // PLEASE, PRESERVE 10 VALUES
`define TLID_w 9                                               // * defines the TILE identificator width
`define DATA_NET_IB_QUEUE_SIZE 8                               // * defines the default input buffer size for datanet routers. Power of 2 required
`define DATA_NET_IB_SG_UPPER_THRESHOLD 5                       // * defines the upper threshold for the Stop&Go flow control between datanet routers
`define DATA_NET_IB_SG_LOWER_THRESHOLD 4                       // * defines the lower threshold for the Stop&Go flow control between datanet routers
`define DATA_NET_FLIT_UNIT_ID_w `TLID_w                        // * Defines the width of the Unit ID
`define DATA_NET_FLIT_UNIT_TYPE_w `COMPONENT_TYPE_w            // * Defines the width of type of a component
`define DATA_NET_FLIT_MSG_TYPE_w 2                             // * Defines the width for the message type, if not defined externally. This can not be defined globally, because for the MANGO network is 0; meanwhile for the PEAK network is 2.

//For 4x4 mesh
localparam FPGA_DIMX          = 4;                 // FPGA number of Tiles in X-dimension
localparam FPGA_DIMY          = 4;                 // FPGA number of Tiles in Y-dimension
localparam FPGA_N_NxT         = 1;                 // FPGA number of Nodes per tile
localparam FPGA_N_Nodes       = 16;                // FPGA number of Total nodes in the topology
localparam FPGA_DIMX_w        = 2;                 // FPGA X-Dim width
localparam FPGA_DIMY_w        = 2;                 // FPGA Y-Dim width
localparam FPGA_N_NxT_w       = 1;                 // FPGA Nodes per tile width
localparam FPGA_N_Nodes_w     = 4;                 // FPGA Total nodes width
localparam FPGA_SWITCH_ID_w   = 4;                 // ID width for switches
localparam GLBL_DIMX          = 4;                 // Global number of tiles in X-dimension
localparam GLBL_DIMY          = 4;                 // Global number of Tiles in Y-dimension
localparam GLBL_N_NxT         = 1;                 // Global number of Nodes per tile
localparam GLBL_N_Nodes       = 16;                // Global number of Total nodes in the topology
localparam GLBL_DIMX_w        = 2;                 // Global  X-Dim width
localparam GLBL_DIMY_w        = 2;                 // Global  Y-Dim width
localparam GLBL_N_NxT_w       = 1;                 // Global Nodes per tile width
localparam GLBL_N_Nodes_w     = 4;                 // Total nodes width
localparam GLBL_SWITCH_ID_w   = 4;                 // ID width for switches

/*//Uncomment for 8x8 mesh
localparam FPGA_DIMX          = 8,                 // FPGA number of Tiles in X-dimension
localparam FPGA_DIMY          = 8,                 // FPGA number of Tiles in Y-dimension
localparam FPGA_N_NxT         = 1,                 // FPGA number of Nodes per tile
localparam FPGA_N_Nodes       = 64,                // FPGA number of Total nodes in the topology
localparam FPGA_DIMX_w        = 3,                 // FPGA X-Dim width
localparam FPGA_DIMY_w        = 3,                 // FPGA Y-Dim width
localparam FPGA_N_NxT_w       = 1,                 // FPGA Nodes per tile width
localparam FPGA_N_Nodes_w     = 6,                 // FPGA Total nodes width
localparam FPGA_SWITCH_ID_w   = 6,                 // ID width for switches
localparam GLBL_DIMX          = 8,                 // Global number of tiles in X-dimension
localparam GLBL_DIMY          = 8,                 // Global number of Tiles in Y-dimension
localparam GLBL_N_NxT         = 1,                 // Global number of Nodes per tile
localparam GLBL_N_Nodes       = 64,                // Global number of Total nodes in the topology
localparam GLBL_DIMX_w        = 3,                 // Global  X-Dim width
localparam GLBL_DIMY_w        = 3,                 // Global  Y-Dim width
localparam GLBL_N_NxT_w       = 1,                 // Global Nodes per tile width
localparam GLBL_N_Nodes_w     = 6,                 // Total nodes width
localparam GLBL_SWITCH_ID_w   = 6,                 // ID width for switches*/

//
localparam FLIT_SIZE          = `DATA_NET_FLIT_w;
localparam PHIT_SIZE          = `DATA_NET_FLIT_w;
localparam PHIT_SIZE_L        = `DATA_NET_FLIT_w;
localparam PHIT_SIZE_N        = `DATA_NET_FLIT_w;
localparam PHIT_SIZE_E        = `DATA_NET_FLIT_w;
localparam PHIT_SIZE_W        = `DATA_NET_FLIT_w;
localparam PHIT_SIZE_S        = `DATA_NET_FLIT_w;
localparam FLIT_TYPE_SIZE     = `DATA_NET_FT_w;
localparam BROADCAST_SIZE     = 5;
localparam NUM_PORTS          = `NUM_PORTS;
localparam NUM_VC             = `DATA_NET_NUM_VC_PER_VN;                 // Number of Virtual Channels supported for each Virtual Network
localparam NUM_VN             = `DATA_NET_NUM_VN;                 // Number of Virtual Networks supported
//
localparam IB_QUEUE_SIZE      = 8;                 // queue size (per VN)
localparam IB_SG_UPPER_THOLD  = 5;                 // stop flow control threshold
localparam IB_SG_LOWER_THOLD  = 4;                 // go flow control threshold
//

localparam VN_WEIGHT_VECTOR_w = `DATA_NET_VN_PRIORITY_VECTOR_w;                // Virtual network priority vector size
localparam VN_WEIGHT_VECTOR   = {`VN_WEIGHT_PRIORITIES};  // Virtual network priority vector

localparam LOG_CORES_PER_TILE_GOOD    = Log2(GLBL_N_NxT);

localparam ENABLE_MESSAGE_SYSTEM_SUPPORT = "yes";
localparam ENABLE_VN_WEIGHTS_SUPPORT = "yes";

localparam DIMX = FPGA_DIMX;
localparam DIMY = FPGA_DIMY;

reg clk;
reg rst_p;
reg [63:0] timestamp;

//*****************************************************************************************************************
// DATA NETWORK inter-routers connection wires
//*****************************************************************************************************************
wire [`DATA_NET_FLIT_SIGNALS_RANGE] toDATANET_E   [0 : (DIMY*DIMX)-1];
wire [`DATA_NET_FLIT_SIGNALS_RANGE] toDATANET_S   [0 : (DIMY*DIMX)-1];
wire [`DATA_NET_FLIT_SIGNALS_RANGE] toDATANET_W   [0 : (DIMY*DIMX)-1];
wire [`DATA_NET_FLIT_SIGNALS_RANGE] toDATANET_N   [0 : (DIMY*DIMX)-1];

wire [`DATA_NET_FLIT_SIGNALS_RANGE] fromDATANET_E [0 : (DIMY*DIMX)-1];
wire [`DATA_NET_FLIT_SIGNALS_RANGE] fromDATANET_S [0 : (DIMY*DIMX)-1];
wire [`DATA_NET_FLIT_SIGNALS_RANGE] fromDATANET_W [0 : (DIMY*DIMX)-1];
wire [`DATA_NET_FLIT_SIGNALS_RANGE] fromDATANET_N [0 : (DIMY*DIMX)-1];
//*****************************************************************************************************************

//2D Mesh Interconnection***************************************************************
genvar i, j;
generate
  //
  for (i = 0; i < (DIMY * DIMX); i = i + 1) begin: tiles_conn
    //
    // ********* South -> North connections
    if (i < ((DIMY-1) * DIMX)) begin
      // it is not the last row
      assign toDATANET_N[i+DIMX] = fromDATANET_S[i];
       //
    end else begin
      // it is the last row
      assign toDATANET_S[i][`DATA_NET_FLIT_VALID_RANGE] = `V_ALLX(`DATA_NET_VALID_w);
      assign toDATANET_S[i][`DATA_NET_FLIT_GO_RANGE] = `V_ALLX(`DATA_NET_GO_w);
      assign toDATANET_S[i][`DATA_NET_FLIT_BC_RANGE] = `V_ALLX(`DATA_NET_BC_w);
      assign toDATANET_S[i][`DATA_NET_FLIT_RANGE] = `V_ALLX(`DATA_NET_FLIT_w);
    end

    // ********** North -> South connections
    if (i>=DIMX) begin
      // it is not the first row
      assign toDATANET_S[i-DIMX] = fromDATANET_N[i];
      //
    end else begin
      // it is the first row
      assign toDATANET_N[i][`DATA_NET_FLIT_VALID_RANGE] = `V_ALLX(`DATA_NET_VALID_w);
      assign toDATANET_N[i][`DATA_NET_FLIT_GO_RANGE] = `V_ALLX(`DATA_NET_GO_w);
      assign toDATANET_N[i][`DATA_NET_FLIT_BC_RANGE] = `V_ALLX(`DATA_NET_BC_w);
      assign toDATANET_N[i][`DATA_NET_FLIT_RANGE] = `V_ALLX(`DATA_NET_FLIT_w);
     end

    // ********** East -> West connections
    if ((((i%DIMX) - (DIMX-1))!=0)) begin
      // it is not the last col
      assign toDATANET_W[i+1] = fromDATANET_E[i];
      //
    end else begin
      // it is the last col
      assign toDATANET_E[i][`DATA_NET_FLIT_VALID_RANGE] = `V_ALLX(`DATA_NET_VALID_w);
      assign toDATANET_E[i][`DATA_NET_FLIT_GO_RANGE] = `V_ALLX(`DATA_NET_GO_w);
      assign toDATANET_E[i][`DATA_NET_FLIT_BC_RANGE] = `V_ALLX(`DATA_NET_BC_w);
      assign toDATANET_E[i][`DATA_NET_FLIT_RANGE] = `V_ALLX(`DATA_NET_FLIT_w);
    end
//      `endif

    // ********** West -> East connections
    if ((i%DIMX)!=0) begin
      // it is not the first col
      assign toDATANET_E[i-1] = fromDATANET_W[i];
      //
    end else begin
      //it is the first col
      assign toDATANET_W[i][`DATA_NET_FLIT_VALID_RANGE] = `V_ALLX(`DATA_NET_VALID_w);
      assign toDATANET_W[i][`DATA_NET_FLIT_GO_RANGE] = `V_ALLX(`DATA_NET_GO_w);
      assign toDATANET_W[i][`DATA_NET_FLIT_BC_RANGE] = `V_ALLX(`DATA_NET_BC_w);
      assign toDATANET_W[i][`DATA_NET_FLIT_RANGE] = `V_ALLX(`DATA_NET_FLIT_w);
   end
  end  // for ... TILES_CONNECTIONS
endgenerate

//Tiles Definition***************************************************************
generate
  for (i = 0; i < (DIMY * DIMX); i = i + 1) begin: def_tiles

    // DATANET iface to wire 2D mesh
    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_north_i;
    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_east_i;
    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_west_i;
    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_south_i;

    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_north_o;
    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_east_o;
    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_west_o;
    wire [`DATA_NET_FLIT_SIGNALS_RANGE]  datanet_south_o;

    assign datanet_east_i   = toDATANET_E[i];
    assign datanet_north_i  = toDATANET_N[i];
    assign datanet_south_i  = toDATANET_S[i];
    assign datanet_west_i   = toDATANET_W[i];

    assign fromDATANET_E[i] = datanet_east_o ;
    assign fromDATANET_S[i] = datanet_south_o;
    assign fromDATANET_W[i] = datanet_west_o ;
    assign fromDATANET_N[i] = datanet_north_o;

    // SYNTHETIC TRAFFIC GENERATORS INSTANCES ****************************************************************************
    wire [FLIT_SIZE-1:0] flit_fromMS;                                             //
    wire [FLIT_TYPE_SIZE-1:0] flit_type_fromMS;                                         //
    wire reqMS_tonet;                                                    //
    wire availMS_fromnet;                                                //
    wire [37:0] w_data_vn0_to_ms;
    wire w_req_ms_to_ms;
    wire w_req_vn0_to_ms;
    wire [37:0] w_data_ms_to_ms;
    wire w_avail_ms_to_vn0;
    wire w_avail_ms_to_ms;
    wire [1:0] vn_to_inject_fromMS;

    wire [`MS_w-1:0] w_MessageSystem_in;
    wire [`MS_w-1:0] w_MessageSystem_out;


    reg [`MS_w-1:0] Generated_MessageSystem_in;
    reg ms_activated;

    reg        req_Generated_MessageSystem;
    reg [`MS_MSG_SIZE_w-1:0] msg_size_Generated_MessageSystem;
    reg [3:0] synth_function_Generated_MessageSystem;
    reg [1:0] vn_Generated_MessageSystem;
    reg [8:0] dst_Generated_MessageSystem;
    reg [3:0] iRate_Generated_MessageSystem;


    localparam select_dst = 0;   //Send to specific destination and specific vn, else will send to a random destination and vn

    always @ (posedge clk)
      if (rst_p) begin
        ms_activated <= 1'b0;
        Generated_MessageSystem_in <= `V_ZERO(`MS_w);
        req_Generated_MessageSystem <= 1'b0;

      end else begin

        if(!ms_activated) begin
          req_Generated_MessageSystem <= 1'b1;
          msg_size_Generated_MessageSystem <= 6; //MESSAGE_SIZE
          synth_function_Generated_MessageSystem <= (select_dst) ?   `SYNTH2_FUNCTION : //Selected destination and vn mode
                                                                      `SYNTH_FUNCTION ; //Random destination and vn mode
          vn_Generated_MessageSystem <= `V_ZERO(`MS_VNID_w);     // VN to inject (does not care in random mode)
          dst_Generated_MessageSystem <= `V_ZERO(`MS_DST_w);    // Destination node (does not care in random mode)
          iRate_Generated_MessageSystem <= 4'd1;  //1=100% injection rate, 2=50%, 3=33%, 4=25%, 5=12.5%, 6=6.25%

          Generated_MessageSystem_in <= {req_Generated_MessageSystem, msg_size_Generated_MessageSystem, synth_function_Generated_MessageSystem, 3'd0, vn_Generated_MessageSystem, dst_Generated_MessageSystem, iRate_Generated_MessageSystem};
          ms_activated <= req_Generated_MessageSystem;
        end// ms_activated
        else begin
          Generated_MessageSystem_in[`MS_w-1] <= 1'b0;
        end// ms_disabled
      end// else

        // We define the Message_tonet module if defined
        MS_tonet #(
          .ID(i),
          .CORES_PER_TILE(GLBL_N_NxT),
          .NUM_NODES(GLBL_N_Nodes)
        ) ms_tonet0 (
          .clk(clk),                                      //
          .rst_p(rst_p),                                  //
          .timestamp_in(timestamp),
          .MessageSystem_in(Generated_MessageSystem_in),  //
          .FlitOut(flit_fromMS),                          //
          .FlitType(flit_type_fromMS),                    //
          .req_tonet(reqMS_tonet),                        //
          .req_tolocal(w_req_ms_to_ms),                   //
          .data_tolocal(w_data_ms_to_ms),                 //
          .vn_to_inject(vn_to_inject_fromMS),             //
          .avail_net(availMS_fromnet),                    //
          .avail_local(w_avail_ms_to_ms)                  //
        );
        assign w_avail_ms_to_ms = 1'b1;
    // END MESSAGE SYSTEM INSTANCE ---------------------------------------------------------------------------

    // NETWORK INJECTOR INSTANCES ---------------------------------------------------------------------------------------------------------
    //THIS IS A PARAMETRIZABLE NETWORK INJECTOR WITH SUPPORT TO SEVERAL INPUTS
    localparam NUM_INJ_PORTS = 0; // SET THE NUMBER OF INPUT PORTS (SYNTHETIC MESSAGE GENERATOR USE ADITIONAL INPUT PORT)
    wire  [(NUM_INJ_PORTS*FLIT_SIZE)-1:0]      inject_flit;
    wire  [(NUM_INJ_PORTS*FLIT_TYPE_SIZE)-1:0] inject_flit_type;
    wire  [(BROADCAST_SIZE*NUM_INJ_PORTS)-1:0] inject_broadcast;
    wire  [(NUM_INJ_PORTS*bits_VN_X_VC)-1:0]   inject_vn;
    wire  [NUM_INJ_PORTS-1:0]                  inject_req;
    wire  [NUM_INJ_PORTS-1:0]                  inject_avail;

    assign inject_flit              = `V_ZERO(NUM_INJ_PORTS*FLIT_SIZE);
    assign inject_flit_type         = `V_ZERO(NUM_INJ_PORTS*FLIT_TYPE_SIZE);
    assign inject_broadcast         = `V_ZERO(BROADCAST_SIZE*NUM_INJ_PORTS);
    assign inject_vn                = `V_ZERO(NUM_INJ_PORTS*bits_VN_X_VC);
    assign inject_req               = `V_ZERO(NUM_INJ_PORTS);

    // We define the wires between NI and the networks
    wire [FLIT_SIZE-1:0]         FlitToVDN;
    wire [FLIT_TYPE_SIZE-1:0]    FlitTypeToVDN;
    wire                         ValidBitToVDN;
    wire [BROADCAST_SIZE-1:0]    BroadcastBits_NItoRD;
    wire [NUM_VN-1 : 0]          GoToVDN = `V_ALL1(NUM_VN); //This Go signals must come from ejectors. We set all bits to 1.
    wire [bits_VN_X_VC-1 : 0]    VcToVDN;

    wire [FLIT_SIZE-1:0]         FlitfromVDN;
    wire [FLIT_TYPE_SIZE-1:0]    FlitTypefromVDN;
    wire                         ValidBitFromVDN;
    wire [NUM_VN_X_VC-1 : 0]     GoFromVDN;
    wire [bits_VN-1 : 0]         VnFromVDN;
    wire                         BroadcastBit_VDNtoNI;

    network_injector #(
      .ID                            ( i                                    ),
      .FLIT_SIZE                     ( FLIT_SIZE                            ),
      .FLIT_TYPE_SIZE                ( FLIT_TYPE_SIZE                       ),
      .BROADCAST_SIZE                ( BROADCAST_SIZE                       ),
      .PHIT_SIZE                     ( PHIT_SIZE                            ),
      .QUEUE_SIZE                    ( IB_QUEUE_SIZE                        ),
      .SG_UPPER_THOLD                ( IB_SG_UPPER_THOLD                    ),
      .SG_LOWER_THOLD                ( IB_SG_LOWER_THOLD                    ),
      .NUM_PORTS                     ( NUM_PORTS                            ),
      .NUM_VC                        ( NUM_VC                               ),
      .NUM_VN                        ( NUM_VN                               ),
      .VN_w                          ( bits_VN                              ),
      .NUM_VN_X_VC                   ( NUM_VN_X_VC                          ),
      .VN_WEIGHT_VECTOR_w            ( VN_WEIGHT_VECTOR_w                   ),
      .CORES_PER_TILE                ( GLBL_N_NxT                           ),
      .NUM_INPUT_SOURCES             ( NUM_INJ_PORTS                        ),  //  Modify acordingly to notify the module with the number of Imput Sources
      .ENABLE_MESSAGE_SYSTEM_SUPPORT ( ENABLE_MESSAGE_SYSTEM_SUPPORT        ),
      .ENABLE_VN_WEIGHTS_SUPPORT     ( ENABLE_VN_WEIGHTS_SUPPORT            ),
      .ENABLE_NETWORK_DEBUG_LEVEL_0_SUPPORT  ( "yes" )
    ) network_injector_inst (
      .clk                           ( clk                                  ),
      .rst_p                         ( rst_p                                ),
      .go                            ( GoFromVDN                            ),
      .WeightsVector_i               ( VN_WEIGHT_VECTOR                     ),
      .flit_i                        ( inject_flit                          ), //  This bus format will be like this: {flit_2, flit_1, flit_0}
      .flit_type_i                   ( inject_flit_type                     ), //  This bus format will be like this: {flit_type_2, flit_type_1, flit_type_0}
      .bc_i                          ( inject_broadcast                     ), //  This bus format will be like this: {bc_i_2, bc_i_1, bc_i_0}
      .vn_i                          ( inject_vn                            ), //  This bus format will be like this: {vn_i_2, vn_i_1, vn_i_0}
      .req_i                         ( inject_req                           ), //  This bus format will be like this: {req_i_2, req_i_1, req_i_0}
      .avail_o                       ( inject_avail                         ), //  This bus format will be like this: {avail_o_2, avail_o_1, avail_o_0}

      .flit_MS_i                     ( flit_fromMS                          ), // only if message_system infrastructure is defined
      .flit_type_MS_i                ( flit_type_fromMS                     ), //
      .req_MS_i                      ( reqMS_tonet                          ), //
      .vn_MS_i                       ( vn_to_inject_fromMS                  ), //
      .avail_MS_o                    ( availMS_fromnet                      ), //

      .BroadcastFlitOut              ( BroadcastBits_NItoRD[BROADCAST_SIZE-1:0]),
      .FlitOut                       ( FlitToVDN[FLIT_SIZE-1:0]             ),
      .FlitTypeOut                   ( FlitTypeToVDN[FLIT_TYPE_SIZE-1:0]    ),
      .ValidOut                      ( ValidBitToVDN                        ),
      .VC_out                        ( VcToVDN                              )
    );

    // NETWORK SWITCH INSTANCES ---------------------------------------------------------------------------------------------------------
    switch_2dmesh_vc #(
      .ID ( i ),
      //
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
      .NUM_PORTS ( NUM_PORTS ),
      .NUM_VN ( NUM_VN ),
      .NUM_VC ( NUM_VC ),
      //
      .FLIT_TYPE_SIZE ( FLIT_TYPE_SIZE ),
      //
      .FLIT_SIZE          ( FLIT_SIZE      ),
      .PHIT_SIZE_L        ( PHIT_SIZE_L    ),
      .PHIT_SIZE_N        ( PHIT_SIZE_N    ),
      .PHIT_SIZE_E        ( PHIT_SIZE_E    ),
      .PHIT_SIZE_W        ( PHIT_SIZE_W    ),
      .PHIT_SIZE_S        ( PHIT_SIZE_S    ),
      //
      .IB_QUEUE_SIZE     ( IB_QUEUE_SIZE ),
      .IB_SG_UPPER_THOLD ( IB_SG_UPPER_THOLD ),
      .IB_SG_LOWER_THOLD ( IB_SG_LOWER_THOLD ),

      .DATA_NET_FLIT_DST_UNIT_ID_MSB ( `MSG_TLDST_MSB  ),
      .DATA_NET_FLIT_DST_UNIT_ID_LSB ( `MSG_TLDST_LSB  ),

      .ENABLE_VN_WEIGHTS_SUPPORT ( ENABLE_VN_WEIGHTS_SUPPORT ),
      .VN_WEIGHT_VECTOR_w ( VN_WEIGHT_VECTOR_w )
      ) switch_2dmesh_vc_inst (
      .clk ( clk ),
      .rst_p ( rst_p ),

      .WeightsVector_in(VN_WEIGHT_VECTOR),

      .FlitFromE ( datanet_east_i[`DATA_NET_FLIT_w-1:0] ),
      .FlitFromN ( datanet_north_i[`DATA_NET_FLIT_w-1:0] ),
      .FlitFromNI ( FlitToVDN ),
      .FlitFromS ( datanet_south_i[`DATA_NET_FLIT_w-1:0] ),
      .FlitFromW ( datanet_west_i[`DATA_NET_FLIT_w-1:0] ),

      .FlitTypeFromE ( datanet_east_i[`DATA_NET_FLIT_FT_RANGE] ),
      .FlitTypeFromN ( datanet_north_i[`DATA_NET_FLIT_FT_RANGE] ),
      .FlitTypeFromNI ( FlitTypeToVDN ),
      .FlitTypeFromS ( datanet_south_i[`DATA_NET_FLIT_FT_RANGE] ),
      .FlitTypeFromW ( datanet_west_i[`DATA_NET_FLIT_FT_RANGE] ),

      .BroadcastFlitFromE ( datanet_east_i[`DATA_NET_FLIT_BC_RANGE] ),
      .BroadcastFlitFromN ( datanet_north_i[`DATA_NET_FLIT_BC_RANGE] ),
      .BroadcastFlitFromNI ( BroadcastBits_NItoRD[BROADCAST_SIZE-1] ),
      .BroadcastFlitFromS ( datanet_south_i[`DATA_NET_FLIT_BC_RANGE] ),
      .BroadcastFlitFromW ( datanet_west_i[`DATA_NET_FLIT_BC_RANGE] ),

      .GoBitFromE ( datanet_east_i[`DATA_NET_FLIT_GO_RANGE] ),
      .GoBitFromN ( datanet_north_i[`DATA_NET_FLIT_GO_RANGE] ),
      .GoBitFromNI ( GoToVDN ),
      .GoBitFromS ( datanet_south_i[`DATA_NET_FLIT_GO_RANGE] ),
      .GoBitFromW ( datanet_west_i[`DATA_NET_FLIT_GO_RANGE] ),

      .ValidBitFromE ( datanet_east_i[`DATA_NET_FLIT_VALID_RANGE] ),
      .ValidBitFromN ( datanet_north_i[`DATA_NET_FLIT_VALID_RANGE] ),
      .ValidBitFromNI( ValidBitToVDN ),
      .ValidBitFromS ( datanet_south_i[`DATA_NET_FLIT_VALID_RANGE] ),
      .ValidBitFromW ( datanet_west_i[`DATA_NET_FLIT_VALID_RANGE] ),

      .VC_FromE ( datanet_east_i[`DATA_NET_FLIT_VC_RANGE] ),
      .VC_FromN ( datanet_north_i[`DATA_NET_FLIT_VC_RANGE] ),
      .VC_FromNI ( VcToVDN ),
      .VC_FromS ( datanet_south_i[`DATA_NET_FLIT_VC_RANGE] ),
      .VC_FromW ( datanet_west_i[`DATA_NET_FLIT_VC_RANGE] ),


      .FlitToE ( datanet_east_o[`DATA_NET_FLIT_w-1:0] ),
      .FlitToN ( datanet_north_o[`DATA_NET_FLIT_w-1:0] ),
      .FlitToNI ( FlitfromVDN ),
      .FlitToS ( datanet_south_o[`DATA_NET_FLIT_w-1:0] ),
      .FlitToW ( datanet_west_o[`DATA_NET_FLIT_w-1:0] ),

      .FlitTypeToE ( datanet_east_o[`DATA_NET_FLIT_FT_RANGE] ),
      .FlitTypeToN ( datanet_north_o[`DATA_NET_FLIT_FT_RANGE] ),
      .FlitTypeToNI ( FlitTypefromVDN ),
      .FlitTypeToS ( datanet_south_o[`DATA_NET_FLIT_FT_RANGE] ),
      .FlitTypeToW ( datanet_west_o[`DATA_NET_FLIT_FT_RANGE] ),

      .BroadcastFlitToE( datanet_east_o[`DATA_NET_FLIT_BC_RANGE] ),
      .BroadcastFlitToN( datanet_north_o[`DATA_NET_FLIT_BC_RANGE] ),
      .BroadcastFlitToS( datanet_south_o[`DATA_NET_FLIT_BC_RANGE] ),
      .BroadcastFlitToW( datanet_west_o[`DATA_NET_FLIT_BC_RANGE] ),
      .BroadcastFlitToNI ( BroadcastBit_VDNtoNI ),

      .GoBitToE ( datanet_east_o[`DATA_NET_FLIT_GO_RANGE] ),
      .GoBitToN ( datanet_north_o[`DATA_NET_FLIT_GO_RANGE] ),
      .GoBitToNIC ( GoFromVDN ),
      .GoBitToS ( datanet_south_o[`DATA_NET_FLIT_GO_RANGE] ),
      .GoBitToW ( datanet_west_o[`DATA_NET_FLIT_GO_RANGE] ),

      .ValidBitToE ( datanet_east_o[`DATA_NET_FLIT_VALID_RANGE] ),
      .ValidBitToN ( datanet_north_o[`DATA_NET_FLIT_VALID_RANGE] ),
      .ValidBitToNI ( ValidBitFromVDN ),
      .ValidBitToS ( datanet_south_o[`DATA_NET_FLIT_VALID_RANGE] ),
      .ValidBitToW ( datanet_west_o[`DATA_NET_FLIT_VALID_RANGE] ),

      .VC_ToE ( datanet_east_o[`DATA_NET_FLIT_VC_RANGE] ),
      .VC_ToN ( datanet_north_o[`DATA_NET_FLIT_VC_RANGE] ),
      .VN_ToNI ( VnFromVDN ),
      .VC_ToS ( datanet_south_o[`DATA_NET_FLIT_VC_RANGE] ),
      .VC_ToW ( datanet_west_o[`DATA_NET_FLIT_VC_RANGE] )
    );

    // RECEIVED MESSAGE COUNTERS AND DISPLAYS  ---------------------------------------------------------------------------------------------------------
    localparam MS_TIMESTAMP_w = `MS_TIMESTAMP_w;
    localparam MS_OUT_TIMESTAMP_LSB = `MS_OUT_TIMESTAMP_LSB;
    localparam MS_OUT_TIMESTAMP_MSB = `MS_OUT_TIMESTAMP_MSB;

    //Incomming Flits from Switch output Local port
    wire                          valid = ValidBitFromVDN;
    wire [FLIT_SIZE-1:0]           flit = FlitfromVDN;
    wire [FLIT_TYPE_SIZE-1:0] flit_type = FlitTypefromVDN;
    wire [bits_VN-1 : 0]           VNID = VnFromVDN;

    //Flit/Message counter and latency calculus
    wire  [MS_TIMESTAMP_w-1:0] current_timestamp_i = timestamp[MS_TIMESTAMP_w-1:0];  // Current system timestamp
    wire                       incr_flit_o;
    wire                       incr_msg_o;
    wire [MS_TIMESTAMP_w-1:0] flit_latency_o;
    wire [MS_TIMESTAMP_w-1:0] msg_latency_o;

    wire ms_header = incr_flit_o & (flit_type == `header);
    wire ms_header_tail = incr_flit_o & (flit_type == `header_tail);
    wire ms_tail = incr_flit_o & (flit_type == `tail);

    wire                       timestamp_greater_than_current;
    wire                       header_timestamp_greater_than_current;

    wire [MS_TIMESTAMP_w-1:0] timestamp_from_flit;
    reg [MS_TIMESTAMP_w-1:0]  timestamp_last_header;

    assign incr_flit_o = valid & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `MS);
    assign incr_msg_o  = (ms_tail | ms_header_tail);

    assign flit_latency_o = (incr_flit_o & ~timestamp_greater_than_current) ? (current_timestamp_i - timestamp_from_flit  ):
                            (incr_flit_o                                  ) ? (`V_ALL1(MS_TIMESTAMP_w)-flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB]) + current_timestamp_i + 1: //flit_ts > current_ts
                                                                              `V_ZERO(MS_TIMESTAMP_w);

    assign msg_latency_o  = (ms_header_tail)                                      ? flit_latency_o :                                                            //header_tail case
                            (incr_msg_o & ~header_timestamp_greater_than_current) ? (current_timestamp_i - timestamp_last_header):                              //header case
                            (incr_msg_o                                         ) ? (`V_ALL1(MS_TIMESTAMP_w)-timestamp_last_header) + current_timestamp_i + 1: //header and flit_ts > current_ts
                                                                                    `V_ZERO(MS_TIMESTAMP_w);

    assign                       timestamp_greater_than_current = (flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB] > current_timestamp_i);
    assign                       header_timestamp_greater_than_current = (timestamp_last_header > current_timestamp_i);

    assign timestamp_from_flit = (incr_flit_o) ? flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB] : `V_ZERO(MS_TIMESTAMP_w);

    localparam lsb_tid = `WIDTH(GLBL_N_NxT);
    localparam msb_tid = 8;

    reg [63:0] Counter;
    always @ (posedge clk) begin
      if (rst_p) begin
          Counter   <= 64'd0;
          timestamp_last_header <= `V_ZERO(MS_TIMESTAMP_w);
        end else begin
        if (valid) begin
          if(flit_type==`header | flit_type==`header_tail) begin
            $display ("VN%2d, ejection node ID %3d, Header_Message from sender %3d, flit_latency %5d, COUNTER: %8d, at:%t\n", VNID, i, flit[11:0], flit_latency_o, (Counter+1), $realtime);
            Counter <= Counter + 64'd1;
          end //
          // Counter <= Counter + 64'd1;
          //if ((Counter%1000) == 0) begin
            // $display ("VN%d_eject: ID%0d, COUNTER: %d", VNID, i, Counter);
          //end
          if (incr_flit_o) begin
            // $display ("VN%1d_eject Flit: ID %1d, flit_latency %2d", VNID, i, flit_latency_o);
            if(ms_header)begin
              timestamp_last_header <= timestamp_from_flit;
            end // end receiving_ms_header
            else if(incr_msg_o) begin
              // $display ("VN%1d_eject Message: ID %1d, msg_latency %2d", VNID, i, msg_latency_o);
            end // end incr_msg
          end // end incr_flit

        end //end if valid

      end // end else rst_p
    end // end always

  end// for ... def_tiles
endgenerate


// logic for clock generation and system timestamp
initial begin
  // Initialize Inputs
  clk = 0;
  rst_p = 1;

  // Wait 100 ns for global reset to finish
  #100;
  rst_p = 0;

end//initial


always begin
  #5
  clk <= ~clk;
  timestamp <= timestamp + 1'b1;
end//always

always @(posedge clk, rst_p) begin
  if (rst_p) begin
    timestamp <= `V_ZERO(64);
  end else begin
    timestamp <= timestamp + 1'b1;
  end
end//always

endmodule;
