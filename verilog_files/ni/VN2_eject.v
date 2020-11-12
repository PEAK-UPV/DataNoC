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
// Company:   GAP (UPV)  
// Engineer:  J. Flich (jflich@disca.upv.es)
//
// Create Date: 08/31/2013 09:49:31
// Design Name: 
// Module Name: VN2_eject
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
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


module VN2_eject #(
                  parameter  ENABLE_MESSAGE_SYSTEM_SUPPORT = "no",
                  parameter  ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT = "no",
                  parameter  ID = 0,
                  parameter  VNID = 2,
                  parameter  CORES_PER_TILE = 1,
                  parameter  FLIT_SIZE = 64,
                  localparam LOG_CORES_PER_TILE = Log2_w(CORES_PER_TILE),
                  localparam LOG_CORES_PER_TILE_GOOD    = Log2(CORES_PER_TILE),
                  localparam DATA_NET_FLIT_w = FLIT_SIZE
                 )(
                 avail_fCORE, 
                 avail_fL1I, 
                 avail_fL2, 
                 avail_fMC, 
                 avail_fTR, 
                 avail_fNCA,
                 clk, 
                 timestamp_in,
                 flit, 
                 flit_type, 
                 rst, 
                 valid, 
                 go, 
                 msg, 
                 req_toCORE, 
                 req_toL1I, 
                 req_toL2, 
                 req_toMC, 
                 req_toTR,
                 req_toNCA);

   `include "common_functions.vh"


    input avail_fCORE;
    input avail_fL1I;
    input avail_fL2;
    input avail_fMC;
    input avail_fTR;
    input avail_fNCA;
    input clk;
    input [63:0] timestamp_in;
    input [63:0] flit;
    input [1:0] flit_type;
    input rst;
    input valid;
   output go;
   output reg [`VN2_MSG_w-1:0] msg;
   output reg req_toCORE;
   output reg req_toL1I;
   output reg req_toL2;
   output reg req_toMC;
   output reg req_toTR;
   output reg req_toNCA;
  

  //reg req_toMS;
  reg [63:0] slot;
  reg [1:0] flit_type_slot;
  reg free_slot;
  reg completed;
  reg [3:0] flit_number;
  
  reg [1:0] flit_type_ant;
  
  reg request_possible;

    
  assign go = ~completed;

  reg h;//debugging
  reg t;//debugging
  reg p;//debugging

  reg [63:0] Counter_VN;
  reg waiting_tail;
  reg ms_msg_incoming;

  wire is_ms_flit;
  generate
    if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin
      assign is_ms_flit = valid & (((flit_type == `header_tail | flit_type == `header) & flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `MS) | ms_msg_incoming);
    end else
      assign is_ms_flit = 0;
  endgenerate
  
  // generate
  //   if (ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT == "yes") begin
  //     always @ (posedge clk)
  //       if (valid) $display("                       VN2 EJECT: %h SRC: %d DST: %d TYPE %h", flit, flit[`MSG_TLSRC_MSB:`MSG_TLSRC_LSB], ID, flit_type);
  //   end
  // endgenerate

  always @ (posedge clk)
    if (rst) begin
      req_toL2 <= 0;
      req_toL1I <= 0;
      req_toMC <= 0;
      req_toTR <= 0;
      req_toCORE <= 0;
      req_toNCA <= 0;
      completed <= 0;
      slot <= 64'b0;
      flit_type_slot <= 2'b00;
      free_slot <= 1;
      flit_number <= 0;
      msg <= 0;
      request_possible <= 0;
      flit_type_ant <= `tail;
      h<=0;//debugging
      t<=0;//debugging
      p<=0;//debugging
      waiting_tail <= 1'b0;
      Counter_VN <= `VZERO(64);
      ms_msg_incoming <= 1'b0;
    end else begin
      // Let's check if there is an incomming flit 
      if (valid) begin //Counter of flits for this VN and Network Debug
        Counter_VN <= Counter_VN + `VONE(64);
        // $display ("VN%1d_eject ID %1d, SRC %1d, COUNTER: %d", VNID, ID, flit[`MSG_TLSRC_MSB:`MSG_OFSRC_LSB], Counter_VN);
        //if ((Counter_VN%1000) == 0) $display ("VN2_eject: ID%0d, COUNTER: %d", ID, (Counter_VN));
      end
 
      if (is_ms_flit) begin
        if (flit_type == `header) begin
          ms_msg_incoming <= 1'b1;
          if (ms_msg_incoming) begin $display("%t ERROR!\n", $realtime); $finish; end
        end else if (flit_type == `tail) begin
          ms_msg_incoming <= 1'b0;
        end else if (flit_type == `header_tail) begin
          if (ms_msg_incoming) begin $display("%t ERROR!\n", $realtime); $finish; end
        end
      end else if (valid) begin //MS flits will be ignored
        if (flit_type == `payload && flit_type_ant == `tail) $display("******************************************************************************************** Error, flit type at ejection in VN2");
        flit_type_ant <= flit_type;
        if (~completed) begin
          case (flit_type)
          `header_tail: begin
                                  msg[`MSG_DB_MSB:0] <= {512'b0,flit};
                    completed <= 1;
                      if (waiting_tail) begin 
                      $display("%t ERROR!\n", $realtime);
                      $finish;
                    end
                  end
          `header:    begin
                    msg[63:0] <= flit;
                    flit_number <= 1;
                    waiting_tail <= 1'b1;
                    if (waiting_tail) begin $display("%t ERROR!\n", $realtime); $finish; end
                  end
          `payload:   begin
                    case (flit_number)
                    1:  msg[127:64] <= flit;
                    2: msg[191:128] <= flit;
                    3: msg[255:192] <= flit;
                    4: msg[319:256] <= flit;
                    5: msg[383:320] <= flit;
                    6: msg[447:384] <= flit;
                    7: msg[511:448] <= flit;
                    endcase
                    flit_number <= flit_number + 4'b0001;
                  end
          `tail:      begin
                            // this may be a 2-flit message for word- byte- half-size accesses to memory
                            if (flit_number == 1) 
                              msg[127:64] <= flit;
                            else
                      msg[575:512] <= flit;
                    completed <= 1;
                    waiting_tail <= 1'b0;
                  end
           endcase
        end
      end //else valid & not MS
  
    if (completed) begin
      case (msg[`MSG_NTDST_MSB:`MSG_DST_LSB])
        `CORE:    if (avail_fCORE) req_toCORE <= 1;
        `L1I_cache: if (avail_fL1I) req_toL1I <= 1;
        `L2_cache:  if (avail_fL2) req_toL2 <= 1;
        `MC:      if (avail_fMC) req_toMC <= 1;
        `TR:      if (avail_fTR) req_toTR <= 1;
        `NCA:           if (avail_fNCA) req_toNCA <= 1;
        default:    $display("wrong destination through VN2: %h", msg[`MSG_NTDST_MSB:`MSG_DST_LSB]);
      endcase
    
      if (valid & ~is_ms_flit) begin //MS flits will be ignored
        if (request_possible) begin
          msg[63:0] <= flit;
          flit_number <= 1;
          if (flit_type != `header_tail) completed <= 0;
        end else begin
          slot <= flit;
          flit_number <= 1;
          flit_type_slot <= flit_type;
          free_slot <= 0;
        end
      end else begin
        if (request_possible) begin
          if (~free_slot) begin
            msg[63:0] <= slot;
            free_slot <= 1;
            if (flit_type_slot != `header_tail) completed <= 0;
          end else begin
            completed <= 0;
          end
        end
      end
    end//completed
 
    // Let's remove the request signals
    if (req_toL2 && ~avail_fL2) req_toL2 <= 0;
    if (req_toL1I && ~avail_fL1I) req_toL1I <= 0;
    if (req_toCORE && ~avail_fCORE) req_toCORE <= 0;
    if (req_toTR && ~avail_fTR) req_toTR <= 0;
    if (req_toMC && ~avail_fMC) req_toMC <= 0;
    if (req_toNCA && ~avail_fNCA) req_toNCA <= 1'b0;

      request_possible <=  completed & (((msg[`MSG_NTDST_MSB:`MSG_DST_LSB]== `L2_cache) & avail_fL2) |
                 ((msg[`MSG_NTDST_MSB:`MSG_DST_LSB]== `L1I_cache) & avail_fL1I) | ((msg[`MSG_NTDST_MSB:`MSG_DST_LSB]== `CORE) & avail_fCORE) |
                 ((msg[`MSG_NTDST_MSB:`MSG_DST_LSB]== `MC) & avail_fMC) | ((msg[`MSG_NTDST_MSB:`MSG_DST_LSB]== `TR) & avail_fTR)) |
                 ((msg[`MSG_NTDST_MSB:`MSG_DST_LSB]== `NCA) & avail_fNCA);

  end    

generate
  // if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin
    localparam MS_TIMESTAMP_w = 9;
    localparam MS_OUT_TIMESTAMP_LSB = 53;
    localparam MS_OUT_TIMESTAMP_MSB = 61;
    wire  [MS_TIMESTAMP_w-1:0] current_timestamp_i = timestamp_in[MS_TIMESTAMP_w-1:0];  // Current system timestamp
    wire                       incr_flit_o;
    wire                       incr_msg_o;
    wire [MS_TIMESTAMP_w-1:0] flit_latency_o;
    wire [MS_TIMESTAMP_w-1:0] msg_latency_o;

    wire ms_header = incr_flit_o & (flit_type == `header);
    wire ms_header_tail = incr_flit_o & (flit_type == `header_tail);
    wire ms_tail = incr_flit_o & (flit_type == `tail);

    wire                       timestamp_greater_than_current ;
    wire                       header_timestamp_greater_than_current ;

    wire [MS_TIMESTAMP_w-1:0] timestamp_from_flit ;
    reg [MS_TIMESTAMP_w-1:0]  timestamp_last_header;

    //********************************************************************************************************
    // Output assignments
    //********************************************************************************************************

    assign incr_flit_o = valid & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `MS);
    assign incr_msg_o  = (ms_tail | ms_header_tail);

    assign flit_latency_o = (incr_flit_o & ~timestamp_greater_than_current) ? (current_timestamp_i - timestamp_from_flit  ):
                            (incr_flit_o                                  ) ? (`V_ALL1(MS_TIMESTAMP_w)-flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB]) + current_timestamp_i + 1: //flit_ts > current_ts
                                                                              `V_ZERO(MS_TIMESTAMP_w);




    assign msg_latency_o  = (ms_header_tail)                                      ? flit_latency_o :                                                            //header_tail case
                            (incr_msg_o & ~header_timestamp_greater_than_current) ? (current_timestamp_i - timestamp_last_header):                              //header case
                            (incr_msg_o                                         ) ? (`V_ALL1(MS_TIMESTAMP_w)-timestamp_last_header) + current_timestamp_i + 1: //header and flit_ts > current_ts
                                                                                    `V_ZERO(MS_TIMESTAMP_w);
    //********************************************************************************************************
    // *****************************************************************
    // Aditionals
    //******************************************************************
    assign                       timestamp_greater_than_current = (flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB] > current_timestamp_i);
    assign                       header_timestamp_greater_than_current = (timestamp_last_header > current_timestamp_i);

    assign  timestamp_from_flit = (incr_flit_o) ? flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB] : `V_ZERO(MS_TIMESTAMP_w);

    // wire [8:0]  xjumps = ((TLID%4) > (flit[`MS_OUT_SRC_RANGE]%4)) ? (TLID%4) - (flit[`MS_OUT_SRC_RANGE]%4):
    //                      ((TLID%4) < (flit[`MS_OUT_SRC_RANGE]%4)) ? (flit[`MS_OUT_SRC_RANGE]%4) - (TLID%4): `V_ZERO(9);
    // wire [8:0]  yjumps = ((TLID/4) != (flit[`MS_OUT_SRC_RANGE]/4)) ? 9'd1: `V_ZERO(9);
    // wire [8:0]  jumps = (xjumps + yjumps)+1;
    // wire [8:0]  generate_and_inject_cycles = 1+5;

    always @ (posedge clk) begin
      if (rst) begin
          Counter_VN   <= 64'd0;
          timestamp_last_header <= `V_ZERO(MS_TIMESTAMP_w);
        end else begin
        if (valid) begin
          if(valid & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] != `MS) & (flit_type==`header | flit_type==`header_tail)) begin
            $display ("VN%1d_eject ID %1d, SRC %1d, COUNTER: %d, at:%t\n", VNID, ID, flit[`MSG_TLSRC_MSB:`MSG_TLSRC_LSB], Counter_VN, $realtime);
          end // non MS
          Counter_VN <= Counter_VN + 64'd1;
          //if ((Counter_VN%1000) == 0) begin
            // $display ("VN%d_eject: ID%0d, COUNTER: %d", VNID, TLID, (Counter_VN));
          //end
          if (incr_flit_o) begin
            $display ("VN%1d_eject Flit: ID %1d, flit_latency_o %2d, ", VNID, ID, flit_latency_o);
            if(ms_header)begin
              timestamp_last_header <= timestamp_from_flit;
            end // end receiving_ms_header
            else if(incr_msg_o) begin
              $display ("VN%1d_eject Message: ID %1d, flit_latency_o %2d, ", VNID, ID, msg_latency_o);
            end // end incr_msg
          end // end incr_flit

        end //end if valid

      end // end else rst_p
    end // end always

  // end
endgenerate





endmodule
