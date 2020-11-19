`ifndef __DATA_NET_MESSAGE_FORMAT_H__
`define __DATA_NET_MESSAGE_FORMAT_H__
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
// Create Date: November 11, 2016
// File Name: data_net_message_format.h
// Design Name: 
// Module Name:
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//  This file includes the definitions for the format of the DATA Messages
//  interchanged among components of the same or differnt TILEs through
//  a NI
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////



// MSG types
`define MSG_TYPE_0    2'b00         // Message type: read request, senders CORE (to TR) and L1I (to MC) (single flit message)
`define MSG_TYPE_1    2'b01         // Message type: write request, senders CORE (to TR) and TR answering a read request (to CORE) (single flit message)
`define MSG_TYPE_2    2'b10         // Message type: senders L1D, L2, MC (1/2-flit message)
`define MSG_TYPE_3    2'b11         // Message type: senders L1D, L2, MC (9/10-flit message)

// MSG field width
`define MSG_TYPE_w     2            // Message format: message type field width (in bits)
`define ADDR_w         32           // Message format: Addr field width (in bits)   
`define SRC_w          `NODE_ID_w   // Message format: SRC field width (in bits)
`define DST_w          `NODE_ID_w   // Message format: DST field width (in bits)
`define REG_w          5            // Message format: Register field width (in bits)
`define BA_w           26           // Message format: Block Address field width (in bits)
`define DATA_w         32           // Message format: Data field width (in bits)
`define ACK_w          6            // Message format: number of ACKs field width (in bits)
`define CMD_w          6            // Message format: Command field width (in bits)
`define DB_w           512          // Message format: Data Block field width (in bits)
`define MSG_WORD_DATA_w 32          // Message format: Word data field (for word-size accesses to memory)
`define MSG_WORD_OFFSET_w 4         // Message format: Word offset field (for word-size accesses to memory)
`define MSG_BYTE_OFFSET_w 2         // Message format: Byte offset field (for half- and byte-size accesses to memory)

//MSG format. All messages
`define MSG_BA_LSB      0                                 // Block address lsb
`define MSG_BA_MSB      `BIT(`MSG_BA_LSB, `BA_w)          // Block address msb
`define MSG_DATA_LSB    0                                 // Data lsb
`define MSG_DATA_MSB    `BIT(`MSG_DATA_LSB, `DATA_w)      // Data msb
`define MSG_CMD_LSB     26                                // Command lsb
`define MSG_CMD_MSB     `BIT(`MSG_CMD_LSB, `CMD_w)        // Command msb
`define MSG_ACK_LSB     32                                // ACK lsb
`define MSG_ACK_MSB     `BIT(`MSG_ACK_LSB, `ACK_w)        // ACK msb
`define MSG_REG_LSB     33                                // REG lsb
`define MSG_REG_MSB     `BIT(`MSG_REG_LSB, `REG_w)        // REG msb
`define MSG_DST_LSB     38                                // DST, DST Node Type lsb
`define MSG_DST_MSB     `BIT(`MSG_DST_LSB, `DST_w)        // DST msb
`define MSG_NTDST_MSB   `BIT(`MSG_DST_LSB, 3)             // DST Node type MSB
`define MSG_OFDST_LSB   41                                // Offset dst lsb                     // PEPE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
`define MSG_OFDST_MSB   `BIT(`MSG_OFDST_LSB, LOG_CORES_PER_TILE_GOOD)  // Offset dst msb                     // PEPE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
`define MSG_TLDST_LSB   `BIT(`MSG_OFDST_MSB, 2)           // Tile Dst lsb                       // PEPE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
`define MSG_TLDST_MSB   `MSG_DST_MSB                      // Tile Dst msb                       // PEPE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
`define MSG_SRC_LSB     50                                // SRC, SRC Node type lsb
`define MSG_SRC_MSB     `BIT(`MSG_SRC_LSB, `SRC_w)        // SRC msb
`define MSG_NTSRC_MSB   `BIT(`MSG_SRC_LSB, 3)             // SRC Node type msb
`define MSG_OFSRC_LSB   53
`define MSG_OFSRC_MSB   `BIT(`MSG_OFSRC_LSB, LOG_CORES_PER_TILE_GOOD)
`define MSG_TLSRC_LSB   `BIT(`MSG_OFSRC_MSB, 2)
`define MSG_TLSRC_MSB   `MSG_SRC_MSB
`define MSG_TYPE_LSB    62                                // Msg type lsb    
`define MSG_TYPE_MSB    `BIT(`MSG_TYPE_LSB, `MSG_TYPE_w)  // Msg type msb
`define MSG_DB_LSB      64                                // Data block lsb
`define MSG_DB_MSB      `BIT(`MSG_DB_LSB, `DB_w)          // Data block msb
`define MSG_HOME_LSB    576                               // Home lsb
`define MSG_HOME_MSB    `BIT(`MSG_HOME_LSB, `TLID_w)      // Home msb
`define MSG_WORD_DATA_LSB 64                                                  // Word data lsb
`define MSG_WORD_DATA_MSB `BIT(`MSG_WORD_DATA_LSB, `MSG_WORD_DATA_w)          // Word data msb
`define MSG_WORD_OFFSET_LSB 32                                                // Word offset lsb
`define MSG_WORD_OFFSET_MSB `BIT(`MSG_WORD_OFFSET_LSB, `MSG_WORD_OFFSET_w)    // Word offset msb
`define MSG_BYTE_OFFSET_LSB 36                                                // Byte offset lsb
`define MSG_BYTE_OFFSET_MSB `BIT(`MSG_BYTE_OFFSET_LSB, `MSG_BYTE_OFFSET_w)    // Byte offset msb

// MSG widths (in bits)
`define L1_MSG_w    `MSG_HOME_MSB+1                 // This is between L1D_tonet and VN{0,1}_inject. Currently it is the msg home field msb + 1
`define L2_MSG_w    `MSG_HOME_MSB+1                 // This is between L2_tonet and VN{0,1,2}_inject. Currently is the same as the L1D Message, but could be different
`define MC_MSG_w    `MSG_DB_MSB+1                   // This is between MC_tonet and VN2_inject. Currently it is the msg datablock field msb + 1
`define VN0_MSG_w   `MAX(`L1_MSG_w, `L2_MSG_w)      // This is between VN0_inject and VN0_eject. VN0_inject can inject L1D and L2 messages, that's because of this is the max(L1_MSG_w, L2_MSG_w)
`define VN1_MSG_w   `MAX(`L1_MSG_w, `L2_MSG_w)      // This is between VN1_inject and VN1_eject. VN1_inject can inject L1D and L2 messages, that's because of this is the max(L1_MSG_w, L2_MSG_w)
`define VN2_MSG_w   `MSG_DB_MSB+1                   // This is between VN2_inject and VN2_eject. Currently it is the msg datablock field msb + 1   
  
`define PADDING_FLIT_HOME {`FLIT_w-`TLID_w{1'b0}}    // Padding due to the need of sending the Home id in RHM, before it was coded in Address LSBs, but now we use an additional flit
//



`endif // header file
