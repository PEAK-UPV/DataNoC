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
// Engineer: T. Picornell (tompic@gap.upv.es
// Contact: J.Flich (jflich@disca.upv.es)
// Create Date: 
// File Name: ms.v
// Module Name: MS_tonet
// Project Name: DataNoC
// Target Devices: 
// Description: 
//
//  This file defines the MS component. For more details, see archspec document in the docs/archspec folder
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

`include "macro_functions.h"
`include "net_common.h"
`include "data_net_message_format.h"
`include "synthetic_traffic_generator.h"

module MS_tonet
 #(
  parameter ID = 0,
  parameter CORES_PER_TILE = 1,
  parameter NUM_NODES = 1
 ) (
  input clk,                                          // clock input
  input rst_p,                                          // rst_p input
  input [63:0] timestamp_in,
  input [38:0] MessageSystem_in,                      // Message request from the NI (req + num_flits + type + sender + dest)
  output reg [63:0] FlitOut,                          // Flit to inject
  output reg [1:0] FlitType,                          // Flit type (to inject)
  output reg req_tonet,                               // Request to the network
  output reg req_tolocal,                             // Request to local node
  output reg [37:0] data_tolocal,                     // data to local ms_fnet (size + type + sender + dest)
  output [1:0] vn_to_inject,
  input  avail_net,                                   // Available signal from the network
  input  avail_local                                  // Available signal from local
 );

localparam msg_queue_size_p = `MESSAGE_SYSTEM_QUEUE_SIZE;
localparam log_queue_size = `WIDTH(msg_queue_size_p);
localparam lsb_tid = `WIDTH(CORES_PER_TILE);
localparam msb_tid = 8;
localparam LOG_CORES_PER_TILE = `WIDTH(CORES_PER_TILE);
localparam log_num_nodes = `WIDTH(NUM_NODES);
localparam synth_function = `SYNTH_FUNCTION;
localparam synth2_function = `SYNTH2_FUNCTION;

wire [11:0] id = ID;

// We define queue structure to store all requests from the TILEREGs
reg [21:0] fifo_req     [msg_queue_size_p-1:0];
reg [15:0] fifo_req_ctr [msg_queue_size_p-1:0];
reg [15:0] current_counter;

reg [log_queue_size-1:0] read_ptr;
reg [log_queue_size-1:0] write_ptr;
reg [log_queue_size:0]   num_reqs;

reg [8:0]  random_value;
reg        synth_inject_new;

reg header_sent;                                    // Just tells us whether the header has been sent for the current message (kept to one during message transmission)
reg tail_sent;                                      // Just tells us whether the tail has been sent for the current message (kept to one only during tail transmission cycle)

// synthetic traffic mode
reg        synth_mode;
reg        synth2_mode;
reg [8:0]  destination_synth2;  // destination in SYNTH2 mode
reg [1:0]  vn_synth2;
reg        synth_on;               // switch to enable synthetic traffic pattern generator
reg [3:0]  synth_rate;
reg [15:0] synth_msg_size;
//reg [8:0]  synth_timestamp;
reg [31:0] synth_counter_down;
wire [8:0] synth_dest = (synth_mode) ? {`VZERO(9-log_num_nodes),random_value[log_num_nodes-1:0]}:
                        (synth2_mode) ? destination_synth2 : 9'd0;
reg [15:0] synth_current_msg_size;
reg        synth_injecting;
reg [1:0] random_vn_to_inject;
//Aditionals for synth2 mode

assign vn_to_inject = (synth_mode) ? random_vn_to_inject:
                      (synth2_mode) ? vn_synth2 : 2'd0;


wire empty_queue = ~|num_reqs;


// helping wires
wire [37:0] fifo_read_bits = {current_counter,fifo_req[read_ptr]};
wire [15:0] current_message_size = fifo_read_bits[37:22];
wire [8:0]  current_message_dest = fifo_read_bits[8:0];
wire [8:0]  current_message_src  = fifo_read_bits[17:9];
wire [3:0]  current_message_type = fifo_read_bits[21:18];
wire        only_one_flit        = (current_message_size == 1);


// wires to know the destination (local or network)
wire tonet   = ~empty_queue & (fifo_read_bits[msb_tid:lsb_tid] != ID) & (|current_message_size);
wire tolocal = ~empty_queue & (fifo_read_bits[msb_tid:lsb_tid] == ID) & (|current_message_size);


// we aeare the tile bits from synth_dest are obtained using msb_tid and lsb_tid, which assumes id starts at bit 0
wire synth_tonet = (synth_on & synth_inject_new & (synth_dest[msb_tid:lsb_tid] != ID)) | synth_injecting;
wire synth_tolocal = synth_on & synth_inject_new & (synth_dest[msb_tid:lsb_tid] == ID) & ~synth_injecting;

// we achieve a random number to determine in which virtual network will inject.
// Instantiate the random unit generator
 wire [12:0] rnd;
  LFSR_seed random_seed (
   .clock(clk),
   .rst_p(rst_p),
   .seed(ID[3:0]),
   .rnd(rnd)
  );


always @ (posedge clk)
if (rst_p) begin
// Block to handle the FSM of the synth traffic generator
// synth_timestamp <= 9'b0;
 synth_on <= 1'b0;              // switch to enable synthetic traffic pattern generator
 random_value <= rnd[9:1];
 synth_injecting <= 1'b0;
 synth_inject_new <= 1'b0;
//------------------------------------------------------------------------------------------
 // Block to handle the queue
 read_ptr <= `VZERO(log_queue_size);
 write_ptr <= `VZERO(log_queue_size);
 num_reqs <= `VZERO(log_queue_size+1);
//------------------------------------------------------------------------------------------
 // Block to handle the generation of flits
// if synth is on the traffic is ONLY generated from the synth generator, not from the queue
 req_tonet <= 1'b0;
 req_tolocal <= 1'b0;
 header_sent <= 1'b0;
 tail_sent <= 1'b0;
 random_vn_to_inject <= (rnd % 2'd3);

end else begin

// Block to handle the FSM of the synth traffic generator
// synth_timestamp <= synth_timestamp + 9'b1;

 if ((MessageSystem_in[38]) && ((MessageSystem_in[21:18] == synth_function) || (MessageSystem_in[21:18] == synth2_function))) begin
  // A message switches off the synthetic traffic injector or switches it on only if rate and message size are not zero (both)
  if (synth_on) synth_on <= 1'b0;
  else begin
    synth_inject_new <= 1'b1;
    synth_on <= |MessageSystem_in[3:0] && |MessageSystem_in[37:22];
    synth_rate <= MessageSystem_in[3:0];            // rate comes in the four least significant bits of dest field
    synth_msg_size <= MessageSystem_in[37:22];      // Message size
    synth_counter_down <= MessageSystem_in[3:0] * MessageSystem_in[37:22];
    synth_current_msg_size <= MessageSystem_in[37:22];
    synth_mode <= (MessageSystem_in[21:18] == synth_function);

    synth2_mode <= (MessageSystem_in[21:18] == synth2_function);
    vn_synth2 <= MessageSystem_in[14:13];
    destination_synth2 <= MessageSystem_in[12:4];
  end
 end

 if (synth_on) begin
  if ( (~(|synth_counter_down)) | (synth_rate==4'd1 & (synth_current_msg_size == 16'b1))) begin
    synth_inject_new <= 1'b1;
    synth_counter_down <= synth_rate * synth_msg_size;
    random_value <= rnd[9:1];
  end else begin
    synth_counter_down <= synth_counter_down - 32'b1;
  end
 end
//------------------------------------------------------------------------------------------
// Block to handle the queue
 if ((MessageSystem_in[38]) && (MessageSystem_in[21:18] != synth_function)) begin
    fifo_req[write_ptr] <= MessageSystem_in[21:0];
    fifo_req_ctr[write_ptr][15:0] <= MessageSystem_in[37:22];
    write_ptr <= write_ptr + 1;
    if (~tail_sent) begin
      num_reqs <= num_reqs + 1;
    end
 end

 if (tail_sent & ~synth_on) begin
    read_ptr <= read_ptr + 1;

   if ((MessageSystem_in[38]) && (MessageSystem_in[21:18] != synth_function) & (num_reqs == 0)) begin
     current_counter <= MessageSystem_in[37:22];
   end else if (tail_sent & ~empty_queue) begin
     current_counter <= fifo_req_ctr[read_ptr];
   end

    if (~MessageSystem_in[38]) begin
      num_reqs <= num_reqs - 1;
    end
 end
//------------------------------------------------------------------------------------------
// Block to handle the generation of flits
// if synth is on the traffic is ONLY generated from the synth generator, not from the queue
 if (synth_on | synth_injecting) begin

   if (synth_tonet & avail_net) begin
    if (~header_sent) begin
      FlitOut  <= {`MSG_TYPE_0,                      // Messsage type
                 timestamp_in[8:0],                   // timestamp in the sender field (9 bits)
                 `MS,                               // sender type
                 synth_dest,                        // destination node
                 `MS,                               // destination type
                 6'b0,
                 synth_msg_size,
                 synth_function,
                 id};                            //
      FlitType <= (synth_current_msg_size == 1)?`header_tail:`header;
      random_vn_to_inject <= (rnd % 2'd3);
      synth_injecting <= (synth_current_msg_size != 1);
      synth_inject_new <= (synth_rate==4'd1 & (synth_current_msg_size == 16'b1)) ? 1'b1 : 1'b0;
    end else begin
      FlitOut  <= {2'b0,                      // Messsage type
                         timestamp_in[8:0],                   // timestamp in the sender field (9 bits)
                         `MS,                               // sender type
                         synth_dest,                        // destination node
                         `MS,                               // destination type
                         6'b0,
                         16'b0,
                         4'b0,
                         id};
      FlitType <= (synth_current_msg_size == 1)?`tail:`payload;
      synth_injecting <= (synth_current_msg_size != 1);
    end

    header_sent <= (synth_current_msg_size != 1);
    tail_sent <= (synth_current_msg_size == 16'b1);
    req_tonet <= synth_tonet;
    req_tolocal <= 1'b0;
    if (synth_current_msg_size != 1)
      synth_current_msg_size <= synth_current_msg_size - 16'b1;
    else
      synth_current_msg_size <= synth_msg_size;

   end else if (synth_tolocal & avail_local) begin

    data_tolocal <= {synth_msg_size, synth_function, timestamp_in[8:0], synth_dest};
    req_tolocal <= synth_tolocal;
    req_tonet <= 1'b0;
    tail_sent <= 1'b1;
    header_sent <= 1'b0;
    synth_inject_new <= (synth_rate==4'd1 & (synth_current_msg_size == 16'b1)) ? 1'b1 : 1'b0;

   end else begin
    req_tolocal <= 1'b0;
    req_tonet <= 1'b0;
    tail_sent <= 1'b0;
   end

 end else begin // ------------

   if (~empty_queue & ((tonet & avail_net))) begin
    if (~header_sent) begin
      FlitOut  <= {`MSG_TYPE_0,                      // Messsage type
                 timestamp_in[8:0],                   // timestamp in the sender field (9 bits)
                 `MS,                               // Sender type
                 current_message_dest,              // destination node
                 `MS,                               // destination type
                 6'b0,
                 current_message_size,
                 current_message_type,
                 id};                            //
      FlitType <= (current_message_size == 1)?`header_tail:`header;
      random_vn_to_inject <= (rnd % 2'd3);
    end else begin
      FlitOut  <= {2'b0,                      // Messsage type
                         timestamp_in[8:0],                   // timestamp in the sender field (9 bits)
                         `MS,                               // sender type
                         synth_dest,                        // destination node
                         `MS,                               // destination type
                         6'b0,
                         16'b0,
                         4'b0,
                         id};
      FlitType <= (current_message_size == 1)?`tail:`payload;
    end

    header_sent <= (current_message_size != 1);
    tail_sent <= (current_message_size == 16'b1);
    req_tonet <= tonet;
    current_counter <= current_counter - 16'b1;

   end else if (~empty_queue & (tolocal & avail_local)) begin

    data_tolocal <= {current_message_size, current_message_type, current_message_src, current_message_dest};
    req_tolocal <= tolocal;
    tail_sent <= 1'b1;

   end else begin
    req_tolocal <= 1'b0;
    req_tonet <= 1'b0;
    tail_sent <= 1'b0;
   end

 end

end


endmodule


module MS_fnet # (
  parameter  ID                 = 0,
  parameter  CORES_PER_TILE     = 1,
  localparam LOG_CORES_PER_TILE = `WIDTH(CORES_PER_TILE),     // Log number of cores per tile
  localparam width_core_dest    = (LOG_CORES_PER_TILE > 0)?LOG_CORES_PER_TILE:1,
  localparam lsb_toff           = 0,
  localparam msb_toff           = (LOG_CORES_PER_TILE > 0)?`WIDTH(CORES_PER_TILE)-1:0,
  localparam width_tr_dest      = (LOG_CORES_PER_TILE > 0)?LOG_CORES_PER_TILE:1

)(
    clk,                                   // clock input
    rst_p,                                   // rst_p input
    timestamp_in,
    valid,                        // request from local
    flit,                       // data from local (size + type + sender + destination)
    flit_type
);

input clk;
input rst_p;
input [63:0] timestamp_in;
input valid;
input [63:0] flit;
    input [1:0] flit_type;



// we define register buffers for incoming requests
reg [37:0] buf_from_net;
reg [37:0] buf_from_local;
reg        pending_from_net;
reg        pending_from_local;



localparam MS_TIMESTAMP_w = `MS_TIMESTAMP_w;
localparam MS_OUT_TIMESTAMP_LSB = `MS_OUT_TIMESTAMP_LSB;
localparam MS_OUT_TIMESTAMP_MSB = `MS_OUT_TIMESTAMP_MSB;
  wire  [MS_TIMESTAMP_w-1:0] current_timestamp_i = timestamp_in[MS_TIMESTAMP_w-1:0];  // Current system timestamp
  wire                       incr_flit_o;
  wire                       incr_msg_o;
  wire [MS_TIMESTAMP_w-1:0] flit_latency_o;
  wire [MS_TIMESTAMP_w-1:0] msg_latency_o;

  wire ms_header = incr_flit_o & (flit_type == `header);
  wire ms_header_tail = incr_flit_o & (flit_type == `header_tail);
  wire ms_tail = incr_flit_o & (flit_type == `tail);

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
  wire                       timestamp_greater_than_current = (flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB] > current_timestamp_i);
  wire                       header_timestamp_greater_than_current = (timestamp_last_header > current_timestamp_i);

  wire [MS_TIMESTAMP_w-1:0] timestamp_from_flit = (incr_flit_o) ? flit[MS_OUT_TIMESTAMP_MSB:MS_OUT_TIMESTAMP_LSB] : `V_ZERO(MS_TIMESTAMP_w);
  reg [MS_TIMESTAMP_w-1:0]  timestamp_last_header;

  // wire [8:0]  xjumps = ((TLID%4) > (flit[`MS_OUT_SRC_RANGE]%4)) ? (TLID%4) - (flit[`MS_OUT_SRC_RANGE]%4):
  //                      ((TLID%4) < (flit[`MS_OUT_SRC_RANGE]%4)) ? (flit[`MS_OUT_SRC_RANGE]%4) - (TLID%4): `V_ZERO(9);
  // wire [8:0]  yjumps = ((TLID/4) != (flit[`MS_OUT_SRC_RANGE]/4)) ? 9'd1: `V_ZERO(9);
  // wire [8:0]  jumps = (xjumps + yjumps)+1;
  // wire [8:0]  generate_and_inject_cycles = 1+5;

  // reg [63:0] Counter_VN;
  always @ (posedge clk) begin
    if (rst_p) begin
        // Counter_VN   <= 64'd0;
        timestamp_last_header <= `V_ZERO(MS_TIMESTAMP_w);
      end else begin
      if (valid) begin
        // Counter_VN = Counter_VN + 64'd1;
        //if ((Counter_VN%1000) == 0) begin
          // $display ("VN%d_eject: ID%0d, COUNTER: %d", VNID, TLID, (Counter_VN));
        //end
        if (incr_flit_o) begin
          $display ("Local_eject Flit: ID %1d, flit_latency_o %2d, ", ID, flit_latency_o);
          if(ms_header)begin
            timestamp_last_header <= timestamp_from_flit;
          end // end receiving_ms_header
          else if(incr_msg_o) begin
            $display ("Local_eject Message: ID %1d, flit_latency_o %2d, ", ID, msg_latency_o);
          end // end incr_msg
        end // end incr_flit

      end //end if valid

    end // end else rst_p
  end // end always
endmodule
