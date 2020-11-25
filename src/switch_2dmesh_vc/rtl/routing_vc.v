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
// Engineer: J. Flich (jflich@disca.upv.es)
// Contact: J. Flich (jflich@disca.upv.es)
// Create Date: September 3, 2013
// File Name: routing_vc.v
// Module Name: ROUTING_VC
// Project Name: DataNoC
// Target Devices:
// Description:
//
//
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`include "macro_functions.h"
`include "net_common.h"
`include "net_2dmesh.h"
`include "data_net_virtual_channel.h"

module ROUTING_VC(
            clk,
            rst_p,
            Cur,              //current id of the tile
            Port,             //to which input port is attached this routing unit (L->000, E->001, W->011, N->101, S->101)
            Req,              //routing request
            Flit,             //flit input
            FlitType,         //flit type input (flit type is not coded in the flit structure)
            BroadcastFlit,	  //is input flit broadcast?
            Grant_VA_FromN,       //Granted virtual channel in North port to this routing engine (feedback from VA_N).
            Grant_VA_FromE,
            Grant_VA_FromW,
            Grant_VA_FromS,
            Grant_VA_FromL,
            Grant_SA_FromN,       //Granted output port North to this routing engine (feedback from SA_N).
            Grant_SA_FromE,
            Grant_SA_FromW,
            Grant_SA_FromS,
            Grant_SA_FromL,

            FlitOut,           //flit output from the module
            FlitTypeOut,       //flit type output
            TailFlit,          //is a tail flit? (To notifiy the SA that this is the last flit of the packet)
            BroadcastFlitE,    //output flit has to be broadcasted to E
            BroadcastFlitS,
            BroadcastFlitW,
            BroadcastFlitN,
            BroadcastFlitL,
            Request_VA_E,                 //request virtual channel for output port to SA
            Request_VA_L,
            Request_VA_N,
            Request_VA_S,
            Request_VA_W,
            Request_SA_E,                 //available output ports for the current routed flit
            Request_SA_L,
            Request_SA_N,
            Request_SA_S,
            Request_SA_W,
            Avail             //routing engine ready for receiving requests
);

  parameter FPGA_DIMX          = 2;                 // FPGA number of Tiles in X-dimension
  parameter FPGA_DIMY          = 1;                 // FPGA number of Tiles in Y-dimension
  parameter FPGA_N_NxT         = 1;                 // FPGA number of Nodes per tile
  parameter FPGA_N_Nodes       = 2;                 // FPGA number of Total nodes in the topology
  parameter FPGA_DIMX_w        = 1;                 // FPGA X-Dim width
  parameter FPGA_DIMY_w        = 0;                 // FPGA Y-Dim width
  parameter FPGA_N_NxT_w       = 0;                 // FPGA Nodes per tile width
  parameter FPGA_N_Nodes_w     = 1;                 // FPGA Total nodes width
  parameter FPGA_SWITCH_ID_w   = 1;                 // ID width for switches
  parameter GLBL_DIMX          = 2;                 // Global number of tiles in X-dimension
  parameter GLBL_DIMY          = 1;                 // Global number of Tiles in Y-dimension
  parameter GLBL_N_NxT         = 1;                 // Global number of Nodes per tile
  parameter GLBL_N_Nodes       = 2;                 // Global number of Total nodes in the topology
  parameter GLBL_DIMX_w        = 1;                 // Global  X-Dim width
  parameter GLBL_DIMY_w        = 0;                 // Global  Y-Dim width
  parameter GLBL_N_NxT_w       = 0;                 // Global Nodes per tile width
  parameter GLBL_N_Nodes_w     = 1;                 // Total nodes width
  parameter GLBL_SWITCH_ID_w   = 1;                 // ID width for switches

  parameter FLIT_SIZE          = 64;
  parameter FLIT_TYPE_SIZE     = 2;
  parameter BROADCAST_SIZE     = 5;
  parameter DATA_NET_FLIT_DST_UNIT_ID_LSB = 1;
  parameter DATA_NET_FLIT_DST_UNIT_ID_MSB = 1;
  parameter LSB_DST_FLIT_FIELD = 0;

  localparam DIMX = GLBL_DIMX;
  localparam DIMY = GLBL_DIMY;
  localparam DIMX_w = GLBL_DIMX_w > 0 ? GLBL_DIMX_w : 1;
  localparam DIMY_w = GLBL_DIMY_w > 0 ? GLBL_DIMY_w : 1;
  localparam ID_SIZE = GLBL_SWITCH_ID_w;

    input clk;
    input rst_p;
    input [ID_SIZE-1:0] Cur;
    input [2:0] Port;
    input Req;
	input [FLIT_SIZE-1:0] Flit;
    input [FLIT_TYPE_SIZE-1:0] FlitType;
    input BroadcastFlit;
    input Grant_VA_FromN;
    input Grant_VA_FromE;
    input Grant_VA_FromW;
    input Grant_VA_FromS;
    input Grant_VA_FromL;
    input Grant_SA_FromN;
    input Grant_SA_FromE;
    input Grant_SA_FromW;
    input Grant_SA_FromS;
    input Grant_SA_FromL;

	output [FLIT_SIZE-1:0] FlitOut;
	output [FLIT_TYPE_SIZE-1:0] FlitTypeOut;
    output TailFlit;
	output BroadcastFlitN;
    output BroadcastFlitE;
    output BroadcastFlitW;
    output BroadcastFlitS;
    output BroadcastFlitL;
    output Request_VA_E;
    output Request_VA_L;
    output Request_VA_N;
    output Request_VA_S;
    output Request_VA_W;
    output Request_SA_E;
    output Request_SA_L;
    output Request_SA_N;
    output Request_SA_S;
    output Request_SA_W;
    output Avail;


	//they store the output ports requested by a header flit for the rest of the flits of the packet
    reg Nant, Sant, Eant, Want, Lant;

    //they store if VC of each port needs more requests
    reg VC_req_N,VC_req_S,VC_req_E,VC_req_W,VC_req_L;
    //they store if there is VC assigned for each port
    reg VC_assigned_N, VC_assigned_S, VC_assigned_E, VC_assigned_W, VC_assigned_L;
    //there is any grant form VA module?
    wire Grant_VA = Grant_VA_FromN | Grant_VA_FromS | Grant_VA_FromE | Grant_VA_FromW | Grant_VA_FromL;
    wire VC_assigned = Grant_VA | VC_assigned_N | VC_assigned_S | VC_assigned_E | VC_assigned_W | VC_assigned_L /*|
    (((ftype_buf==`header | ftype_buf==`header_tail) `ifdef VC_SUPPORT & Grant_VA `endif) & (((N1 & ~bc) | bc_n) | ((S1 & ~bc) | bc_s) | ((E1 & ~bc) | bc_e) | ((W1 & ~bc) | bc_w) | ((L1 & ~bc) | bc_l)))*/;

    reg buf_bc_n, buf_bc_s, buf_bc_e, buf_bc_w, buf_bc_l;

    reg [FLIT_SIZE-1      : 0] flit_buf;
    reg [FLIT_TYPE_SIZE-1 : 0] ftype_buf;

    reg buf_free;

     /*When a header flit arrives, it requests VA for a channel. Once it has a grant, for each flit in each packet if makes a request for output port to VA.
     Only when it flit achieves two grants (each from VA and SA) it is granted to leave ROUTING module
	*/
    wire grantedN = Grant_SA_FromN;
	wire grantedE = Grant_SA_FromE;
	wire grantedW = Grant_SA_FromW;
	wire grantedS = Grant_SA_FromS;
	wire grantedL = Grant_SA_FromL;

    wire granted = (Grant_SA_FromN) |
                   (Grant_SA_FromE) |
                   (Grant_SA_FromW) |
                   (Grant_SA_FromS) |
                   (Grant_SA_FromL);
    //let's get info for routing output computation
    wire [ID_SIZE-1:0] Dst = Req ? Flit[DATA_NET_FLIT_DST_UNIT_ID_MSB:DATA_NET_FLIT_DST_UNIT_ID_LSB] : `V_ZERO(ID_SIZE);
    wire               bc  = Req ? BroadcastFlit                       :  1'b0;

    //unicast outport computation
    wire [DIMX_w-1 : 0] x_cur;// = ((`DIMX_w) > 0 ? Cur[(`DIMX_w)-1:0] : 1'b0);
    wire [DIMY_w-1 : 0] y_cur;// = ((`DIMY_w) > 0 ? Cur[(`DIMY_w)+(`DIMX_w)-1:(`DIMX_w)] : 1'b0);
    wire [DIMX_w-1 : 0] x_dst;// = ((`DIMX_w) > 0 ? Dst[(`DIMX_w)-1:0] : 1'b0);
    wire [DIMY_w-1 : 0] y_dst;// = ((`DIMY_w) > 0 ? Dst[(`DIMY_w)+(`DIMX_w)-1:(`DIMX_w)] : 1'b0);

    if ((GLBL_DIMX_w) > 0) begin
      assign x_cur = Cur[(DIMX_w)-1:0];
      assign x_dst = Dst[(DIMX_w)-1:0];
    end else begin
      assign x_cur = 1'b0;
      assign x_dst = 1'b0;
    end

    if ((GLBL_DIMY_w) > 0) begin
      assign y_cur = Cur[(DIMY_w)+(DIMX_w)-1:(DIMX_w)];
      assign y_dst = Dst[(DIMY_w)+(DIMX_w)-1:(DIMX_w)];
    end else begin
      assign y_cur = 1'b0;
      assign y_dst = 1'b0;
    end

    wire N1 = (x_cur == x_dst) & (y_cur > y_dst)  & ~bc;
    wire E1 = (x_cur < x_dst)                     & ~bc;
    wire W1 = (x_cur > x_dst)                     & ~bc;
    wire S1 = (x_cur == x_dst) & (y_cur < y_dst)  & ~bc;
    wire L1 = (x_cur == x_dst) & (y_cur == y_dst) & ~bc;
    //end unicast

    //broadcast output port computation
    wire bc_n = (y_cur > 0)       & bc & (Port != `PORT_N);
    wire bc_s = (y_cur < DIMY-1) & bc & (Port != `PORT_S);
    wire bc_e = (x_cur < DIMX-1) & bc & ((Port == `PORT_W) || (Port == `PORT_L));
    wire bc_w = (x_cur > 0)       & bc & ((Port == `PORT_E) || (Port == `PORT_L));
    wire bc_l = (Port != `PORT_L) & bc;
    //end broadcast


    //available to ibuffer
    //assign next = granted & (GrantFromN | GrantFromS | GrantFromE | GrantFromW | GrantFromL) ;
    assign Avail = granted | buf_free;

    //output request to va signals
    /*wire Virtual_buf_free = ~(Req | ~buf_free);


    wire incoming_TailFlit = Req ? (FlitType==`header | FlitType==`header_tail) : 1'b0;

    wire Request_VA = (~Virtual_buf_free & ~VC_assigned) & (incoming_TailFlit | (ftype_buf==`header | ftype_buf==`header_tail));
    */
    //wire Request_VA = (~buf_free) & (ftype_buf==`header | ftype_buf==`header_tail);
    wire Request_VA = (Req) & (FlitType==`header | FlitType==`header_tail);
    assign Request_VA_N = ((Request_VA /*& ~Nant*/ /*& ~VC_assigned_N*/ & ((N1 & ~bc) | bc_n)) | VC_req_N) & ~Grant_VA_FromN;
    assign Request_VA_S = ((Request_VA /*& ~Sant*/ /*& ~VC_assigned_S*/ & ((S1 & ~bc) | bc_s)) | VC_req_S) & ~Grant_VA_FromS;
    assign Request_VA_E = ((Request_VA /*& ~Eant*/ /*& ~VC_assigned_E*/ & ((E1 & ~bc) | bc_e)) | VC_req_E) & ~Grant_VA_FromE;
    assign Request_VA_W = ((Request_VA /*& ~Want*/ /*& ~VC_assigned_W*/ & ((W1 & ~bc) | bc_w)) | VC_req_W) & ~Grant_VA_FromW;
    assign Request_VA_L = ((Request_VA /*& ~Lant*/ /*& ~VC_assigned_L*/ & ((L1 & ~bc) | bc_l)) | VC_req_L) & ~Grant_VA_FromL;

    //output request to sa signals (Frist of all we need a Grant from VA)
    wire TailFlit_granted = (ftype_buf==`tail | ftype_buf==`header_tail) & granted;
    // wire pre_Request_SA_N = /*~Grant_SA_FromN &*/ (Grant_VA_FromN | (VC_assigned_N & Nant /*SEGURAMENTE & ~Grant_SA_FromN*/)) & ~buf_free;
    // wire pre_Request_SA_S = /*~Grant_SA_FromS &*/ (Grant_VA_FromS | (VC_assigned_S & Sant /*SEGURAMENTE & ~Grant_SA_FromS*/)) & ~buf_free;
    // wire pre_Request_SA_E = /*~Grant_SA_FromE &*/ (Grant_VA_FromE | (VC_assigned_E & Eant /*SEGURAMENTE & ~Grant_SA_FromE*/)) & ~buf_free;
    // wire pre_Request_SA_W = /*~Grant_SA_FromW &*/ (Grant_VA_FromW | (VC_assigned_W & Want /*SEGURAMENTE & ~Grant_SA_FromW*/)) & ~buf_free;
    // wire pre_Request_SA_L = /*~Grant_SA_FromL &*/ (Grant_VA_FromL | (VC_assigned_L & Lant /*SEGURAMENTE & ~Grant_SA_FromL*/)) & ~buf_free;

    // wire pre_Request_SA_S = (Grant_VA_FromS | (VC_assigned_S & Sant)) & (~Grant_SA_FromS | (Req & (VC_assigned_S & Sant))) & ~buf_free;
    // wire pre_Request_SA_E = (Grant_VA_FromE | (VC_assigned_E & Eant)) & (~Grant_SA_FromE | (Req & (VC_assigned_E & Eant))) & ~buf_free;
    // wire pre_Request_SA_W = (Grant_VA_FromW | (VC_assigned_W & Want)) & (~Grant_SA_FromW | (Req & (VC_assigned_W & Want))) & ~buf_free;
    // wire pre_Request_SA_L = (Grant_VA_FromL | (VC_assigned_L & Lant)) & (~Grant_SA_FromL | (Req & (VC_assigned_L & Lant))) & ~buf_free;

    wire forward_buf_free = (~Req & granted) | buf_free;

    wire pre_Request_SA_N = ((Grant_VA_FromN | VC_assigned_N) & (Req | (~forward_buf_free & ~buf_free))) | (~forward_buf_free & Grant_VA_FromN);
    wire pre_Request_SA_S = ((Grant_VA_FromS | VC_assigned_S) & (Req | (~forward_buf_free & ~buf_free))) | (~forward_buf_free & Grant_VA_FromS);
    wire pre_Request_SA_E = ((Grant_VA_FromE | VC_assigned_E) & (Req | (~forward_buf_free & ~buf_free))) | (~forward_buf_free & Grant_VA_FromE);
    wire pre_Request_SA_W = ((Grant_VA_FromW | VC_assigned_W) & (Req | (~forward_buf_free & ~buf_free))) | (~forward_buf_free & Grant_VA_FromW);
    wire pre_Request_SA_L = ((Grant_VA_FromL | VC_assigned_L) & (Req | (~forward_buf_free & ~buf_free))) | (~forward_buf_free & Grant_VA_FromL);

    assign Request_SA_N = pre_Request_SA_N & (~TailFlit_granted);
    assign Request_SA_S = pre_Request_SA_S & (~TailFlit_granted);
    assign Request_SA_E = pre_Request_SA_E & (~TailFlit_granted);
    assign Request_SA_W = pre_Request_SA_W & (~TailFlit_granted);
    assign Request_SA_L = pre_Request_SA_L & (~TailFlit_granted);






    //tail flit to SA
    assign TailFlit = (ftype_buf == `tail) | (ftype_buf == `header_tail);

    //output broadcast signals
    assign BroadcastFlitN =  buf_bc_n;
    assign BroadcastFlitE =  buf_bc_e;
    assign BroadcastFlitW =  buf_bc_w;
    assign BroadcastFlitS =  buf_bc_s;
    assign BroadcastFlitL =  buf_bc_l;

    assign FlitOut     =  flit_buf;
    assign FlitTypeOut =  ftype_buf;

always @ (posedge clk)
    if (rst_p) begin
        Nant     <= 1'b0;
        Eant     <= 1'b0;
        Want     <= 1'b0;
        Sant     <= 1'b0;
        Lant     <= 1'b0;

        buf_free <= 1'b1;

        buf_bc_n <= 1'b0;
        buf_bc_s <= 1'b0;
        buf_bc_e <= 1'b0;
        buf_bc_w <= 1'b0;
        buf_bc_l <= 1'b0;

        VC_req_N <= 1'b0;
        VC_req_E <= 1'b0;
        VC_req_W <= 1'b0;
        VC_req_S <= 1'b0;
        VC_req_L <= 1'b0;

        VC_assigned_N <= 1'b0;
        VC_assigned_E <= 1'b0;
        VC_assigned_W <= 1'b0;
        VC_assigned_S <= 1'b0;
        VC_assigned_L <= 1'b0;

        flit_buf    <= `V_ZERO(FLIT_SIZE);
        ftype_buf   <= `V_ZERO(FLIT_TYPE_SIZE);

    end else begin

        VC_req_N <= Request_VA_N & ~Grant_VA_FromN;
        VC_req_E <= Request_VA_E & ~Grant_VA_FromE;
        VC_req_W <= Request_VA_W & ~Grant_VA_FromW;
        VC_req_S <= Request_VA_S & ~Grant_VA_FromS;
        VC_req_L <= Request_VA_L & ~Grant_VA_FromL;

        if (Req) begin
            flit_buf  <= Flit;
            ftype_buf <= FlitType;

            buf_bc_n <= bc_n;
            buf_bc_s <= bc_s;
            buf_bc_e <= bc_e;
            buf_bc_w <= bc_w;
            buf_bc_l <= bc_l;

            buf_free  <= 1'b0;

        end else begin
            if (~buf_free & granted) begin
                buf_free <= 1'b1;
            end
            if (VC_assigned | Grant_VA)begin
                if (Grant_VA_FromN) VC_req_N <= 1'b0;
                if (Grant_VA_FromE) VC_req_E <= 1'b0;
                if (Grant_VA_FromW) VC_req_W <= 1'b0;
                if (Grant_VA_FromS) VC_req_S <= 1'b0;
                if (Grant_VA_FromL) VC_req_L <= 1'b0;            //<<<<<<<<<<<<<<<<<<<<*/

                 VC_assigned_N <= (Grant_VA_FromN | Nant) /*& ~granted*/;//HABR?? QUE COMENTAR ~GRANTED SEGURAMENTE
                 VC_assigned_E <= (Grant_VA_FromE | Eant) /*& ~granted*/;
                 VC_assigned_W <= (Grant_VA_FromW | Want) /*& ~granted*/;
                 VC_assigned_S <= (Grant_VA_FromS | Sant) /*& ~granted*/;
                 VC_assigned_L <= (Grant_VA_FromL | Lant) /*& ~granted*/;

                 Nant <= (Grant_VA_FromN | VC_assigned_N) /*& ~granted*/;//HABR?? QUE COMENTAR ~GRANTED SEGURAMENTE
                 Eant <= (Grant_VA_FromE | VC_assigned_E) /*& ~granted*/;
                 Want <= (Grant_VA_FromW | VC_assigned_W) /*& ~granted*/;
                 Sant <= (Grant_VA_FromS | VC_assigned_S) /*& ~granted*/;
                 Lant <= (Grant_VA_FromL | VC_assigned_L) /*& ~granted*/;                         //<<<<<<<<<<<<<<<<<<<<

                                 //<<<<<<<<<<<<<<<<<<<<
            end
        end//else Req

        if ( Grant_SA_FromN & TailFlit) begin Nant <= 1'b0; VC_assigned_N <= 1'b0; end
        if ( Grant_SA_FromS & TailFlit) begin Sant <= 1'b0; VC_assigned_S <= 1'b0; end
        if ( Grant_SA_FromE & TailFlit) begin Eant <= 1'b0; VC_assigned_E <= 1'b0; end
        if ( Grant_SA_FromW & TailFlit) begin Want <= 1'b0; VC_assigned_W <= 1'b0; end
        if ( Grant_SA_FromL & TailFlit) begin Lant <= 1'b0; VC_assigned_L <= 1'b0; end

    end//else rst_p
endmodule
