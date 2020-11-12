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
// Module Name: VN1_eject
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

module VN1_eject #(
                  parameter  ENABLE_MESSAGE_SYSTEM_SUPPORT = "no",
                  parameter ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT = "no",
                  parameter ID = 0,
                  parameter  VNID = 1,
                  parameter  CORES_PER_TILE = 1,
                  parameter  FLIT_SIZE = 64,
                  localparam DATA_NET_FLIT_w = FLIT_SIZE,
                  localparam PADDING = {(`VN1_MSG_w-`DATA_NET_FLIT_w){1'b0}},
                  localparam LOG_CORES_PER_TILE = Log2_w(CORES_PER_TILE),
                  localparam LOG_CORES_PER_TILE_GOOD    = Log2(CORES_PER_TILE)
                 )(
                 avail_fL1D, 
                 avail_fL2, 
                 clk, 
                 timestamp_in,
                 flit, 
                 flit_type, 
                 broadcast,
                 rst, 
                 valid, 
                 go, 
                 msg, 
                 broadcast_toL1D,
                 broadcast_toL2,
                 req_toL1D, 
                 req_toL2/*,

                 req_toMS,
                 data_toMS,
                 avail_fMS*/

                 );
                 
    input avail_fL1D;
    input avail_fL2;
    input clk;
    input [63:0] timestamp_in;
    input [63:0] flit;
    input [1:0] flit_type;
    input broadcast;
    input rst;
    input valid;
   output go;
   output reg [`VN1_MSG_w-1:0] msg;
   output reg req_toL1D;
   output reg req_toL2;
   output reg broadcast_toL1D;
   output reg broadcast_toL2;

   // output reg req_toMS;                         // message system
   // output reg [37:0] data_toMS;                 // message system. num_flits + type + sender + dest
   // input avail_fMS;                            // message system
  `include "common_functions.vh"

  reg [3:0] flit_number;
  reg toL1Dreg;
  reg toL2reg;
  wire buffered;
  wire completed;
  
  reg tail_received;
  
  assign go = ~buffered;
  
  wire toL1D = (valid & ((flit_type == `header) | (flit_type == `header_tail)) & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L1_cache)) | toL1Dreg;
  wire toL2   = (valid & ((flit_type == `header) | (flit_type == `header_tail)) & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L2_cache)) | toL2reg;
  
    assign completed = ((valid & ((flit_type == `tail) | (flit_type == `header_tail))) | ((toL1D | toL2) & tail_received));

  assign buffered = completed & ((toL1D & ~avail_fL1D) | (toL2 & ~avail_fL2));
  
  reg [63:0] Counter_VN;
  reg waiting_tail;
 
  // generate
  //   if (ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT == "yes") begin
  //     always @ (posedge clk)
  //       if  (valid) $display("                                                                              VN1 EJECT: %h SRC: %d DST: %d TYPE %h", flit, flit[`MSG_TLSRC_MSB:`MSG_TLSRC_LSB], ID, flit_type);
  //   end
  // endgenerate
          
        
always @ (posedge clk)
if (rst) begin
   req_toL1D <= 0;
  req_toL2 <= 0;
  toL1Dreg <= 0;
  toL2reg <= 0;
  tail_received <= 0;
  flit_number <= 0;
  msg <= 0; 
  broadcast_toL1D <= 1'b0;
    broadcast_toL2  <= 1'b0;
      waiting_tail <= 1'b0;
      Counter_VN <= `VZERO(64);

end else begin
  // Let's check if there is an incomming flit

      
  if (valid) begin

      Counter_VN <= Counter_VN + `VONE(64);
      // if ((Counter_VN%1000) == 0) begin
      // $display ("VN1_eject: ID%0d, COUNTER: %d", ID, (Counter_VN));
      // end
      // $display ("VN%1d_eject ID %1d, SRC %1d, COUNTER: %d", VNID, ID, flit[`MSG_TLSRC_MSB:`MSG_TLSRC_LSB], Counter_VN);

 
      
    case (flit_type)
      `header_tail: begin
                      msg[`MSG_HOME_MSB:0] <= {PADDING,flit};
                      toL1Dreg <= ~avail_fL1D & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L1_cache);
                      toL2reg <= ~avail_fL2 & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L2_cache);
                      tail_received <= 1;
                      broadcast_toL1D <= broadcast & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L1_cache);
                                            broadcast_toL2 <= broadcast & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L2_cache);
                      if (waiting_tail) $display("%t ERROR!\n", $realtime);
                     end
        `header:    begin
                      msg[63:0] <= flit;
                      flit_number <= 1;
                      toL1Dreg <= (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L1_cache);
                      toL2reg <= (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L2_cache);
                      tail_received <= 0;
                      broadcast_toL1D <= 1'b0;
                      broadcast_toL2 <= 1'b0;
                        waiting_tail <= 1'b1;
                        if (waiting_tail) $display("%t ERROR!\n", $realtime);
                    end
        `payload: begin
                      case (flit_number)
                        1: msg[127:64] <= flit;
                        2: msg[191:128] <= flit;
                        3: msg[255:192] <= flit;
                        4: msg[319:256] <= flit;
                        5: msg[383:320] <= flit;
                        6: msg[447:384] <= flit;
                        7: msg[511:448] <= flit;
                        8: msg[575:512] <= flit;
                      endcase
                      flit_number <= flit_number + 4'b0001;
                      broadcast_toL1D <= 1'b0;
                      broadcast_toL2 <= 1'b0;
                    end
          `tail:      begin
                                 case (flit_number)
                                                1: msg[`MSG_HOME_MSB:64]  <= {flit[`TLID_w-1:0], 512'b0};  //short message without datablock, but home field (two flits message)
                                                8: msg[`MSG_HOME_MSB:512] <= {{`TLID_w{1'b0}},flit};            //long message with datablock, but not home field (9 flits message)
                                                9: msg[`MSG_HOME_MSB:576] <= flit[`TLID_w-1:0];            //long message with datablock and home field  (10 flits message)
                                            endcase
                      toL1Dreg <= toL1Dreg & ~avail_fL1D;
                      toL2reg <= toL2reg & ~avail_fL2;
                      tail_received <= 1;
                      broadcast_toL1D <= 1'b0;
                      broadcast_toL2 <= 1'b0;
                      waiting_tail <= 1'b0;
                  end
    endcase
  end
  
  // we filter out non L1D and L2 receptions
  if (completed & ~toL1D & ~toL2) begin
    tail_received <= 1'b0;
    broadcast_toL1D <= 1'b0;
    broadcast_toL2 <= 1'b0;
  end
  
  if (avail_fL1D & (completed | buffered) & toL1D) begin
    req_toL1D <= 1;
    tail_received <= 0;
    toL1Dreg <= 0;
  end else begin
    req_toL1D <= 0;
    //if (~valid & avail_fL1D) broadcast_toL1D <= 1'b0; 
  end

  if (avail_fL2 & (completed | buffered) & toL2) begin
    req_toL2 <= 1;
    tail_received <= 0;
    toL2reg <= 0;
  end else begin
    req_toL2 <= 0;
    //if (~valid & avail_fL2) broadcast_toL2 <= 1'b0; 
  end
  
end  

//---------------------------------------------------------MESSAGE_SYSTEM_SUPPORT ---------------------------------------------------------------------------------
  wire w_message_system;
  reg receiving_ms;                               // message system
  wire receiving_ms_header;                       // message system
  wire receiving_ms_header_tail;                  // message system
  wire receiving_ms_tail;                         // message system
  if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin
    assign w_message_system = 1'b1;
  end else begin
    assign w_message_system = 1'b0;
  end


generate
  if (ENABLE_MESSAGE_SYSTEM_SUPPORT == "yes") begin
  reg [63:0] Counter_VN;
    // If message_system defined then we use a register bit (flag) to remember we are receiving an explicit message
    assign receiving_ms_header = valid & (flit_type == `header) & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `MS);
    assign receiving_ms_header_tail = valid & (flit_type == `header_tail) & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `MS);
    assign receiving_ms_tail = receiving_ms & valid & (flit_type == `tail);//  & (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `MS);
  
  // We annotate the size, type and sender
  reg [8:0] sender_ms;
  reg [8:0] destination_ms;
  reg [3:0] type_ms;
  reg [15:0] size_ms;
  

  always @ (posedge clk)
  begin
      if (rst) begin
        receiving_ms <= 1'b0;                                                               
        Counter_VN <= `VZERO(64);
      end else begin                                                                        

        if (receiving_ms_header) receiving_ms <= 1'b1;                                                             
      if (receiving_ms_tail) receiving_ms <= 1'b0;              

    if (valid) begin
      Counter_VN <= Counter_VN + `VONE(64);
      if ((Counter_VN%1000) == 0) begin
        //$display ("VN1_eject: ID%0d, COUNTER: %d", ID, (Counter_VN));
      end
        //$display ("VN0_eject COUNTER: %d", Counter_VN);

    end

      // if (ENABLE_NETWORK_DEBUG_LEVEL_1_SUPPORT == "yes") begin
      //     if (w_message_system & valid & ~receiving_ms & ~receiving_ms_header & ~receiving_ms_header_tail) begin
      //       if ((Counter_VN%1000) == 0) begin
      //         $display("                                                                                                               VN1 EJECT: %h SRC: %d DST: %d TYPE %h ", flit, flit[`MSG_TLSRC_MSB:`MSG_TLSRC_LSB], ID, flit_type);
      //       end
      //     end
      //   end

      if (receiving_ms_header | receiving_ms_header_tail) begin
        sender_ms <= flit[`MSG_TLSRC_MSB:`MSG_OFSRC_LSB];
        destination_ms <= flit[`MSG_TLDST_MSB:`MSG_OFDST_LSB]; 
        type_ms <= flit[15:12];
        size_ms <= flit[31:16];
        end
    end                                                                                                                                          
    end
    
    // // Interface implementation to the MS_fnet
    // reg  toMSreg;    // flag to know a message is pending to be sent to the ms_fnet
    // always @ (posedge clk)
    // if (rst) begin
    //   req_toMS <= 1'b0;
    //   toMSreg <= 1'b0;
    // end else begin
    //   if (receiving_ms_tail) begin
    //     toMSreg <= 1'b1;
    //     data_toMS <= {size_ms, type_ms, sender_ms, destination_ms};
    //   end else if (receiving_ms_header_tail) begin
    //     toMSreg <= 1'b1;
    //     data_toMS <= {flit[31:16], flit[15:12], flit[`MSG_TLSRC_MSB:`MSG_OFSRC_LSB], flit[`MSG_TLDST_MSB:`MSG_OFDST_LSB]};
    //   end        

    //   if (avail_fMS & toMSreg) begin
    //     req_toMS <= 1'b1;
    //     toMSreg <= 1'b0;
    //   end else begin
    //     req_toMS <= 1'b0;
    //   end
    // end //if rst
  end //ENABLE_MESSAGE_SYSTEM_SUPPORT
endgenerate

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
    assign                     header_timestamp_greater_than_current = (timestamp_last_header > current_timestamp_i);

    assign timestamp_from_flit = (incr_flit_o) ? flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB] : `V_ZERO(MS_TIMESTAMP_w);

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
            if((ID!=0) | (flit[`MSG_NTDST_MSB:`MSG_DST_LSB] == `L1_cache)) begin
              $display ("VN%1d_eject ID %1d, SRC %1d, COUNTER: %d, at:%t, FlitInfo:%h\n", VNID, ID, flit[`MSG_TLSRC_MSB:`MSG_TLSRC_LSB], Counter_VN, $realtime, flit);
            end
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

   
