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
// Create Date:
// Design Name:
// Module Name:
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
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

module network_injector #(
  parameter ID                         = 0,                                                  // TILE ID
  parameter FLIT_SIZE                  = 64,                                                 // flit size
  parameter FLIT_TYPE_SIZE             = 2,                                                  // flit type size
  parameter PHIT_SIZE                  = 64,                                                 // phit syze
  parameter QUEUE_SIZE                 = 8,                                                  // queue size (per VN)
  parameter SG_UPPER_THOLD             = 5,                                                  // stop flow control threshold
  parameter SG_LOWER_THOLD             = 4,                                                  // go flow control threshold
  parameter NUM_VC                     = 1,                                                  // Number of Virtual Channels supported for each Virtual Network
  parameter NUM_VN                     = 3,                                                  // Number of Virtual Networks supported
  parameter VN_w                       = 2,                                                  // VN width
  parameter NUM_VN_X_VC                = NUM_VC * NUM_VN,                                    // number of queues (VNxVC)
  parameter NUM_INPUT_SOURCES          = 0,                                                  // Number of Input Sources to inject
  parameter BROADCAST_SIZE             = 5,                                                  // Broadcast field width
  parameter ENABLE_VN_WEIGHTS_SUPPORT  = "no",
  parameter VN_WEIGHT_VECTOR_w         = 0,
  //
  parameter ENABLE_MESSAGE_SYSTEM_SUPPORT = "no",
  parameter ENABLE_NETWORK_DEBUG_LEVEL_0_SUPPORT = "no",
  parameter  CORES_PER_TILE = 1,
  localparam LOG_CORES_PER_TILE = Log2_w(CORES_PER_TILE),
  localparam LOG_CORES_PER_TILE_GOOD    = Log2(CORES_PER_TILE),

  localparam MESSAGE_SYSTEM_ENABLED = (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes"),

  localparam VN_QUEUES                 = BROADCAST_SIZE + 1 + FLIT_TYPE_SIZE + FLIT_SIZE,    // internal injector queues that contains information to be injected belonging each VN

  localparam FLIT_TYPE_LSB             = FLIT_SIZE,                                          //
  localparam FLIT_TYPE_MSB             = FLIT_TYPE_LSB + (FLIT_TYPE_SIZE-1),                 //
  localparam QUEUE_VALID_BIT           = FLIT_TYPE_MSB + 1,                                  //
  localparam BROADCAST_LSB             = QUEUE_VALID_BIT + 1,                                //
  localparam BROADCAST_MSB             = BROADCAST_LSB + (BROADCAST_SIZE-1),                 //


  localparam NUM_INPUT_SOURCES_w       = Log2_w(NUM_INPUT_SOURCES),                          // number of bits required to code NUM_INPUT_SOURCES
  localparam IS_F_SIZE                 = FLIT_SIZE * NUM_INPUT_SOURCES,                      // input bus size providing flit of each IS
  localparam IS_FT_SIZE                = FLIT_TYPE_SIZE * NUM_INPUT_SOURCES,                 // input bus size providing flit type of each IS
  localparam IS_BC_SIZE                = BROADCAST_SIZE * NUM_INPUT_SOURCES,                 // input bus size providing broadcast of each IS
  localparam IS_VN_w                   = VN_w * NUM_INPUT_SOURCES,                           // number of bits required to code bits_VN of each IS
  localparam COUNTER_w                 = 64,                                                 // number of bits required to code the flit counter for simulation purposes
  localparam bits_VN_X_VC              = Log2_w(NUM_VN_X_VC),
  localparam FIFO_SIZE                 = 2,
  localparam FIFO_W                    = Log2_w(FIFO_SIZE),
  localparam NUM_PORTS                 = `NUM_PORTS,                                                   // Number of ports used in this network
  localparam NUM_PORTS_w               = Log2_w(NUM_PORTS),                                  // Number of bits needed to code NUM_PORTS number
  //localparam bits_VN                   = `DATA_NET_VN_w,
  localparam bits_VN                   = Log2_w(NUM_VN),
  //localparam bits_VC                   = `DATA_NET_NUM_VC_PER_VN_w,                          // Number of bits needed to code NUM_VC number
  localparam bits_VC                   = Log2_w(NUM_VC),                                                  // Number of bits needed to code NUM_VC number
  localparam NUM_VC_AND_PORTS          = NUM_VC * NUM_PORTS,                                 // Number of signals per port and each signal have one bit per VC
  localparam bits_VC_AND_PORTS         = Log2_w(NUM_VC_AND_PORTS),                           // Number of bits needed to code NUM_VC number
  localparam NUM_VN_X_VC_AND_PORTS     = NUM_VN_X_VC * NUM_PORTS,                            // Number of signals per port and each signal have one bit per VC
  localparam bits_VN_X_VC_AND_PORTS    = Log2_w(NUM_VN_X_VC_AND_PORTS),                      // Number of bits needed to code NUM_VC number
  localparam long_VC_assigns           = ((bits_VN_X_VC_AND_PORTS+1) * NUM_VN_X_VC),         // Bits neded to store bidimensional array like //{E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}, in Verilog is not supported a I/O bidimensional array port
  localparam long_VC_assigns_per_VN    = ((bits_VN_X_VC_AND_PORTS+1) * NUM_VC),              // The same last but only for one VN
  localparam long_VC_assigns_NI        = ((bits_VN_X_VC+1) * NUM_VN_X_VC),                   // Bits neded to store which input REQ (expresed in binary) is located in each VC
  localparam long_VC_assigns_NI_per_VN = ((bits_VN_X_VC+1) * NUM_VC),                        // The same last but only for one VN
  //localparam long_WEIGTHS              = `DATA_NET_VN_PRIORITY_VECTOR_w,                     // Number of bits needed to code NUM_VC number into weitgths priorities vector
  localparam long_WEIGTHS              = VN_WEIGHT_VECTOR_w,                                 // Number of bits needed to code NUM_VC number into weitgths priorities vector
  localparam long_vector_grants_id     = 3 * NUM_VN_X_VC,                                    // Number of bits needed to save the port id which is granted in each VC
  localparam FLIT_SIZE_VC              = FLIT_SIZE * NUM_VN_X_VC,                            // Size of full bus with all flit signals that belongs to each port
  localparam FLIT_TYPE_SIZE_VC         = FLIT_TYPE_SIZE * NUM_VN_X_VC,                       // Size of full bus with all flit_type signals that belongs to each port
  localparam FLIT_SIZE_VN              = FLIT_SIZE * NUM_VN,                                 // Size of full bus with all flit signals that belongs to each VN
  localparam FLIT_TYPE_SIZE_VN         = FLIT_TYPE_SIZE * NUM_VN,                            // Size of full bus with all flit_type signals that belongs to each VN
  localparam BROADCAST_FLIT_SIZE_VN    = BROADCAST_SIZE * NUM_VN                             // Size of full bus with all broadcast signals that belongs to each VN  localparam long_VC_assigns     = ((bits_VN_X_VC_AND_PORTS+1) * NUM_VN_X_VC),         // Bits neded to store bidimensional array like //{E*NUM_VC, S*NUM_VC, W*NUM_VC, N*NUM_VC, L*NUM_VC}, in Verilog is not supported a I/O bidimensional array port
)(
  input                                          clk,                                        // master input clock signal
  input                                          rst_p,                                      // asynchronous reset signal
  input [NUM_VN_X_VC-1:0]                        go,                                         // GO input signals from the network
  input  [VN_WEIGHT_VECTOR_w-1 : 0]              WeightsVector_i,                            // Weight vector to enforce bandwidth allocation to different virtual networks. The vector goes to SA arbiter
  input [IS_F_SIZE-1:0]                          flit_i,                                     // Input flits (all ports grouped)
  input [IS_FT_SIZE-1:0]                         flit_type_i,                                // Input flit types (all ports grouped)
  input [IS_BC_SIZE-1:0]                         bc_i,                                       // Input broadcast bits (all ports grouped)
  input [IS_VN_w-1:0]                            vn_i,                                       // VNs to use by each input (all ports grouped)
  input [NUM_INPUT_SOURCES-1:0]                  req_i,                                      // Valid (req) bits (all ports grouped)
  output [NUM_INPUT_SOURCES-1:0]                 avail_o,                                    // Avail signals to input ports (all ports grouped)

  input [FLIT_SIZE-1:0]                          flit_MS_i,                                  // Input flit from MS generator
  input [FLIT_TYPE_SIZE-1:0]                     flit_type_MS_i,                             // Input flit type from MS generator
  input [VN_w-1:0]                               vn_MS_i,                                    // Input VN to use from MS generator
  input                                          req_MS_i,                                   // Valid (req) bit from MS generator
  output                                         avail_MS_o,                                 // Avail signal to MS generator

  output [BROADCAST_SIZE-1:0]                    BroadcastFlitOut,                           // Ouput broadcast bits
  output [FLIT_SIZE-1:0]                         FlitOut,                                    // Output flit
  output [FLIT_TYPE_SIZE-1:0]                    FlitTypeOut,                                // Output flit type
  output                                         ValidOut,                                   // Output valid signal
  output [bits_VN_X_VC-1:0]                      VC_out                                      // Output VC encoded (it embeds the VN)
);

  `include "common_functions.vh"

  genvar i, j;

  if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin
    `define MESSAGE_SYSTEM_ENABLED
  end

  if (ENABLE_NETWORK_DEBUG_LEVEL_0_SUPPORT == "yes") begin
    `define NETWORK_DEBUG_LEVEL_0
  end



  // *************** CONVERSION FROM INPUT_SOURCES_BUSES ******************************************************
  wire [FLIT_SIZE-1:0]        w_flit [0:NUM_INPUT_SOURCES-1];
  wire [FLIT_TYPE_SIZE-1:0]   w_flit_type [0:NUM_INPUT_SOURCES-1];
  wire [BROADCAST_SIZE-1:0]   w_bc [0:NUM_INPUT_SOURCES-1];
  wire [VN_w-1:0]             w_vn [0:NUM_INPUT_SOURCES-1];

  generate
    for (i=0; i<NUM_INPUT_SOURCES; i=i+1)begin
      assign w_flit[i]      = flit_i[((i*FLIT_SIZE)+(FLIT_SIZE-1))-:FLIT_SIZE];
      assign w_flit_type[i] = flit_type_i[((i*FLIT_TYPE_SIZE)+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE];
      assign w_bc[i]        = bc_i[((i*BROADCAST_SIZE)+(BROADCAST_SIZE-1))-:BROADCAST_SIZE];
      assign w_vn[i]        = vn_i[((i*VN_w)+(VN_w-1))-:VN_w];
    end
  endgenerate

  //--------------------------------------------------------------------------------------------
  //*************** INPUT_SOURCES_BUFFERS ******************************************************
  // The following signals are the input queues and some aditional control wires for each input to ensure 100% injection rate
  reg [FLIT_SIZE-1:0]         r_queue_flit [0:FIFO_SIZE-1] [0:NUM_INPUT_SOURCES-1];               // Queues to save the incomming flits messages
  reg [FLIT_TYPE_SIZE-1:0]    r_queue_type [0:FIFO_SIZE-1] [0:NUM_INPUT_SOURCES-1];               // Queues to save the incomming flits types
  reg [BROADCAST_SIZE-1:0]    r_queue_bc   [0:FIFO_SIZE-1] [0:NUM_INPUT_SOURCES-1];               // Queues to save the incomming broadcasts

  reg [FIFO_W-1:0]            r_readPointer [0:NUM_INPUT_SOURCES-1];
  reg [FIFO_W-1:0]            r_writePointer [0:NUM_INPUT_SOURCES-1];
  reg [FIFO_W-1:0]            r_queued_messages [0:NUM_INPUT_SOURCES-1];

  wire [FLIT_SIZE-1:0]        w_flit_buff [0:NUM_INPUT_SOURCES-1];
  wire [FLIT_TYPE_SIZE-1:0]   w_flit_type_buff [0:NUM_INPUT_SOURCES-1];
  wire [BROADCAST_SIZE-1:0]   w_bc_buff [0:NUM_INPUT_SOURCES-1];

  wire                        w_queued [0:NUM_INPUT_SOURCES-1];
  wire                        w_pending [0:NUM_INPUT_SOURCES-1];
  generate
    for (i=0; i<NUM_INPUT_SOURCES; i=i+1)begin
      assign w_flit_buff[i] = r_queue_flit[r_readPointer[i]][i];                                   // -flit at read pointer of queue_flit
      assign w_flit_type_buff[i] = r_queue_type[r_readPointer[i]][i];                              // flit type at read pointer of queue_type
      assign w_bc_buff[i] = r_queue_bc[r_readPointer[i]][i];
      assign w_queued[i] = (r_queued_messages[i]>=`V_ONE(FIFO_SIZE));
      assign w_pending[i] = (r_queued_messages[i]!=`V_ZERO(FIFO_SIZE));
    end
  endgenerate


  //--------------------------------------------------------------------------------------------
  //*************** MESSAGE_SYSTEM_BUFFERS ******************************************************
  //The following signals are the input queues and some aditional control wires for MS to ensure 100% injection rate
  `ifdef MESSAGE_SYSTEM_ENABLED
  reg [FLIT_SIZE-1:0]         r_queue_flit_MS [0:FIFO_SIZE-1];                                    //Queues to save the MS incomming flits messages
  reg [FLIT_TYPE_SIZE-1:0]    r_queue_type_MS [0:FIFO_SIZE-1];                                    //Queues to save the MS incomming flits types
  reg [VN_w-1:0]           r_queue_vn_MS [0:FIFO_SIZE-1];                                      //Queues to save the MS incomming vn to inject

  reg [FIFO_W-1:0]            r_readPointer_MS;
  reg [FIFO_W-1:0]            r_writePointer_MS;
  reg [FIFO_W-1:0]            r_queued_messages_MS;

  wire [FLIT_SIZE-1:0]        w_flit_buff_MS;
  wire [FLIT_TYPE_SIZE-1:0]   w_flit_type_buff_MS;
  wire [VN_w-1:0]             w_dest_vn_buff_MS;

  wire                        w_queued_MS;
  wire                        w_pending_MS;

  assign w_flit_buff_MS = r_queue_flit_MS[r_readPointer_MS];                                          //flit at read pointer of queue_flit
  assign w_flit_type_buff_MS = r_queue_type_MS[r_readPointer_MS];                                    //flit type at read pointer of queue_type
  assign w_dest_vn_buff_MS = r_queue_vn_MS[r_readPointer_MS];                                         //dest_vn at read pointer of queue_vn
  assign w_queued_MS = (r_queued_messages_MS>=`V_ONE(FIFO_SIZE));
  assign w_pending_MS = (r_queued_messages_MS!=`V_ZERO(FIFO_SIZE));
  `endif

  //--------------------------------------------------------------------------------------------
  //*************** SIGNALS FOR EACH VN ********************************************************
  reg                           r_unassigned_VN [0:NUM_VN-1];
  reg [NUM_INPUT_SOURCES-1:0]   r_IS_asigned_to_VN [0:NUM_VN-1];
  `ifdef MESSAGE_SYSTEM_ENABLED
  reg [NUM_VN-1:0]              r_asigned_to_MS;
  `endif

  wire [NUM_INPUT_SOURCES-1:0]  w_IS_pending_to_VN [0:NUM_VN-1];
  wire [NUM_INPUT_SOURCES-1:0]  w_IS_avail_to_VN [0:NUM_VN-1];
  wire [NUM_VN-1:0] w_each_IS_VN_avail [0:NUM_INPUT_SOURCES-1]; //inverse matrix of w_IS_avail_to_VN

  `ifdef MESSAGE_SYSTEM_ENABLED
  wire  [NUM_VN-1:0]            w_avail_to_MS;
  `endif
  wire                          w_write       [0:NUM_VN-1];
  wire [FLIT_SIZE-1:0]          w_flit_to_write [0:NUM_VN-1];
  wire [FLIT_TYPE_SIZE-1:0]     w_flit_type_to_write [0:NUM_VN-1];
  wire [BROADCAST_SIZE-1:0]     w_bc_to_write [0:NUM_VN-1];
//---------------------------------------------------------------------------------------------------------------
//*************** SWITCH FUNCTIONALITY FOR EACH VN USING WRITING SIGNALS ****************************************
//WARNING!! Previous implementations have been failed due to GoBitOut was used before its declaration

//Aditional wires
wire [NUM_VN_X_VC-1 :0] Request_SA;     //Request output port for each channel granted
wire [NUM_VN_X_VC-1 :0] Grant_SA;     //Granted output for each channel
wire [long_VC_assigns_NI-1:0] VC_assigns; //Vector in wich indicates the index of Grant_VA is asigned for each channel.
wire free_VC;             //Indicates that one VC is released in this cycle
wire [bits_VN_X_VC-1:0] vc_selected;      //Virtual Channel granted from VA
wire [bits_VN_X_VC-1:0] vc_to_release;
wire [FLIT_SIZE_VN-1:0] Pre_Flit;
wire [FLIT_TYPE_SIZE_VN-1:0] Pre_FlitType;
wire [BROADCAST_FLIT_SIZE_VN-1:0] Pre_BroadcastFlit;

wire [VN_QUEUES-1:0] QUEUE_VN [0:NUM_VN-1];   //Input data QUEUE
wire [NUM_VN-1:0] GoBitOut;           //Go bit from each IMPUT BUFFER of each VN
//--------------------------------------------------------------------------------------------------------------------------------
//*************** INPUT AND OUTPUT AVAIL SIGNALS ****************************************************************

wire [NUM_INPUT_SOURCES-1:0] rr_vector_in  [0:NUM_VN-1];
wire [NUM_INPUT_SOURCES-1:0] rr_vector_out  [0:NUM_VN-1];
generate
  for (i=0; i<NUM_VN; i=i+1)begin
    for (j=0; j<NUM_INPUT_SOURCES; j=j+1)begin
        assign w_IS_pending_to_VN[i][j] = (w_pending[j] & (w_vn[j]==i));
        assign rr_vector_in[i][j] = r_unassigned_VN[i] & w_IS_pending_to_VN[i][j];

        // Avail signals. These signals indicate if a buffered flit at an input port can be written to the VN queues
        assign w_IS_avail_to_VN[i][j] = GoBitOut[i] & (rr_vector_out[i][j] | (w_IS_pending_to_VN[i][j] & r_IS_asigned_to_VN[i][j]));
        assign w_each_IS_VN_avail[j][i] = w_IS_avail_to_VN[i][j];

        // The following signals are the available signals sent to the upstream blocks that inject flits to this module
        assign avail_o[j] = ~w_queued[j] | (|w_each_IS_VN_avail[j]);
    end// end for j

    `ifdef MESSAGE_SYSTEM_ENABLED
        assign w_avail_to_MS[i] = (NUM_INPUT_SOURCES > 0) ? ((GoBitOut[i] & r_unassigned_VN[i] & w_pending_MS & (w_dest_vn_buff_MS==i) & ~(|w_IS_pending_to_VN[i])) | //in case there is input sources
                                                 (GoBitOut[i] & r_asigned_to_MS[i] & w_pending_MS & (w_dest_vn_buff_MS==i))) :

                                                ((GoBitOut[i] & r_unassigned_VN[i] & w_pending_MS & (w_dest_vn_buff_MS==i)) |               //in case there is no input sources
                                                 (GoBitOut[i] & r_asigned_to_MS[i] & w_pending_MS & (w_dest_vn_buff_MS==i)));
    `endif

    //The following RR arbiters will grant only one request for each VN
    RR_X_IN #(
    .IO_SIZE(NUM_INPUT_SOURCES),
    .IO_w(NUM_INPUT_SOURCES_w),
    .OUTPUT_ID("no"),
    .SHUFFLE("no"),
    .SUFFLE_DIM_1(NUM_VN),
    .SUFFLE_DIM_2(NUM_VC)
    )round_robin_VN_IS(
    .vector_in(rr_vector_in[i]),
    .clk(clk),
    .rst_p(rst_p),
    .GRANTS_IN(w_IS_avail_to_VN[i]),
    .vector_out(rr_vector_out[i]),
    .grant_id());
  end
endgenerate
//---------------------------------------------------------------------------------------------------------------
// The following signals are the available signals sent to the upstream blocks that inject flits to this module
`ifdef MESSAGE_SYSTEM_ENABLED
      assign avail_MS_o = ~w_queued_MS | (|w_avail_to_MS);
`endif
//---------------------------------------------------------------------------------------------------------------
//*************** WRITING SIGNALS *******************************************************************************
generate
  for (i=0; i<NUM_VN; i=i+1)begin
    wire [NUM_INPUT_SOURCES_w-1:0] vector_id_encoder;
    wire [NUM_INPUT_SOURCES-1:0] grant_in_encoder = w_IS_avail_to_VN[i];
    encoder #(
         .lenght_in(NUM_INPUT_SOURCES),
         .lenght_out(NUM_INPUT_SOURCES_w)
         ) encoder_64 (
            .enable(|(64'd0+grant_in_encoder)),
            .vector_in(grant_in_encoder),
            .vector_id(vector_id_encoder)
        );

    assign w_flit_to_write[i] =       (NUM_INPUT_SOURCES > 0) ? ((|w_IS_avail_to_VN[i]) ? w_flit_buff[vector_id_encoder] :              //in case there is input sources
                                                    `ifdef MESSAGE_SYSTEM_ENABLED (w_avail_to_MS[i]) ? w_flit_buff_MS:`endif
                                                    `V_ZERO(FLIT_SIZE)) :

                                `ifdef MESSAGE_SYSTEM_ENABLED (w_avail_to_MS[i]) ? w_flit_buff_MS:`endif          //in case there is no input sources
                                                    `V_ZERO(FLIT_SIZE);

    assign w_flit_type_to_write[i] =  (NUM_INPUT_SOURCES > 0) ? ((|w_IS_avail_to_VN[i]) ? w_flit_type_buff[vector_id_encoder] :           //in case there is input sources
                                                      `ifdef MESSAGE_SYSTEM_ENABLED (w_avail_to_MS[i]) ? w_flit_type_buff_MS:`endif
                                                      `V_ZERO(FLIT_TYPE_SIZE)) :

                                `ifdef MESSAGE_SYSTEM_ENABLED (w_avail_to_MS[i]) ? w_flit_type_buff_MS:`endif       //in case there is no input sources
                                                      `V_ZERO(FLIT_TYPE_SIZE);

    assign w_bc_to_write[i] =         (NUM_INPUT_SOURCES > 0) ? ((|w_IS_avail_to_VN[i]) ? w_bc_buff[vector_id_encoder] : `V_ZERO(BROADCAST_SIZE)) : //in case there is input sources
                                  `V_ZERO(BROADCAST_SIZE);                              //in case there is no input sources

    assign w_write[i] =               (NUM_INPUT_SOURCES > 0) ? ((|w_IS_avail_to_VN[i])  `ifdef MESSAGE_SYSTEM_ENABLED | (w_avail_to_MS[i]) `endif) :   //in case there is input sources
                                     `ifdef MESSAGE_SYSTEM_ENABLED (w_avail_to_MS[i]) `else 1'b0 `endif;            //in case there is no input sources
  end
endgenerate
//---------------------------------------------------------------------------------------------------------------

   generate
    for (i=0; i<NUM_VN; i=i+1)begin : VN
      wire [NUM_VC-1 :0] REQ__FROM__RT__TO__VA;     //Request Virtual Channel for each VN
    wire [NUM_VC-1 :0] GRANT__FROM__VA__TO__RT;     //Grant one VC for each VN
    wire RT_READYFORREQ__FROM__RT__TO__IB;
    wire [FLIT_SIZE-1:0] FLIT__FROM__IB__TO__RT;
    wire [FLIT_TYPE_SIZE-1:0] FLITTYPE__FROM__IB__TO__RT;
    wire BCFLIT__FROM__IB__TO__RT;
    wire REQ__FROM__IB__TO__RT;
    wire BCFLIT__FROM__RT__TO__O;

    assign QUEUE_VN[i][FLIT_SIZE-1:0] =               w_flit_to_write[i];

    assign QUEUE_VN[i][FLIT_TYPE_MSB:FLIT_TYPE_LSB] = w_flit_type_to_write[i];

    assign QUEUE_VN[i][BROADCAST_MSB:BROADCAST_LSB] = w_bc_to_write[i];

    assign QUEUE_VN[i][QUEUE_VALID_BIT] =             w_write[i];
    end
   endgenerate

   generate
    for (i=0; i<NUM_VN; i=i+1)begin

      IBUFFER_NI #(
     .ID                 ( ID                       ),
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE                ),
     .QUEUE_SIZE         ( QUEUE_SIZE               ),
     .SG_UPPER_THOLD     ( SG_UPPER_THOLD           ),
     .SG_LOWER_THOLD     ( SG_LOWER_THOLD           ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   )
     ) IBUFFER_VN (
     .clk(clk),
     .rst_p(rst_p),
     .Flit(QUEUE_VN[i][FLIT_SIZE-1:0]),
     .FlitType(QUEUE_VN[i][FLIT_TYPE_MSB:FLIT_TYPE_LSB]),
     .BroadcastFlit(QUEUE_VN[i][BROADCAST_MSB/*:BROADCAST_LSB*/]),
     .Valid(QUEUE_VN[i][QUEUE_VALID_BIT]),
     .Avail(VN[i].RT_READYFORREQ__FROM__RT__TO__IB),
     .FlitOut(VN[i].FLIT__FROM__IB__TO__RT[FLIT_SIZE-1:0]),
     .FlitTypeOut(VN[i].FLITTYPE__FROM__IB__TO__RT[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlitOut(VN[i].BCFLIT__FROM__IB__TO__RT),
     .Go(GoBitOut[i]),
     .Req_RT(VN[i].REQ__FROM__IB__TO__RT));

      ROUTING_NI #(
     .ID                 ( ID                       ),
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE                ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   )
     ) ROUTING_VN (
     .clk(clk),
     .rst_p(rst_p),
     .Req(VN[i].REQ__FROM__IB__TO__RT),
     .Flit(VN[i].FLIT__FROM__IB__TO__RT[FLIT_SIZE-1:0]),
     .FlitType(VN[i].FLITTYPE__FROM__IB__TO__RT[FLIT_TYPE_SIZE-1:0]),
     .BroadcastFlit(VN[i].BCFLIT__FROM__IB__TO__RT),
     .Grant_VA_FromL(VN[i].GRANT__FROM__VA__TO__RT),
     .Grant_SA_FromL(Grant_SA[((i*NUM_VC)+(NUM_VC-1))-:NUM_VC]),
     .FlitOut(Pre_Flit[((i*FLIT_SIZE)+(FLIT_SIZE-1))-:FLIT_SIZE]),
     .FlitTypeOut(Pre_FlitType[((i*FLIT_TYPE_SIZE)+(FLIT_TYPE_SIZE-1))-:FLIT_TYPE_SIZE]),
     .BroadcastFlitL(VN[i].BCFLIT__FROM__RT__TO__O),
     .Request_VA_L(VN[i].REQ__FROM__RT__TO__VA),
     .Request_SA_L(Request_SA[((i*NUM_VC)+(NUM_VC-1))-:NUM_VC]),
     .Avail(VN[i].RT_READYFORREQ__FROM__RT__TO__IB));

      assign Pre_BroadcastFlit[((i*BROADCAST_SIZE)+(BROADCAST_SIZE-1))-:BROADCAST_SIZE] = (VN[i].BCFLIT__FROM__RT__TO__O) ? {BROADCAST_SIZE{1'b1}} : {BROADCAST_SIZE{1'b0}};

      VA_NI_DYNAMIC #(
     .ID                 ( ID                       ),
     .FLIT_SIZE          ( FLIT_SIZE                ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
     .PHIT_SIZE          ( PHIT_SIZE                ),
     .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
     .NUM_VC             ( NUM_VC                   ),
     .NUM_VN             ( NUM_VN                   ),
     .VN_WEIGHT_VECTOR_w ( VN_WEIGHT_VECTOR_w       )
     ) VA_NI_DYNAMIC_inst0(
     .id(i),
     .clk(clk),
     .rst_p(rst_p),
     .REQ(VN[i].REQ__FROM__RT__TO__VA),
     .free_VC_in(free_VC),
     .VC_released_in(vc_to_release),
     .VC_assigns_out(VC_assigns[((i*long_VC_assigns_NI_per_VN)+(long_VC_assigns_NI_per_VN-1))-:long_VC_assigns_NI_per_VN]),
     .GRANTS(VN[i].GRANT__FROM__VA__TO__RT));
    end
endgenerate

    SA_NI #(
    .ID                        ( ID                        ),
    .FLIT_SIZE                 ( FLIT_SIZE                 ),
    .FLIT_TYPE_SIZE            ( FLIT_TYPE_SIZE            ),
    .BROADCAST_SIZE            ( BROADCAST_SIZE            ),
    .PHIT_SIZE                 ( PHIT_SIZE                 ),
    .NUM_VC                    ( NUM_VC                    ),
    .NUM_VN                    ( NUM_VN                    ),
    .ENABLE_VN_WEIGHTS_SUPPORT ( ENABLE_VN_WEIGHTS_SUPPORT )
    )SA_NI_inst0(
    .clk(clk),
    .rst_p(rst_p),
    .go(go),
    .WeightsVector_in(WeightsVector_i),
    .REQ(Request_SA),
    .VC_assigns_in(VC_assigns),
    .GRANTS(Grant_SA),
    .vc_selected_out(vc_selected)
  );

  wire [bits_VN_X_VC-1:0] vector_id_Grant_SA;
    encoder #(
         .lenght_in(NUM_VN_X_VC),
         .lenght_out(bits_VN_X_VC)
         ) encoder_64_SA (
            .enable(|(64'd0+Grant_SA)),
            .vector_in(Grant_SA),
            .vector_id(vector_id_Grant_SA)
        );

    wire [VN_w-1:0] vn_selected = (vector_id_Grant_SA/NUM_VC);

  OUTPUT_NI #(
  .ID                 ( ID                       ),
  .FLIT_SIZE          ( FLIT_SIZE                ),
  .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE           ),
  .PHIT_SIZE          ( PHIT_SIZE                ),
  .BROADCAST_SIZE     ( BROADCAST_SIZE           ),
  .NUM_VC             ( NUM_VC                   ),
  .NUM_VN             ( NUM_VN                   )
  )OUTPUT_NI_inst0 (
  .clk(clk),
  .rst_p(rst_p),
  .Pre_Flit(Pre_Flit),
  .Pre_FlitType(Pre_FlitType),
  .Pre_BroadcastFlit(Pre_BroadcastFlit),
  .GRANTS(Grant_SA),
  .vc_selected(vc_selected),

  .free_VC(free_VC),
  .VC_out(VC_out),
  .vc_to_release(vc_to_release),
  .FlitOut(FlitOut),
  .FlitTypeOut(FlitTypeOut),
  .BroadcastFlitOut(BroadcastFlitOut),
  .Valid(ValidOut)
  );
//---------------------------------------------------------------------------------------------------------------
integer x,z;
`ifdef NETWORK_DEBUG_LEVEL_0
reg [COUNTER_w-1:0] Counter_VN [0:NUM_VN-1];
`endif
    always @ (posedge clk)
if (rst_p) begin

  for(x=0; x<NUM_INPUT_SOURCES; x=x+1) begin
    r_readPointer[x] <= `V_ZERO(FIFO_W);
    r_writePointer[x] <= `V_ZERO(FIFO_W);
    r_queued_messages[x] <= `V_ZERO(FIFO_W);
  end

  `ifdef MESSAGE_SYSTEM_ENABLED
  r_readPointer_MS <= `V_ZERO(FIFO_W);
  r_writePointer_MS <= `V_ZERO(FIFO_W);
  r_queued_messages_MS <= `V_ZERO(FIFO_W);
  r_asigned_to_MS <= `V_ZERO(NUM_VN);
  `endif

  for(x=0; x<NUM_VN; x=x+1) begin
    r_unassigned_VN[x] <= 1'b1;
    r_IS_asigned_to_VN[x] <= `V_ZERO(NUM_INPUT_SOURCES);
  end


  `ifdef NETWORK_DEBUG_LEVEL_0
  for(x=0; x<NUM_VN; x=x+1) begin
    Counter_VN[x] <= `V_ZERO(COUNTER_w);
  end
  `endif

end else begin //********************************************************************************************************************************************************************************************

//  `ifdef NETWORK_DEBUG_LEVEL_0
//  for(x=0; x<NUM_VN; x=x+1) begin
//    if(w_write[x]) $display("            VN%0d INJECT: %h SRC: %d DST: %d TYPE %h", x, QUEUE_VN[x][FLIT_SIZE-1:0], ID, QUEUE_VN[x][`MSG_TLDST_MSB:`MSG_TLDST_LSB], QUEUE_VN[x][FLIT_TYPE_MSB:FLIT_TYPE_LSB]);
//  end // end for
//  `endif

// The follwing logic registers incoming flits through the incoming ports
for(x=0; x<NUM_INPUT_SOURCES; x=x+1) begin
  if(req_i[x]) begin
    if((w_flit_type[x] == `header | w_flit_type[x] == `header_tail) &  w_flit[x][`MSG_NTDST_MSB:`MSG_DST_LSB] != `MS) begin
      if((ID!=0) | (w_flit[x][`MSG_NTDST_MSB:`MSG_DST_LSB] == `L1_cache)) begin
        $display("VN%0d Before INJECT: ID%1d, DST%1d, at:%t, FlitInfo:%h\n", vn_i[x], ID, w_flit[x][`MSG_TLDST_MSB:`MSG_OFDST_LSB], $realtime, w_flit[x]);
      end
    end
    r_queue_flit[r_writePointer[x]][x] <= w_flit[x];
    r_queue_type[r_writePointer[x]][x] <= w_flit_type[x];
    r_queue_bc[r_writePointer[x]][x] <= w_bc[x];
    if(~(|w_each_IS_VN_avail[x]))begin
      r_queued_messages[x] <= r_queued_messages[x] + `V_ONE(FIFO_W);
    end
    if( r_writePointer[x] == (FIFO_SIZE-1) ) begin
        r_writePointer[x] <= `V_ZERO(FIFO_W);
    end else begin
        r_writePointer[x] <= r_writePointer[x] + `V_ONE(FIFO_W);
    end //update writePointer
  end// end req
end// end for

`ifdef MESSAGE_SYSTEM_ENABLED
if(req_MS_i) begin
  r_queue_flit_MS[r_writePointer_MS] <= flit_MS_i;
  r_queue_type_MS[r_writePointer_MS] <= flit_type_MS_i;
  r_queue_vn_MS[r_writePointer_MS] <= vn_MS_i;
  if(~(|w_avail_to_MS))begin
    r_queued_messages_MS <= r_queued_messages_MS + `V_ONE(FIFO_W);
  end
  if( r_writePointer_MS == (FIFO_SIZE-1) ) begin
        r_writePointer_MS <= `V_ZERO(FIFO_W);
  end else begin
        r_writePointer_MS <= r_writePointer_MS + `V_ONE(FIFO_W);
  end //update writePointer_MS
end// end req_MS
`endif
 // ----------------------------------------------------------------------
 // The following logic deals with departure of flits from the input buffers to the VN queues
for(x=0; x<NUM_VN; x=x+1) begin

  for(z=0; z<NUM_INPUT_SOURCES; z=z+1) begin
    if(w_IS_avail_to_VN[x][z])begin
      if(~req_i[z])begin
        r_queued_messages[z] <= r_queued_messages[z] - `V_ONE(FIFO_W);
      end// ~req
      if( r_readPointer[z] == (FIFO_SIZE-1) ) begin
        r_readPointer[z] <= `V_ZERO(FIFO_W);
      end else begin
        r_readPointer[z] <= r_readPointer[z] + `V_ONE(FIFO_W);
      end //update readPointer
      if(w_flit_type_buff[z] == `header) begin
        r_IS_asigned_to_VN[x][z] <= 1'b1;
        r_unassigned_VN[x] <= 1'b0;
      end else if ((w_flit_type_buff[z] == `tail) || (w_flit_type_buff[z] == `header_tail)) begin
        r_IS_asigned_to_VN[x][z] <= 1'b0;
        r_unassigned_VN[x] <= 1'b1;
      end
    end//end if w_IS_avail_to_VN
  end// end for z

  `ifdef MESSAGE_SYSTEM_ENABLED
  if(NUM_INPUT_SOURCES > 0) begin
    if(~(|w_IS_avail_to_VN[x]) & w_avail_to_MS[x])begin
      if (~req_MS_i)begin
        r_queued_messages_MS <= r_queued_messages_MS - `V_ONE(FIFO_W);
      end// end ~req_MS
      if( r_readPointer_MS == (FIFO_SIZE-1) ) begin
          r_readPointer_MS <= `V_ZERO(FIFO_W);
      end else begin
          r_readPointer_MS <= r_readPointer_MS + `V_ONE(FIFO_W);
      end //update readPointer_MS
      if (w_flit_type_buff_MS == `header) begin
          r_asigned_to_MS[x] <= 1'b1;
          r_unassigned_VN[x] <= 1'b0;
      end else if ((w_flit_type_buff_MS == `tail) || (w_flit_type_buff_MS == `header_tail)) begin
          r_asigned_to_MS[x] <= 1'b0;
          r_unassigned_VN[x] <= 1'b1;
      end
    end// end avail_to_MS
  end else begin
    if(w_avail_to_MS[x])begin
      if (~req_MS_i)begin
        r_queued_messages_MS <= r_queued_messages_MS - `V_ONE(FIFO_W);
      end// end ~req_MS
      if( r_readPointer_MS == (FIFO_SIZE-1) ) begin
          r_readPointer_MS <= `V_ZERO(FIFO_W);
      end else begin
          r_readPointer_MS <= r_readPointer_MS + `V_ONE(FIFO_W);
      end //update readPointer_MS
      if (w_flit_type_buff_MS == `header) begin
          r_asigned_to_MS[x] <= 1'b1;
          r_unassigned_VN[x] <= 1'b0;
      end else if ((w_flit_type_buff_MS == `tail) || (w_flit_type_buff_MS == `header_tail)) begin
          r_asigned_to_MS[x] <= 1'b0;
          r_unassigned_VN[x] <= 1'b1;
      end
    end// end avail_to_MS
  end
  `endif

end// end for x
//----------------------------------------------------------------------------
// The following code manages counters for simulation purposes
`ifdef NETWORK_DEBUG_LEVEL_0
for(x=0; x<NUM_VN; x=x+1) begin
  if (QUEUE_VN[x][QUEUE_VALID_BIT] & (QUEUE_VN[x][`MSG_NTDST_MSB:`MSG_DST_LSB] != `MS))begin
    Counter_VN[x] <= Counter_VN[x] + `V_ONE(COUNTER_w);
//    if ((Counter_VN[x]%1000) == 0) begin
      if((ID!=0) | (QUEUE_VN[x][`MSG_NTDST_MSB:`MSG_DST_LSB] == `L1_cache)) begin
        $display("VN%0d INJECT: ID%1d, DST%1d, COUNTER: %0d, at:%t, FlitInfo:%h\n", x, ID, QUEUE_VN[x][`MSG_TLDST_MSB:`MSG_OFDST_LSB], Counter_VN[x], $realtime, QUEUE_VN[x][FLIT_SIZE-1:0]);
      end
//    end // end display
  end // end valid bit
end //end for
`endif
// ---------------------------------------------------------------------------

end//rst_p

endmodule
