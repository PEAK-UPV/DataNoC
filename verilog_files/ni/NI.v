//////////////////////////////////////////////////////////////////////////////////
// (c) Copyright 2012 - 2016  Parallel Architectures Group (GAP)
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
// Engineer:  J. Flich (jflich@disca.upv.es)
//
// Create Date: 
// Design Name: 
// Module Name: NI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//  Network interface component (one per tile)
//
// Dependencies: NONE
//
// Revision:
//   Revision 0.01 - File Created
//
// Additional Comments: NONE
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`include "peak_system_parameters.h"

module NI #(
  parameter ENABLE_MESSAGE_SYSTEM_SUPPORT         = "no",
  parameter ENABLE_RHM_SUPPORT                    = "no",
  parameter ID                                    = 0,
  parameter NUM_NODES                             = 1,
  parameter CORES_PER_TILE                        = 1,  // CORES PER TILE
  parameter NUM_VC                                = 1,  // Number of Virtual Channels supported
  parameter NUM_VN                                = 1,  // Number of Virtual Networks supported
  parameter ENABLE_GN_DEBUG_LEVEL_0_SUPPORT       = "no",
  parameter ENABLE_NETWORK_DEBUG_LEVEL_0_SUPPORT  = "no",
  parameter ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT  = "no",
  parameter FLIT_SIZE                             = 64,
  parameter FLIT_TYPE_SIZE                        = 2,
  parameter ENABLE_FLIT_DEBUG_SUPPORT             = "no",
  parameter INJECT_QUEUE_SIZE                     = 8,
  parameter IB_SG_UPPER_THOLD                     = 5,                                                  // stop flow control threshold
  parameter IB_SG_LOWER_THOLD                     = 4,                                                  // go flow control threshold
  parameter NODE_ID_w                             = `NODE_ID_w,
  parameter VN_WEIGHT_VECTOR_w                    = 1,
  parameter VN_w                                  = 2,
  parameter NUM_VN_X_VC                           = 3,
  parameter ENABLE_VN_WEIGHTS_SUPPORT             = "no",
  parameter ENABLE_DEBUG_SUPPORT_INJECT           = "no",
  parameter ENABLE_DEBUG_SUPPORT_EJECT            = "no",
  localparam LOG_CORES_PER_TILE                   = Log2_w(CORES_PER_TILE),     // Log number of cores per tile
  localparam width_xxx_dest                       = Log2_w(CORES_PER_TILE),
  localparam FLAGS_w                              = `NID_FLAG_w,
  localparam NID_w                                = `NID_ID_w,
  localparam NID_ID_w                             = NID_w-1, 
  localparam bits_VC                              = Log2(NUM_VC),                          // Number of bits needed to code NUM_VC number
  localparam bits_VN                              = Log2(NUM_VN),                          // Number of bits needed to code NUM_VN number
  localparam bits_VN_X_VC                         = Log2(NUM_VN_X_VC),
  localparam PHIT_SIZE                            = FLIT_SIZE,
  localparam QUEUE_SIZE                           = INJECT_QUEUE_SIZE,
  localparam DATA_NET_FLIT_w                      = FLIT_SIZE, 
  localparam BC_w                                 = 5
)(
  input [31:0]                                      AddressFromL1,
  input [31:0]                                      AddressFromL2,
  input [31:0]                                      AddressFromMC,
  input [`TLID_w-1:0]                               HomeFromL1,
  input                                             ValidHomeFromL1,
  input [`TLID_w-1:0]                               HomeFromL2,
  input                                             ValidHomeFromL2,    
  input [511:0]                                     BlockFromL1,
  input [511:0]                                     BlockFromL2,
  input [511:0]                                     BlockFromMC,
  input                                             Broadcast1FromL2,
  input                                             Broadcast2FromL2,
  output                                            broadcast_toL1D,
  output                                            broadcast_toL2,
  input                                             clk,
  input [5:0]                                       Command1FromL1,
  input [5:0]                                       Command1FromL2,
  input [5:0]                                       Command2FromL1,
  input [5:0]                                       Command2FromL2,
  input [NODE_ID_w-1:0]                             Dst,
  input [2:0]                                       DstType1FromL1,
  input [2:0]                                       DstType1FromL2,
  input [2:0]                                       DstType2FromL1,
  input [2:0]                                       DstType2FromL2,
  input [NUM_NODES-1:0]                             DstVector1FromL1,
  input [NUM_NODES-1:0]                             DstVector1FromL2,
  input [NUM_NODES-1:0]                             DstVector2FromL1,
  input [NUM_NODES-1:0]                             DstVector2FromL2,
  input                                             FETCH,
  input [63:0]                                      FlitFromDN,    	
  input [1:0]                                       FlitTypeFromDN,
  input [NUM_VN_X_VC-1:0]                           GoFromDN,             
  input                                             ValidBitFromDN,       
  input [bits_VN-1:0]                               VnFromVDN,      
  input                                             BroadcastBit_fromVDN,
  input [VN_WEIGHT_VECTOR_w-1:0]                    WeightsVector_i,             // VNwithPriorities. New weights vector to guarante various bandwidths to different virtual networks. It vector is going to SA Routing arbiters
  input [31:0]                                      IADDRESS,
  input [`ACK_w-1:0]                                NumACKsFromL1,
  input [`ACK_w-1:0]                                NumACKsFromL2,
  input [CORES_PER_TILE-1:0]                        ReadAvailableFromL1,
  input                                             ReadAvailableFromL2,
  input                                             ReadAvailableFromMC,
  input                                             REQ_RD,
  input [`REG_w-1:0]                                REQ_RD_REG,
  input [`TLID_w-1:0]                               REQ_RD_TILE,
  input                                             REQ_WR,
  input [31:0]                                      REQ_WR_DATA,
  input [`REG_w-1:0]                                REQ_WR_REG,
  input [`TLID_w-1:0]                               REQ_WR_TILE,
  input                                             rst_p,
  input [NODE_ID_w-1:0]                             SenderFromL1,
  input [NODE_ID_w-1:0]                             SenderFromL2,
  input [NODE_ID_w-1:0]                             SenderFromMC,
  input [31:0]                                      TR_DataFromTR,
  input [`TLID_w-1:0]                               TR_DST_TILE,
  input                                             TR_ReadCompleted,
  input [CORES_PER_TILE-1:0]                        WriteAvailableFromL1,
  input [CORES_PER_TILE-1:0]                        TR_available,
  input                                             WriteAvailableFromL2,
  input                                             WriteAvailableFromMC,
  input                                             WriteNIBufferFromL1,
  input                                             WriteNIBufferFromL2,
  input                                             WriteNIBufferFromMC,
  input [38:0]                                      MessageSystem_in,                     // message system. req(1) + num_flits(16) + type(4) + sender(9) + dest(9)
  output [38:0]                                     MessageSystem_out,                    // message system. req(1) + num_flits(16) + type(4) + sender(9)
  input [CORES_PER_TILE-1:0]                        avail_tr_to_ms,                       // message system.
  input [63:0]                                      timestamp_in,
  input                                             debugFlit_enabled,                    // flit debug
  output                                            debug_inj_valid_o,
  output [`DEBUG_INJECT_w-1:0]                      debug_inj_o,                          // flit debug. Debug NI, First Flit to inject in VN
  output                                            debug_eje_valid_o,
  output [`DEBUG_EJECT_w-1:0]                       debug_eje_o,                          // flit debug. Debug NI, First Flit from VN  
  input [FLAGS_w-1:0]                               FlagsToGN,                            // rhm support. Flags comming from L2
  output [FLAGS_w-1:0]                              FlagsFromGN,                          // rhm support. Flags to L2
  output [FLAGS_w-1:0]                              NIDs_output_flags,                    // rhm support. Flags to inject into NID
  output [NID_w-1:0]                                NIDs_output_id,                       // rhm support. ID to inject into NID
  input [FLAGS_w-1:0]                               NIDs_input_flags,                     // rhm support. Flags comming from NID
  input [NID_w-1:0]                                 NIDs_input_id,                        // rhm support. ID comming from NID
  output [31:0]                                     AddressToL1,
  output [`TLID_w-1:0]                              HomeToL1,
  output [31:0]                                     AddressToL2,
  output [31:0]                                     AddressToMC,
  output [511:0]                                    BlockToL1,
  output [511:0]                                    BlockToL2,
  output [511:0]                                    BlockToMC,  
  output                                            FETCH_COMPLETED,
  output [63:0]                                     FlitToDN,                                   
  output [1:0]                                      FlitTypeToDN,                                           
  output                                            ValidBitToDN,                                              
  output [NUM_VN-1:0]                               GoToDN,                                                          
  output [4:0]                                      BroadcastBitsToDN,                              
  output [bits_VN_X_VC-1:0]                         VcToDN,
  output [511:0]                                    IDATA,
  output [25:0]                                     BLOCK_ADDRESS,
  output [5:0]                                      MessageTypeToL1,
  output [5:0]                                      MessageTypeToL2,
  output                                            NIBufferToL1Free,
  output                                            NIBufferToL2Free,
  output                                            NIBufferToMCFree,
  output                                            NI_buff_CORE_rd_avail,
  output                                            NI_buff_CORE_wr_avail,
  output                                            NI_buff_L1I_avail,
  output                                            NI_buff_TR_avail,
  output [`ACK_w-1:0]                               NumAcksToL1,
  output [`ACK_w-1:0]                               NumAcksToL2,
  output                                            REQ_RD_COMPLETED,
  output [31:0]                                     REQ_RD_DATA,
  output [NODE_ID_w-1:0]                            SenderToL1,
  output [NODE_ID_w-1:0]                            SenderToL2,
  output [NODE_ID_w-1:0]                            SenderToMC,
  output [31:0]                                     TR_DataWrite,
  output                                            TR_Read,
  output [`REG_w-1:0]                               TR_REG_READ,
  output [`REG_w-1:0]                               TR_REG_WRITE,
  output [`TLID_w-1:0]                              TR_TILE_SENDER,
  output                                            TR_Write,
  output                                            WriteInL1Read,
  output                                            WriteInL1Write,
  output                                            WriteInL2Read,
  output                                            WriteInL2Write,
  output                                            WriteInMCRead,
  output                                            WriteInMCWrite,
  output                                            WordAccessToMC,
  output                                            HalfAccessToMC,
  output                                            ByteAccessToMC,
  output [width_xxx_dest-1:0]                       core_dest,                                        // bus to identify the final core within the tile
  output [width_xxx_dest-1:0]                       l1i_dest,                                         // bus to identify the final core within the tile
  output [width_xxx_dest-1:0]                       l1d_dest,                                         // bus to identify the final l1d within the tile
  output [width_xxx_dest-1:0]                       tr_dest,                                          // bus to identify the final tr within the tile
  output [width_xxx_dest-1:0]                       ms_tr_dest,                                       // message system. bus to identify the final tr within the tile
  input  [width_xxx_dest-1:0]                       offset_node_core,                                 // bus to identify the initial core within the tile
  input  [width_xxx_dest-1:0]                       offset_node_l1d,                                   // bus to identify the initial l1d within the tile
  input  [width_xxx_dest-1:0]                       offset_node_tr,                                    // bus to identify the initial tr within the tile
  // interface from NCA (from the CORE)
  input [31:0]                                      NCA_ADDRESS_i,
  input [3:0]                                       NCA_BE_i,
  input [31:0]                                      NCA_DATA_i,
  input                                             NCA_LL_i,
  input                                             NCA_READ_i,
  input                                             NCA_SC_i,
  input                                             NCA_WRITE_i,
  // interface from NCA_fnet to NCA (core)
  output                                            NCA_COMPLETED_o,
  output [31:0]                                     NCA_DATA_o,
  output                                            NCA_SC_SUCCEEDED_o,
  output                                            NCA_AVAIL_FROM_NI_o
);                  
              
  `include "common_functions.vh"
   
  //Internal connection among modules
  wire availCORE_fnet2;
  wire availCORE_fTR;
  wire availL1D_fL1;
  wire availL1D_fL2;
  wire availL1D_fnet0;
  wire availL1D_fnet1;
  wire availL1I_fMC;
  wire availL1I_fnet2;
  wire availL2_fL1D;
   wire availL2_fMC;
   wire availL2_fnet0;
   wire availL2_fnet1;
   wire availL2_fnet2;
   wire availMC_fL1I;
   wire availMC_fL2;
   wire availMC_fnet2;
   wire availTR_fCORE;
   wire availTR_fnet2;
   wire avail_fCORE_tonet2;
   wire avail_fL1D_tonet0;
   wire avail_fL1D_tonet1;
   wire avail_fL1I_tonet2;
   wire avail_fL2_tonet0;
   wire avail_fL2_tonet1;
   wire avail_fL2_tonet2;
   wire avail_fMC_tonet2;
   wire avail_fTR_tonet2;
   wire BroadcastL2;
   wire [63:0] msgCORE;
   wire [`L1_MSG_w-1:0] msgL1D;
   wire [63:0] msg_fromL1I;
   wire [`L2_MSG_w-1:0] msg_fromL2;        // From L2 to L2_tonet, L1D_fnet, MC_fnet and VNX_inject
   wire [`MC_MSG_w-1:0] msg_fromMC;        // From MC to MC_tonet, L2_fnet, L1I_fnet, VN2_inject
   wire SendHome_FromL1D;
   wire SendHome_FromL2;
   wire [63:0] msgTR;
   wire [`VN0_MSG_w-1:0] msg_fnet0;
   wire [`VN1_MSG_w-1:0] msg_fnet1;
   wire [`VN2_MSG_w-1:0] msg_fnet2;
   wire reqCORE_tonet2;
   wire reqCORE_toTR;
   wire reqL1D_toL1;
   wire reqL1D_toL2;
   wire reqL1D_tonet0;
   wire reqL1D_tonet1;
   wire reqL1I_toMC;
   wire reqL1I_tonet2;
   wire reqL2_toL1D;
   wire reqL2_toMC;
   wire reqL2_tonet0;
   wire reqL2_tonet1;
   wire reqL2_tonet2;
   wire reqMC_toL1I;
   wire reqMC_toL2;
   wire reqMC_tonet2;
   wire reqTR_toCORE;
   wire reqTR_tonet2;
   wire req_toCORE_fnet2;
   wire req_toL1D_fnet0;
   wire req_toL1D_fnet1;
   wire req_toL1I_fnet2;
   wire req_toL2_fnet0;
   wire req_toL2_fnet1;
   wire req_toL2_fnet2;
   wire req_toMC_fnet2;
   wire req_toTR_fnet2;
   wire XLXN_984;
   wire XLXN_995;
   wire req_toNCA_fnet2;
   wire avail_fNCA_tonet2;
   
   wire broadcast_toL1D_fnet0;
   wire broadcast_toL1D_fnet1;
   wire broadcast_toL2_fnet0;
   wire broadcast_toL2_fnet1;
   

   wire [63:0] flit_fromMS;                                             //
   wire [1:0] flit_type_fromMS;                                         //
   wire reqMS_tonet;                                                    //
   wire availMS_fromnet;                                                //
   wire [37:0] w_data_vn0_to_ms;
   wire w_req_ms_to_ms;
   wire w_req_vn0_to_ms;
   wire [37:0] w_data_ms_to_ms;
   wire w_avail_ms_to_vn0;
   wire w_avail_ms_to_ms;
   wire [1:0] vn_to_inject_fromMS;

   wire [38:0] w_MessageSystem_in;
   wire [38:0] w_MessageSystem_out;

   wire [width_xxx_dest-1:0] ms_tr_dest_w;

   // wires between MC_tonet and NCA_fnet
   wire reqMC_toNCA;
   wire avail_nca_to_mc;



   reg [38:0] Generated_MessageSystem_in;
   reg ms_activated;

   reg        req_Generated_MessageSystem;
   reg [15:0] msg_size_Generated_MessageSystem;
   reg [3:0] synth_function_Generated_MessageSystem;
   reg [1:0] vn_Generated_MessageSystem;
   reg [8:0] dst_Generated_MessageSystem;
   reg [3:0] iRate_Generated_MessageSystem;

   if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin

    localparam select_dst = 0;   //Send to specific destination, else will send to a random destination
    localparam injectModeAll = 1;
    localparam injectModePairs = 0;
    localparam injectModeCloseToApp = 0;
    localparam injectModeCloseToMem = 0;

    localparam injectMode = (injectModeAll) ? 1:
                            (injectModePairs) ? 2:
                            (injectModeCloseToApp) ? 3:4;

    always @ (posedge clk)
      if (rst_p) begin
        ms_activated <= 1'b0;
        Generated_MessageSystem_in <= 39'b0;
        req_Generated_MessageSystem <= 1'b0;

      end else begin

        if(!ms_activated) begin
          case (injectMode)
            1: begin  
                if(ID!=15) begin //Todos menos app
                  req_Generated_MessageSystem <= 1'b1;
                  msg_size_Generated_MessageSystem <= 16'd6; //MESSAGE_SIZE
                  synth_function_Generated_MessageSystem <= (select_dst) ?   `SYNTH2_FUNCTION :
                                                                             `SYNTH_FUNCTION ;
                  vn_Generated_MessageSystem <= 2'd0;     //INTERFERENCES VN 
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd1;  //100%
                end// if 
                else begin
                  req_Generated_MessageSystem <= 1'b1;
                  msg_size_Generated_MessageSystem <= 16'd6;
                  synth_function_Generated_MessageSystem <= `SYNTH_FUNCTION;
                  vn_Generated_MessageSystem <= 2'd0;
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd1;  //50%
                end//generate signals
               end//1
            2: begin  
                if((ID%2)==0) begin //Todos los pares
                  req_Generated_MessageSystem <= 1'b1;
                  msg_size_Generated_MessageSystem <= 16'd6;
                  synth_function_Generated_MessageSystem <= (select_dst) ?   `SYNTH2_FUNCTION :
                                                                             `SYNTH_FUNCTION ;
                  vn_Generated_MessageSystem <= 2'd0;
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd1;  //100%
                end// if 
                else begin
                  req_Generated_MessageSystem <= 1'b0;
                  msg_size_Generated_MessageSystem <= 16'd6;
                  synth_function_Generated_MessageSystem <= `SYNTH_FUNCTION;
                  vn_Generated_MessageSystem <= 2'd0;
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd2;  //50%
                end//generate signals
               end//2
            3: begin  
                if((ID==4)|(ID==5)|(ID==8)|(ID==9)|(ID==12)|(ID==13)|(ID==14)) begin
                  req_Generated_MessageSystem <= 1'b1;
                  msg_size_Generated_MessageSystem <= 16'd6;
                  synth_function_Generated_MessageSystem <= (select_dst) ?   `SYNTH2_FUNCTION :
                                                                             `SYNTH_FUNCTION ;
                  vn_Generated_MessageSystem <= 2'd0;
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd1;  //100%
                end// if 
                else begin
                  req_Generated_MessageSystem <= 1'b0;
                  msg_size_Generated_MessageSystem <= 16'd6;
                  synth_function_Generated_MessageSystem <= `SYNTH_FUNCTION;
                  vn_Generated_MessageSystem <= 2'd0;
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd2;  //50%
                end//generate signals
               end//3
            4: begin  
                if((ID==4)|(ID==5)|(ID==8)|(ID==9)|(ID==12)|(ID==13)|(ID==14)) begin
                  req_Generated_MessageSystem <= 1'b1;
                  msg_size_Generated_MessageSystem <= 16'd6;
                  synth_function_Generated_MessageSystem <= (select_dst) ?   `SYNTH2_FUNCTION :
                                                                             `SYNTH_FUNCTION ;
                  vn_Generated_MessageSystem <= 2'd0;
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd1;  //100%
                end// if 
                else begin
                  req_Generated_MessageSystem <= 1'b0;
                  msg_size_Generated_MessageSystem <= 16'd6;
                  synth_function_Generated_MessageSystem <= `SYNTH_FUNCTION;
                  vn_Generated_MessageSystem <= 2'd0;
                  dst_Generated_MessageSystem <= 9'd0;
                  iRate_Generated_MessageSystem <= 4'd2;  //50%
                end//generate signals
               end//4
          endcase//injectMode

          Generated_MessageSystem_in <= {req_Generated_MessageSystem, msg_size_Generated_MessageSystem, synth_function_Generated_MessageSystem, 3'd0, vn_Generated_MessageSystem, dst_Generated_MessageSystem, iRate_Generated_MessageSystem};
          ms_activated <= req_Generated_MessageSystem;
        end// ms_activated
        else begin
          Generated_MessageSystem_in[38] <= 1'b0;
        end// ms_disabled
      end// else
   end//enable MS
   
   if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin
     assign ms_tr_dest = ms_tr_dest_w;
     // assign w_MessageSystem_in = MessageSystem_in;
     assign w_MessageSystem_in = Generated_MessageSystem_in;
     assign MessageSystem_out  = w_MessageSystem_out;
   end else begin
     assign w_MessageSystem_in  = 39'b0;
     assign MessageSystem_out = 39'b0;
     assign avail_tr_to_ms = 1'b0;                     //
   end
   

  if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin
    // We define the Message_tonet module if defined
    MS_tonet #(
      .ID(ID),
      .CORES_PER_TILE(CORES_PER_TILE),
      .NUM_NODES(NUM_NODES)
    ) ms_tonet0 (                                      
      .clk(clk),                                      //
      .rst_p(rst_p),                                  //
      .timestamp_in(timestamp_in),
      .MessageSystem_in(w_MessageSystem_in),            //
      .FlitOut(flit_fromMS),                          //
      .FlitType(flit_type_fromMS),                    //
      .req_tonet(reqMS_tonet),                        //
      .req_tolocal(w_req_ms_to_ms),                   //
      .data_tolocal(w_data_ms_to_ms),                 //
      .vn_to_inject(vn_to_inject_fromMS),             //
      .avail_net(availMS_fromnet),                    //
      .avail_local(w_avail_ms_to_ms)                  //
    );    

    // We define the message_fnet module
    MS_fnet #(
      .ID(ID),
      .CORES_PER_TILE(CORES_PER_TILE)
    ) ms_fnet0 (
      .clk(clk),					                 //
      .rst_p(rst_p),					             //
      .timestamp_in(timestamp_in),
      .flit(flit_fromMS),
      .flit_type(flit_type_fromMS),
      //.avail_from_tilereg(avail_tr_to_ms),		     //
      //.data_from_net(w_data_vn0_to_ms),		         //
      //.data_from_local(w_data_ms_to_ms),		     //
      //.req_from_net(w_req_vn0_to_ms),		         //
      .valid(w_req_ms_to_ms)         //
      //.MessageSystem_out(w_MessageSystem_out),		 //
      //.avail_net(w_avail_ms_to_vn0),		         //
      //.tr_dest(ms_tr_dest_w),				         //
    );

    assign w_avail_ms_to_ms = 1'b1;
    assign w_avail_ms_to_vn0 = 1'b1;
    assign w_MessageSystem_out = 39'b0;
    assign ms_tr_dest_w = `V_ZERO(width_xxx_dest);

  end                                                          

  // In the LX_tonet the valid bit is setted and the NID(valid bit + L1/L2 bit + TLID) is passed to the NID_inject
  // In the NID eject the valid bit is removed and the NID(L1/L2bit+TLID) is passed to the LXfnet
  wire [FLAGS_w-1:0]   Flags_L1_to_NIDs_inject;
  wire [FLAGS_w-1:0]   Flags_L2_to_NIDs_inject;
  wire [NID_w-1:0]     Id_L1_to_NIDs_inject;
  wire [NID_w-1:0]     Id_L2_to_NIDs_inject;
  wire                 req_L1_to_NIDs_inject;
  wire                 req_L2_to_NIDs_inject;
  wire                           availL1_from_NIDs_inject;
  wire                           availL2_from_NIDs_inject;
  wire [CORES_PER_TILE*32-1 : 0] pending_address_NIDs_L1;
  wire [CORES_PER_TILE*32-1 : 0] pending_address_NIDs_L2;
  wire [LOG_CORES_PER_TILE-1:0]  l1d_offset_L1D_to_NIDs_inject;                    // l1d which sends the ID
  wire [FLAGS_w-1:0]             NIDs_output_flags_local;                          // Flags to inject into NID
  wire [NID_w-1:0]               NIDs_output_id_local;                             // ID to inject into NID   
  wire                           avail_fNIDseject_to_NIDsinject;                   // flow control between nid inject and nid eject for local NIDs

  wire                 avail_fL1_to_NIDs_eject;                               
  wire                 avail_fL2_to_NIDs_eject;
  wire [FLAGS_w-1:0]   Flags_NIDs_eject_to_L1;                               
  wire [FLAGS_w-1:0]   Flags_NIDs_eject_to_L2;                               
  wire [NID_ID_w-1:0]  Id_NIDs_eject_to_L1;                               
  wire [NID_ID_w-1:0]  Id_NIDs_eject_to_L2;
  wire                 req_NIDs_eject_to_L1;
  wire                 req_NIDs_eject_to_L2;
  
  if (ENABLE_RHM_SUPPORT == "yes") begin
    NIDs_inject #(
      .ID                               ( ID                              ),
      .CORES_PER_TILE                   ( CORES_PER_TILE                  ),
      .ENABLE_GN_DEBUG_LEVEL_0_SUPPORT  ( ENABLE_GN_DEBUG_LEVEL_0_SUPPORT )
    ) nids_inject0 (
      .clk(clk),
      .rst(rst_p),
      .FLAGS_fL1(Flags_L1_to_NIDs_inject),
      .FLAGS_fL2(Flags_L2_to_NIDs_inject),
      .ID_fL1(Id_L1_to_NIDs_inject),
      .ID_fL2(Id_L2_to_NIDs_inject),
      .l1d_offset(l1d_offset_L1D_to_NIDs_inject),
      .FLAGSout_local(NIDs_output_flags_local),
      .IDout_local(NIDs_output_id_local),    
      .avail_fNIDseject(avail_fNIDseject_to_NIDsinject),
      .req_fL1(req_L1_to_NIDs_inject),
      .req_fL2(req_L2_to_NIDs_inject),
      .avail_toL1(availL1_from_NIDs_inject),
      .avail_toL2(availL2_from_NIDs_inject),
      .FLAGSout(NIDs_output_flags),
      .IDout(NIDs_output_id)
    );
                              
    NIDs_eject #(
      .ID(ID),
      .CORES_PER_TILE(CORES_PER_TILE)
    ) nids_eject0 (
      .clk(clk),
      .rst(rst_p),
      .avail_fL1(avail_fL1_to_NIDs_eject),
      .avail_fL2(avail_fL2_to_NIDs_eject),
      .FLAGSin(NIDs_input_flags),
      .IDin(NIDs_input_id),
      .IDin_local(NIDs_output_id_local),
      .FLAGSin_local(NIDs_output_flags_local),
      .avail_localPort(avail_fNIDseject_to_NIDsinject),
      .FLAGS_toL1(Flags_NIDs_eject_to_L1),
      .FLAGS_toL2(Flags_NIDs_eject_to_L2),
      .ID_toL1(Id_NIDs_eject_to_L1),
      .ID_toL2(Id_NIDs_eject_to_L2),
      .req_toL1(req_NIDs_eject_to_L1),
      .req_toL2(req_NIDs_eject_to_L2)
    );
  end                     

   
   L1I_tonet #(
     .ID(ID),
     .CORES_PER_TILE(CORES_PER_TILE)
   ) XLXI_67 (
	 .Address(IADDRESS[31:0]), 
     .avail_fMC(availL1I_fMC), 
     .avail_fnet(availL1I_fnet2), 
     .clk(clk), 
     .req(FETCH), 
     .rst(rst_p), 
     .avail(NI_buff_L1I_avail), 
     .msg(msg_fromL1I), 
     .req_toMC(reqL1I_toMC), 
     .req_tonet(reqL1I_tonet2),
     .offset_node(offset_node_core)
   );
                      
   TR2_tonet #(
     .ID(ID),
     .CORES_PER_TILE(CORES_PER_TILE)
   ) XLXI_69 (
     .avail_fCORE(availTR_fCORE), 
     .avail_fnet(availTR_fnet2), 
     .clk(clk), 
     .data(TR_DataFromTR[31:0]), 
     .dst_tile(TR_DST_TILE), 
     .req(TR_ReadCompleted), 
     .rst(rst_p), 
     .avail(NI_buff_TR_avail), 
     .msg(msgTR[63:0]), 
     .req_toCORE(reqTR_toCORE), 
     .req_tonet(reqTR_tonet2),
     .offset_node(offset_node_tr)
   );

  wire [3:0] num_flitsL1D;
  wire [3:0] num_flitsL2;
                      
                      
  L1D_tonet #(
    .ID(ID),
    .ENABLE_RHM_SUPPORT(ENABLE_RHM_SUPPORT),
    .CORES_PER_TILE(CORES_PER_TILE),
    .NUM_NODES(NUM_NODES),
    .NODE_ID_w(NODE_ID_w)
  ) XLXI_70 (
    .Address(AddressFromL1[31:0]), 
    .Home(HomeFromL1),
    .ValidHome(ValidHomeFromL1),
    .avail_fL1(availL1D_fL1),
    .avail_fL2(availL1D_fL2), 
    .avail_fnet0(availL1D_fnet0), 
    .avail_fnet1(availL1D_fnet1), 
    .clk(clk),
    .num_flits(num_flitsL1D),
    .NID_flags(Flags_L1_to_NIDs_inject),  
    .FlagsToGN(6'b100000),            // For the moment only ACKs are sent by L1 caches
    .NID_id(Id_L1_to_NIDs_inject),
    .avail_fNIDs(availL1_from_NIDs_inject),
    .req_toNIDs(req_L1_to_NIDs_inject),
    .pending_address_NIDs(pending_address_NIDs_L1),
    .NID_l1d_offset(l1d_offset_L1D_to_NIDs_inject),
    .Command1(Command1FromL1[5:0]), 
    .Command2(Command2FromL1[5:0]), 
    .DataBlock(BlockFromL1[511:0]), 
    .DstType1(DstType1FromL1[2:0]), 
    .DstType2(DstType2FromL1[2:0]), 
    .DstVector1(DstVector1FromL1), 
    .DstVector2(DstVector2FromL1), 
    .NumAcks(NumACKsFromL1), 
    .req(WriteNIBufferFromL1), 
    .rst(rst_p), 
    .Sender(SenderFromL1), 
    .avail(NIBufferToL1Free),
    .msg(msgL1D), 
    .req_toL1(reqL1D_toL1),
    .req_toL2(reqL1D_toL2), 
    .req_tonet0(reqL1D_tonet0), 
    .req_tonet1(reqL1D_tonet1),
    .SendHome(SendHome_FromL1D),
    .offset_node(offset_node_l1d)
  );
  
  // NCA_tonet
  wire         req_toMC_fnca;             // request from NCA to MC
  wire         reqNCA_tonet2;             // request from NCA to network 2
  wire         avail_fMC_tonca;           // avail signal from MC to NCA
  wire [127:0] msgNCA;                    // Output message from NCA (to MC and NETWORK2
  
  NCA_tonet #(
    .ID(ID),
    .CORES_PER_TILE(CORES_PER_TILE),
    .NUM_NODES(NUM_NODES),
    .NODE_ID_w(NODE_ID_w)
  ) NCA_tonet0 (
    .clk                   ( clk                         ),
    .rst                   ( rst_p                       ),
    .core_address          ( NCA_ADDRESS_i               ),
    .core_be               ( NCA_BE_i                    ),
    .core_data             ( NCA_DATA_i                  ),
    .core_ll               ( NCA_LL_i                    ),
    .core_read             ( NCA_READ_i                  ),
    .core_write            ( NCA_WRITE_i                 ),
    .core_sc               ( NCA_SC_i                    ),
    .avail_fnet2           ( availNCA_fnet2              ),
    .msg                   ( msgNCA                      ),
    .req_tonet2            ( reqNCA_tonet2               ),
    .avail_fMC             ( avail_fMC_tonca             ),
    .req_toMC              ( req_toMC_fnca               ),
    .avail                 ( NCA_AVAIL_FROM_NI_o         )
  );

  // L2_tonet
  L2_tonet #(
    .ID(ID),
    .CORES_PER_TILE(CORES_PER_TILE),
    .NUM_NODES(NUM_NODES),
    .ENABLE_RHM_SUPPORT(ENABLE_RHM_SUPPORT),
    .NETWORK_DEBUG_LEVEL_0(ENABLE_NETWORK_DEBUG_LEVEL_0_SUPPORT)
  ) XLXI_71 (
    .Address(AddressFromL2[31:0]),
    .Home(HomeFromL2),
    .ValidHome(ValidHomeFromL2),
    .avail_fL1D(availL2_fL1D), 
    .avail_fMC(availL2_fMC), 
    .avail_fnet0(availL2_fnet0), 
    .avail_fnet1(availL2_fnet1), 
    .avail_fnet2(availL2_fnet2), 
    .BroadcastEnabled(1'b1/*BroadcastEnabled*/), 
    .Broadcast1(Broadcast1FromL2), 
                                                .Broadcast2(Broadcast2FromL2), 
                                                .clk(clk), 
                                                 .num_flits(num_flitsL2),
                                                .FlagsToGN(FlagsToGN[5:0]),
                                                .avail_fNIDs(availL2_from_NIDs_inject),
                                                .NID_flags(Flags_L2_to_NIDs_inject),
                                                .NID_id(Id_L2_to_NIDs_inject),
                                                .req_toNIDs(req_L2_to_NIDs_inject),
                                                .pending_address_NIDs(pending_address_NIDs_L2),
                                                .Command1(Command1FromL2[5:0]), 
                                                .Command2(Command2FromL2[5:0]), 
                                                .DataBlock(BlockFromL2[511:0]), 
                                                .DstType1(DstType1FromL2[2:0]), 
                                                .DstType2(DstType2FromL2[2:0]), 
                                                .DstVector1(DstVector1FromL2), 
                                                .DstVector2(DstVector2FromL2), 
                                                .NumAcks(NumACKsFromL2), 
                                                .req(WriteNIBufferFromL2), 
                                                .rst(rst_p), 
                                                .Sender(SenderFromL2), 
                                                .avail(NIBufferToL2Free), 
                                                .Broadcast(BroadcastL2), 
                                                .msg(msg_fromL2), 
                                                .SendHome(SendHome_FromL2),
                                                .req_toL1D(reqL2_toL1D), 
                                                .req_toMC(reqL2_toMC), 
                                                .req_tonet0(reqL2_tonet0), 
                                                .req_tonet1(reqL2_tonet1), 
                                                .req_tonet2(reqL2_tonet2)
                                                ); 

  MC_tonet #(
    .ID(ID),
    .CORES_PER_TILE(CORES_PER_TILE),
    .LOG_CORES_PER_TILE(LOG_CORES_PER_TILE)
  ) XLXI_77 (
                                                .Address(AddressFromMC[31:0]), 
                                                .avail_fL1I     ( availMC_fL1I        ), 
                                                .avail_fL2      ( availMC_fL2         ), 
                                                .avail_fnet     ( availMC_fnet2       ),
                                                .avail_fNCA     ( avail_nca_to_mc     ), 
                                                .clk            ( clk                 ), 
                                                .DataBlock      ( BlockFromMC[511:0]  ), 
                                                .Dst            ( Dst                 ), 
                                                .req            ( WriteNIBufferFromMC ), 
                                                .rst            ( rst_p               ), 
                                                .SenderFromMC   ( SenderFromMC        ), 
                                                .avail          ( NIBufferToMCFree    ), 
                                                .msg            ( msg_fromMC          ), 
                                                .req_toL1I      ( reqMC_toL1I         ), 
                                                .req_toL2       ( reqMC_toL2          ), 
                                                .req_tonet      ( reqMC_tonet2        ),
                                                .req_toNCA      ( reqMC_toNCA         )
                                                );

  CORE_tonet #(
    .ID              ( ID             ),
    .CORES_PER_TILE  ( CORES_PER_TILE )
  ) XLXI_78 (
    .avail_fnet(availCORE_fnet2), 
    .avail_fTR(availCORE_fTR), 
    .clk(clk), 
    .rd_reg(REQ_RD_REG), 
    .rd_req(REQ_RD), 
    .rd_tile(REQ_RD_TILE), 
    .rst(rst_p), 
    .wr_data(REQ_WR_DATA[31:0]), 
    .wr_reg(REQ_WR_REG), 
    .wr_req(REQ_WR), 
    .wr_tile(REQ_WR_TILE), 
    .msg(msgCORE), 
    .rd_avail(NI_buff_CORE_rd_avail), 
    .req_tonet(reqCORE_tonet2), 
    .req_toTR(reqCORE_toTR), 
    .wr_avail(NI_buff_CORE_wr_avail),
    .offset_node(offset_node_core)
  );

  // L1D-VN0 serializer
  wire                      availL1D_SERIALIZER_VN0;
  wire                      reqL1D_SERIALIZER_VN0;
  wire [FLIT_SIZE-1:0]      msgL1D_SERIALIZER_VN0;
  wire [FLIT_TYPE_SIZE-1:0] msg_typeL1D_SERIALIZER_VN0;
  wire                      SendHome_FromL1D_SERIALIZER_VN0;
 
  SERIALIZER_NI #(            
    .INPUT_WIDTH         ( `L1_MSG_w                  ), 
    .FLIT_SIZE           ( FLIT_SIZE                  ),
    .FLIT_TYPE_SIZE      ( FLIT_TYPE_SIZE             )
  ) SERIALIZER_L1D_VN0 (
    .clk                 ( clk                        ),   
    .rst_p               ( rst_p                      ), 
    .req_in              ( reqL1D_tonet0              ),
    .avail_in            ( availL1D_SERIALIZER_VN0    ),
    .data_in             ( msgL1D                     ),
    .num_flits           ( num_flitsL1D               ),
    .BroadcastL2_VN0_in  ( 1'b0                       ),
    .BroadcastL2_VN0_out (                            ),
    .req_out             ( reqL1D_SERIALIZER_VN0      ), 
    .avail_out           ( availL1D_fnet0             ), 
    .data_out            ( msgL1D_SERIALIZER_VN0      ),
    .data_type_out       ( msg_typeL1D_SERIALIZER_VN0 )
  );
  
  // L1D-VN1 serializer
  wire                      availL1D_SERIALIZER_VN1;
  wire                      reqL1D_SERIALIZER_VN1;
  wire [FLIT_SIZE-1:0]      msgL1D_SERIALIZER_VN1;
  wire [FLIT_TYPE_SIZE-1:0] msg_typeL1D_SERIALIZER_VN1;
  
  SERIALIZER_NI #(            
    .INPUT_WIDTH         ( `L1_MSG_w                  ), 
    .FLIT_SIZE           ( FLIT_SIZE                  ),
    .FLIT_TYPE_SIZE      ( FLIT_TYPE_SIZE             )
  ) SERIALIZER_L1D_VN1 (
    .clk                 ( clk                        ),   
    .rst_p               ( rst_p                      ), 
    .req_in              ( reqL1D_tonet1              ),
    .avail_in            ( availL1D_SERIALIZER_VN1    ),
    .data_in             ( msgL1D                     ),
    .num_flits           ( num_flitsL1D               ),
    .BroadcastL2_VN0_in  ( 1'b0                       ),
    .BroadcastL2_VN0_out (                            ),
    .req_out             ( reqL1D_SERIALIZER_VN1      ), 
    .avail_out           ( availL1D_fnet1             ), 
    .data_out            ( msgL1D_SERIALIZER_VN1      ),
    .data_type_out       ( msg_typeL1D_SERIALIZER_VN1 )
  );

  // L2-VN0 serializer
  wire                      availL2_SERIALIZER_VN0;
  wire                      reqL2_SERIALIZER_VN0;
  wire [FLIT_SIZE-1:0]      msgL2_SERIALIZER_VN0;
  wire [FLIT_TYPE_SIZE-1:0] msg_typeL2_SERIALIZER_VN0;
  wire                      BroadcastL2_SERIALIZER_VN0;
  
  SERIALIZER_NI #(            
     .INPUT_WIDTH        ( `L2_MSG_w                  ), 
     .FLIT_SIZE          ( FLIT_SIZE                  ),
     .FLIT_TYPE_SIZE     ( FLIT_TYPE_SIZE             )
  ) SERIALIZER_L2_VN0 (
    .clk                 ( clk                        ),   
    .rst_p               ( rst_p                      ), 
    .req_in              ( reqL2_tonet0               ),
    .avail_in            ( availL2_SERIALIZER_VN0     ),
    .data_in             ( msg_fromL2                 ),
    .BroadcastL2_VN0_in  ( BroadcastL2                ),
    .BroadcastL2_VN0_out ( BroadcastL2_SERIALIZER_VN0 ),
    .num_flits           ( num_flitsL2                ),
    .req_out             ( reqL2_SERIALIZER_VN0       ), 
    .avail_out           ( availL2_fnet0              ), 
    .data_out            ( msgL2_SERIALIZER_VN0       ),
    .data_type_out       ( msg_typeL2_SERIALIZER_VN0  )
  );

  // L2-VN1 serializer
  wire availL2_SERIALIZER_VN1;
  wire reqL2_SERIALIZER_VN1;
  wire [FLIT_SIZE-1:0] msgL2_SERIALIZER_VN1;
  wire [FLIT_TYPE_SIZE-1:0] msg_typeL2_SERIALIZER_VN1;
  
  SERIALIZER_NI #(            
    .INPUT_WIDTH         ( `L2_MSG_w                  ),
    .FLIT_SIZE           ( FLIT_SIZE                  ),
    .FLIT_TYPE_SIZE      ( FLIT_TYPE_SIZE             )
  ) SERIALIZER_L2_VN1(
    .clk                 ( clk                        ),   
    .rst_p               ( rst_p                      ), 
    .req_in              ( reqL2_tonet1               ),
    .avail_in            ( availL2_SERIALIZER_VN1     ),
    .data_in             ( msg_fromL2                 ),
    .BroadcastL2_VN0_in  ( 1'b0                       ),
    .BroadcastL2_VN0_out (                            ),
    .num_flits           ( num_flitsL2                ),
    .req_out             ( reqL2_SERIALIZER_VN1       ), 
    .avail_out           ( availL2_fnet1              ), 
    .data_out            ( msgL2_SERIALIZER_VN1       ),
    .data_type_out       ( msg_typeL2_SERIALIZER_VN1  )
  );

  // L2-VN2 serializer
  wire availL2_SERIALIZER_VN2;
  wire reqL2_SERIALIZER_VN2;
  wire [FLIT_SIZE-1:0] msgL2_SERIALIZER_VN2;
  wire [FLIT_TYPE_SIZE-1:0] msg_typeL2_SERIALIZER_VN2;
  
  SERIALIZER_NI #(            
    .INPUT_WIDTH          ( `L2_MSG_w                 ), 
    .FLIT_SIZE            ( FLIT_SIZE                 ),
    .FLIT_TYPE_SIZE       ( FLIT_TYPE_SIZE            )
  ) SERIALIZER_L2_VN2 (
    .clk                  ( clk                       ),   
    .rst_p                ( rst_p                     ), 
    .req_in               ( reqL2_tonet2              ),
    .avail_in             ( availL2_SERIALIZER_VN2    ),
    .data_in              ( msg_fromL2                ),
    .BroadcastL2_VN0_in   ( 1'b0                      ),
    .BroadcastL2_VN0_out  (                           ),
    .num_flits            ( num_flitsL2               ),                      // In this case the message num flits always will be always 9                          
    .req_out              ( reqL2_SERIALIZER_VN2      ), 
    .avail_out            ( availL2_fnet2             ), 
    .data_out             ( msgL2_SERIALIZER_VN2      ),
    .data_type_out        ( msg_typeL2_SERIALIZER_VN2 )
  );

  // MC-VN2 serializer
  wire                      avail_MC_SERIALIZER_VN2;
  wire                      req_MC_SERIALIZER_VN2;
  wire [FLIT_SIZE-1:0]      msg_MC_SERIALIZER_VN2;
  wire [FLIT_TYPE_SIZE-1:0] msg_type_MC_SERIALIZER_VN2;
  
  SERIALIZER_NI #(            
    .INPUT_WIDTH          ( `MC_MSG_w                  ),
    .FLIT_SIZE            ( FLIT_SIZE                  ),
    .FLIT_TYPE_SIZE       ( FLIT_TYPE_SIZE             )
  ) SERIALIZER_MC_VN2 (
    .clk                  ( clk                        ),   
    .rst_p                ( rst_p                      ), 
    .req_in               ( reqMC_tonet2               ),
    .avail_in             ( avail_MC_SERIALIZER_VN2    ),
    .data_in              ( msg_fromMC                 ),
    .BroadcastL2_VN0_in   ( 1'b0                       ),
    .BroadcastL2_VN0_out  (                            ),
    .num_flits            ( 4'd9                       ),                             // In this case the message num flits always will be always 9                          
    .req_out              ( req_MC_SERIALIZER_VN2      ), 
    .avail_out            ( availMC_fnet2              ), 
    .data_out             ( msg_MC_SERIALIZER_VN2      ),
    .data_type_out        ( msg_type_MC_SERIALIZER_VN2 )
  );
  
  // NCA-VN2 serializer
  wire                      availNCA_SERIALIZER_VN2;
  wire                      reqNCA_SERIALIZER_VN2;
  wire [FLIT_SIZE-1:0]      msgNCA_SERIALIZER_VN2;
  wire [FLIT_TYPE_SIZE-1:0] msg_typeNCA_SERIALIZER_VN2;
  
  SERIALIZER_NI #(            
    .INPUT_WIDTH         ( 128                        ), 
    .FLIT_SIZE           ( FLIT_SIZE                  ),
    .FLIT_TYPE_SIZE      ( FLIT_TYPE_SIZE             )
  ) SERIALIZER_NCA_VN2 (
    .clk                 ( clk                        ),   
    .rst_p               ( rst_p                      ), 
    .req_in              ( reqNCA_tonet2              ),
    .avail_in            ( availNCA_SERIALIZER_VN2    ),
    .data_in             ( msgNCA                     ),
    .num_flits           ( 4'd2                       ),
    .BroadcastL2_VN0_in  ( 1'b0                       ),
    .BroadcastL2_VN0_out (                            ),
    .req_out             ( reqNCA_SERIALIZER_VN2      ), 
    .avail_out           ( availNCA_fnet2             ), 
    .data_out            ( msgNCA_SERIALIZER_VN2      ),
    .data_type_out       ( msg_typeNCA_SERIALIZER_VN2 )
  );


  // ----------------------------------------------------------------------------------------------------------------
  // INJECT --------------------------------------------------------------------------------------------------------- 
  // input ports: L1D-VN0, L1D-VN1, L2-VN0, L2-VN1, L2-VN2, MC-VN2, CORE-VN2, L1I-VN2, TR-VN2, NCA-VN2
  localparam NUM_INJ_PORTS = 10; 
  wire  [(NUM_INJ_PORTS*FLIT_SIZE)-1:0]      inject_flit;
  wire  [(NUM_INJ_PORTS*FLIT_TYPE_SIZE)-1:0] inject_flit_type;
  wire  [(BC_w*NUM_INJ_PORTS)-1:0] inject_broadcast;
  wire  [(NUM_INJ_PORTS*bits_VN_X_VC)-1:0]   inject_vn;
  wire  [NUM_INJ_PORTS-1:0]                  inject_req;
  wire  [NUM_INJ_PORTS-1:0]                  inject_avail;

  assign inject_flit              = {msgNCA_SERIALIZER_VN2, msgL1D_SERIALIZER_VN0, msgL1D_SERIALIZER_VN1,
                                     msgL2_SERIALIZER_VN0,  msgL2_SERIALIZER_VN1,  msgL2_SERIALIZER_VN2,
                                     msg_MC_SERIALIZER_VN2, msgCORE,               msg_fromL1I,           msgTR 
                                    }; 
  assign inject_flit_type         = {msg_typeNCA_SERIALIZER_VN2, msg_typeL1D_SERIALIZER_VN0, msg_typeL1D_SERIALIZER_VN1,
                                     msg_typeL2_SERIALIZER_VN0,  msg_typeL2_SERIALIZER_VN1,  msg_typeL2_SERIALIZER_VN2,
                                     msg_type_MC_SERIALIZER_VN2, `header_tail,               `header_tail,              `header_tail 
                                    };
  assign inject_broadcast         = {{BC_w{1'b0}}, {BC_w{1'b0}},
                                     {BC_w{BroadcastL2_SERIALIZER_VN0}}, {BC_w{1'b0}}, {BC_w{1'b0}},
                                     {BC_w{1'b0}},{BC_w{1'b0}},{BC_w{1'b0}},{BC_w{1'b0}} , {BC_w{1'b0}}
                                    };
  assign inject_vn                = {2'd2, 2'd0, 2'd1,
                                     2'd0, 2'd1, 2'd2,
                                     2'd2, 2'd2, 2'd2, 2'd2};
  assign inject_req               = {reqNCA_SERIALIZER_VN2, reqL1D_SERIALIZER_VN0, reqL1D_SERIALIZER_VN1,
                                     reqL2_SERIALIZER_VN0,  reqL2_SERIALIZER_VN1,  reqL2_SERIALIZER_VN2,
                                     req_MC_SERIALIZER_VN2, reqCORE_tonet2,        reqL1I_tonet2,         reqTR_tonet2 
                                    };                                 
  assign availNCA_SERIALIZER_VN2    = inject_avail[9];                                    
  assign availL1D_SERIALIZER_VN0    = inject_avail[8];
  assign availL1D_SERIALIZER_VN1    = inject_avail[7];
  assign availL2_SERIALIZER_VN0     = inject_avail[6];
  assign availL2_SERIALIZER_VN1     = inject_avail[5];
  assign availL2_SERIALIZER_VN2     = inject_avail[4];
  assign avail_MC_SERIALIZER_VN2    = inject_avail[3];  
  assign availCORE_fnet2            = inject_avail[2];
  assign availL1I_fnet2             = inject_avail[1];
  assign availTR_fnet2              = inject_avail[0];
 
  INJECT #(
    .ID                            ( ID                                   ),
    .FLIT_SIZE                     ( FLIT_SIZE                            ), 
    .FLIT_TYPE_SIZE                ( FLIT_TYPE_SIZE                       ),
    .BROADCAST_SIZE                ( BC_w                                 ), // TOMAS TO CHECK
    .PHIT_SIZE                     ( PHIT_SIZE                            ),
    .QUEUE_SIZE                    ( QUEUE_SIZE                           ),
    .SG_UPPER_THOLD                ( IB_SG_UPPER_THOLD                    ), // TOMAS TO CHECK 
    .SG_LOWER_THOLD                ( IB_SG_LOWER_THOLD                    ), // TOMAS TO CHECK
    .NUM_VC                        ( NUM_VC                               ),
    .NUM_VN                        ( NUM_VN                               ),
    .VN_w                          ( VN_w                                 ),
    .NUM_VN_X_VC                   ( NUM_VN_X_VC                          ), 
    .VN_WEIGHT_VECTOR_w            ( VN_WEIGHT_VECTOR_w                   ),
    .CORES_PER_TILE                ( CORES_PER_TILE                       ),    
    .NUM_INPUT_SOURCES             ( NUM_INJ_PORTS                        ),  //  Modify acordingly to notify the module with the number of Imput Sources
    .ENABLE_MESSAGE_SYSTEM_SUPPORT ( ENABLE_MESSAGE_SYSTEM_SUPPORT        ),
    .ENABLE_VN_WEIGHTS_SUPPORT     ( ENABLE_VN_WEIGHTS_SUPPORT            ),
    .ENABLE_NETWORK_DEBUG_LEVEL_0_SUPPORT  ( "yes" )
  ) PEAK_INJECT_inst0 (
    .clk                           ( clk                                  ),
    .rst_p                         ( rst_p                                ),  
    .go                            ( GoFromDN                             ),
    .WeightsVector_i               ( WeightsVector_i                      ),
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
    
    .BroadcastFlitOut              ( BroadcastBitsToDN[4:0]               ), 
    .FlitOut                       ( FlitToDN[63:0]                       ), 
    .FlitTypeOut                   ( FlitTypeToDN[1:0]                    ),                                             
    .ValidOut                      ( ValidBitToDN                         ),
    .VC_out                        ( VcToDN                               )
  );
                       
  wire  ValidBitFrom_VN0 = (VnFromVDN==2'd0) & ValidBitFromDN;
  wire  ValidBitFrom_VN1 = (VnFromVDN==2'd1) & ValidBitFromDN;
  wire  ValidBitFrom_VN2 = (VnFromVDN==2'd2) & ValidBitFromDN;

  wire GoBitToN0, GoBitToN1, GoBitToN2;
  assign GoToDN = {GoBitToN2,GoBitToN1,GoBitToN0};

  VN0_eject #(
    .ID(ID),
    .ENABLE_MESSAGE_SYSTEM_SUPPORT(ENABLE_MESSAGE_SYSTEM_SUPPORT),
    .ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT(ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT),
    .FLIT_SIZE(FLIT_SIZE),
    .CORES_PER_TILE(CORES_PER_TILE)
  ) XLXI_82 (
    .avail_fL1D(avail_fL1D_tonet0), 
    .avail_fL2(avail_fL2_tonet0), 
    .clk(clk), 
                      .timestamp_in(timestamp_in),
                      .flit(FlitFromDN[63:0]), 
                      .flit_type(FlitTypeFromDN[1:0]), 
                      .broadcast(BroadcastBit_fromVDN),
                      .rst(rst_p), 
                      .valid(ValidBitFrom_VN0), 
                      .go(GoBitToN0), 
                      .msg(msg_fnet0), 
                      .req_toMS(w_req_vn0_to_ms),               // message system
                      .data_toMS(w_data_vn0_to_ms),             //
                      .avail_fMS(w_avail_ms_to_vn0),            //
                      .broadcast_toL1D(broadcast_toL1D_fnet0),
                      .broadcast_toL2(broadcast_toL2_fnet0),     
                      .req_toL1D(req_toL1D_fnet0), 
                      .req_toL2(req_toL2_fnet0)
                       );

  VN1_eject        #(
    .ID(ID),
    .ENABLE_MESSAGE_SYSTEM_SUPPORT(ENABLE_MESSAGE_SYSTEM_SUPPORT),
    .ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT(ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT),
    .CORES_PER_TILE(CORES_PER_TILE)
  ) XLXI_83 (
    .avail_fL1D(avail_fL1D_tonet1), 
    .avail_fL2(avail_fL2_tonet1), 
                      .clk(clk), 
                      .timestamp_in(timestamp_in),
                      .flit(FlitFromDN[63:0]), 
                      .flit_type(FlitTypeFromDN[1:0]),
                      .broadcast(BroadcastBit_fromVDN), 
                      .rst(rst_p), 
                      .valid(ValidBitFrom_VN1), 
                      .go(GoBitToN1), 
                      .msg(msg_fnet1),
                      .broadcast_toL1D(broadcast_toL1D_fnet1),
                      .broadcast_toL2(broadcast_toL2_fnet1),      
                      .req_toL1D(req_toL1D_fnet1), 
                      .req_toL2(req_toL2_fnet1)
  );
   
  VN2_eject #(
    .ID(ID),
    .ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT(ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT),
    .ENABLE_MESSAGE_SYSTEM_SUPPORT(ENABLE_MESSAGE_SYSTEM_SUPPORT),
    .CORES_PER_TILE(CORES_PER_TILE)
  ) XLXI_84 (
    .avail_fCORE(avail_fCORE_tonet2), 
    .avail_fL1I(avail_fL1I_tonet2), 
    .avail_fL2(avail_fL2_tonet2), 
    .avail_fMC(avail_fMC_tonet2), 
    .avail_fTR(avail_fTR_tonet2),
    .avail_fNCA(avail_fNCA_tonet2), 
    .clk(clk), 
    .timestamp_in(timestamp_in),
    .flit(FlitFromDN[63:0]), 
    .flit_type(FlitTypeFromDN[1:0]), 
    .rst(rst_p), 
    .valid(ValidBitFrom_VN2), 
    .go(GoBitToN2), 
    .msg(msg_fnet2), 
    .req_toCORE(req_toCORE_fnet2), 
    .req_toL1I(req_toL1I_fnet2), 
    .req_toL2(req_toL2_fnet2), 
    .req_toMC(req_toMC_fnet2), 
    .req_toTR(req_toTR_fnet2),
    .req_toNCA(req_toNCA_fnet2)
  );



  L1I_fnet #(
    .CORES_PER_TILE(CORES_PER_TILE)
  ) XLXI_94 (
    .avail(XLXN_984), 
    .clk(clk), 
    .msg_fMC(msg_fromMC), 
    .msg_fnet(msg_fnet2), 
    .req_fMC(reqMC_toL1I), 
    .req_fnet(req_toL1I_fnet2), 
    .rst(rst_p), 
    .avail_toMC(availMC_fL1I), 
    .avail_tonet(avail_fL1I_tonet2), 
    .DataBlock(IDATA[511:0]), 
    .BlockAddress(BLOCK_ADDRESS[25:0]),
    .req(FETCH_COMPLETED),
    .l1i_dest(l1i_dest)
  );
                     
  CORE_fnet #(
    .CORES_PER_TILE(CORES_PER_TILE),
    .LOG_CORES_PER_TILE(LOG_CORES_PER_TILE)
  ) XLXI_95 (
    .avail(XLXN_995), 
    .clk(clk), 
    .msg_fnet(msg_fnet2[63:0]), 
    .msg_fTR(msgTR[63:0]), 
    .req_fnet(req_toCORE_fnet2), 
    .req_fTR(reqTR_toCORE), 
    .rst(rst_p), 
    .avail_tonet(avail_fCORE_tonet2), 
    .avail_toTR(availTR_fCORE), 
    .Data(REQ_RD_DATA[31:0]), 
    .req(REQ_RD_COMPLETED),
    .core_dest(core_dest)
  );
                      
  L1D_fnet #(
    .NODE_ID_w(NODE_ID_w),
    .CORES_PER_TILE(CORES_PER_TILE),
    .ENABLE_RHM_SUPPORT(ENABLE_RHM_SUPPORT),
    .ENABLE_GN_DEBUG_LEVEL_0(ENABLE_GN_DEBUG_LEVEL_0_SUPPORT)
  ) XLXI_96 (
    .avail_read(ReadAvailableFromL1), 
    .avail_write(WriteAvailableFromL1), 
                     .clk(clk), 
                     .msg_fL1(msgL1D),
                     .msg_fL2(msg_fromL2), 
                     .msg_fnet0(msg_fnet0), 
                     .msg_fnet1(msg_fnet1),
                     .req_fL1(reqL1D_toL1), 
                     .req_fL2(reqL2_toL1D), 
                     .req_fnet0(req_toL1D_fnet0), 
                     .req_fnet1(req_toL1D_fnet1),
                     .broadcast_fnet0(broadcast_toL1D_fnet0),
                     .broadcast_fnet1(broadcast_toL1D_fnet1),
                     .broadcast_fL2(BroadcastL2),                     // broadcasting inside the tile when multiple cores/tile
                     .rst(rst_p), 
                     .address(AddressToL1[31:0]),
                     .Home(HomeToL1),  
                     .avail_toL1(availL1D_fL1),                    
                     .avail_toL2(availL2_fL1D), 
                     .avail_tonet0(avail_fL1D_tonet0), 
                     .avail_tonet1(avail_fL1D_tonet1), 
                     .data_block(BlockToL1[511:0]), 
                     .message_type(MessageTypeToL1[5:0]), 
                     .num_acks(NumAcksToL1), 
                     .req_read(WriteInL1Read), 
                     .req_write(WriteInL1Write), 
                     .sender(SenderToL1),
                     .FLAGS_fNIDs(Flags_NIDs_eject_to_L1), 
                     .ID_fNIDs(Id_NIDs_eject_to_L1), 
                     .pending_address_NIDs(pending_address_NIDs_L1), 
                     .req_fNIDs(req_NIDs_eject_to_L1),  
                     .avail_toNIDs(avail_fL1_to_NIDs_eject), 
                     .broadcast_toL1D(broadcast_toL1D),
                     .l1d_dest_o(l1d_dest));

  // NCA_fnet
  NCA_fnet #(
    .CORES_PER_TILE(CORES_PER_TILE)
  ) NCA_fnet0 (
    .clk                   ( clk                         ),
    .rst                   ( rst_p                       ),
    // interface with MCtonet
    .req_fMC               ( reqMC_toNCA                 ),
    .msg_fMC               ( msg_fromMC                  ),
    .avail_toMC            ( avail_nca_to_mc             ),
    // Interface with network 2
    .req_fnet2             ( req_toNCA_fnet2             ),
    .msg_fnet              ( msg_fnet2                   ),
    .avail_tonet2          ( avail_fNCA_tonet2           ),
    // interface with NCA
    .NCA_COMPLETED_o       ( NCA_COMPLETED_o             ),
    .NCA_DATA_o            ( NCA_DATA_o                  ),
    .NCA_SC_SUCCEEDED_o    ( NCA_SC_SUCCEEDED_o          )
  );
       
  L2_fnet #(
    .CORES_PER_TILE(CORES_PER_TILE),
    .ENABLE_RHM_SUPPORT(ENABLE_RHM_SUPPORT),
    .ENABLE_GN_DEBUG_LEVEL_0_SUPPORT(ENABLE_GN_DEBUG_LEVEL_0_SUPPORT)
  ) XLXI_97 (
    .avail_read(ReadAvailableFromL2), 
    .avail_write(WriteAvailableFromL2), 
                    .clk(clk), 
                    .msg_fL1D(msgL1D), 
                    .msg_fnet0(msg_fnet0), 
                    .msg_fnet1(msg_fnet1), 
                    .msg_fnet2(msg_fnet2), 
                    .msg_MC(msg_fromMC), 
                    .req_fL1D(reqL1D_toL2), 
                    .req_fMC(reqMC_toL2), 
                    .req_fnet0(req_toL2_fnet0), 
                    .req_fnet1(req_toL2_fnet1), 
                    .req_fnet2(req_toL2_fnet2), 
                    .broadcast_fnet0(broadcast_toL2_fnet0),
                    .broadcast_fnet1(broadcast_toL2_fnet1),
                    .broadcast_toL2(broadcast_toL2),                    
                    .rst(rst_p), 
                    .FlagsFromGN(FlagsFromGN), 
                    .FLAGS_fNIDs(Flags_NIDs_eject_to_L2), 
                    .ID_fNIDs(Id_NIDs_eject_to_L2), 
                    .pending_address_NIDs(pending_address_NIDs_L2), 
                    .req_fNIDs(req_NIDs_eject_to_L2), 
                    .avail_toNIDs(avail_fL2_to_NIDs_eject), 
                    .address(AddressToL2[31:0]), 
                    .avail_toL1D(availL1D_fL2), 
                    .avail_toMC(availMC_fL2), 
                    .avail_tonet0(avail_fL2_tonet0), 
                    .avail_tonet1(avail_fL2_tonet1), 
                    .avail_tonet2(avail_fL2_tonet2), 
                    .data_block(BlockToL2[511:0]), 
                    .message_type(MessageTypeToL2[5:0]), 
                    .num_acks(NumAcksToL2), 
                    .req_read(WriteInL2Read), 
                    .req_write(WriteInL2Write), 
                    .sender(SenderToL2));
                    
  TR_fnet #(
    .CORES_PER_TILE(CORES_PER_TILE)
  ) XLXI_104 (
    .clk(clk), 
    .msg_fCORE(msgCORE), 
    .msg_fnet(msg_fnet2[63:0]), 
                     .read_avail(TR_available), 
                     .req_fCORE(reqCORE_toTR), 
                     .req_fnet(req_toTR_fnet2), 
                     .rst(rst_p), 
                     .write_avail(TR_available), 
                     .avail_toCORE(availCORE_fTR), 
                     .avail_tonet(avail_fTR_tonet2), 
                     .data(TR_DataWrite[31:0]), 
                     .read(TR_Read), 
                     .reg_rd_tile(TR_REG_READ), 
                     .reg_wr_tile(TR_REG_WRITE), 
                     .sender(TR_TILE_SENDER), 
                     .write(TR_Write),
                     .tr_dest_o(tr_dest));
                     
   MC_fnet #(
                     .CORES_PER_TILE           ( CORES_PER_TILE        )
   ) mcfnet_inst   (
                     .clk                      ( clk                   ), 
                     .rst                      ( rst_p                 ), 
                     // Interface with L1I
                     .req_fL1I                 ( reqL1I_toMC           ), 
                     .msg_fL1I                 ( msg_fromL1I[63:0]     ), 
                     .avail_toL1I              ( availL1I_fMC          ), 
                     // Interface with L2
                     .req_fL2                  ( reqL2_toMC            ), 
                     .msg_fL2                  ( msg_fromL2            ), 
                     .avail_toL2               ( availL2_fMC           ), 
                     // Interface with net
                     .req_fnet2                ( req_toMC_fnet2        ), 
                     .msg_fnet                 ( msg_fnet2             ), 
                     .avail_tonet2             ( avail_fMC_tonet2      ), 
                     // Interface with NCA
                     .req_fnca                 ( req_toMC_fnca         ),
                     .msg_fnca                 ( msgNCA                ),
                     .avail_tonca              ( avail_fMC_tonca       ),
                     // Interface with MC
                     .address                  ( AddressToMC[31:0]     ), 
                     .avail_write              ( WriteAvailableFromMC  ), 
                     .avail_read               ( ReadAvailableFromMC   ), 
                     .data_block               ( BlockToMC[511:0]      ), 
                     .req_read                 ( WriteInMCRead         ), 
                     .req_write                ( WriteInMCWrite        ), 
                     .sender                   ( SenderToMC            ),
                     .word_access              ( WordAccessToMC        ),
                     .half_access              ( HalfAccessToMC        ),
                     .byte_access              ( ByteAccessToMC        )
                   );
                     
   VCC  XLXI_111 (.P(XLXN_984));
   VCC  XLXI_112 (.P(XLXN_995));
   
  generate 
  if (ENABLE_DEBUG_SUPPORT_EJECT == "yes") begin
    assign debug_eje_valid_o = debugFlit_enabled & ValidBitFromDN & ((FlitTypeFromDN == `header) | (FlitTypeFromDN == `header_tail));
 
    assign debug_eje_o[`DEBUG_EJECT_FLIT_RANGE] = FlitFromDN; 
    assign debug_eje_o[`DEBUG_EJECT_VNID_RANGE] = VnFromVDN; 
   end
 
   if (ENABLE_DEBUG_SUPPORT_INJECT == "yes") begin 
     localparam VN_LSB = bits_VC;
     localparam VN_MSB = VN_LSB + bits_VN - 1;
         
     assign debug_inj_valid_o = debugFlit_enabled & ValidBitToDN & ((FlitTypeToDN == `header) | (FlitTypeToDN == `header_tail));
 
     assign debug_inj_o[`DEBUG_INJECT_FLIT_RANGE] = FlitToDN;
     assign debug_inj_o[`DEBUG_INJECT_VNID_RANGE] = VcToDN[VN_MSB:VN_LSB];
   end   
   endgenerate
endmodule
