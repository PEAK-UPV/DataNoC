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
// Create Date: 09/03/2013
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
`include "network/net_common.h"

module ROUTING_NI#(
parameter ID                 = 0,
parameter FLIT_SIZE          = 64,
parameter FLIT_TYPE_SIZE     = 2,
parameter BROADCAST_SIZE     = 5,
parameter PHIT_SIZE          = 64,
parameter NUM_VC             = 1,                 // Number of Virtual Channels supported for each Virtual Network
parameter NUM_VN             = 3                  // Number of Virtual Networks supported

)(
  input clk,
  input rst_p,    
  input Req,                                    //routing request
  input [FLIT_SIZE-1:0] Flit,                   //flit input        
  input [FLIT_TYPE_SIZE-1:0] FlitType,          //flit type input (flit type is not coded in the flit structure)
  input BroadcastFlit,	                        //is input flit broadcast?	    
  input [NUM_VC-1:0] Grant_VA_FromL,
  input [NUM_VC-1:0] Grant_SA_FromL,
  output [FLIT_SIZE-1:0] FlitOut,               //flit output from the module
  output [FLIT_TYPE_SIZE-1:0] FlitTypeOut,      //flit type output
  output BroadcastFlitL,		        
  output [NUM_VC-1:0] Request_VA_L,
  output [NUM_VC-1:0] Request_SA_L,
  output Avail                                 //routing engine ready for receiving requests
);
            	                                    
	//they store the output ports requested by a header flit for the rest of the flits of the packet
    reg [NUM_VC-1:0] Lant;
    //they store if VC of each port needs more requests
    reg VC_req_L;
    //they store if there is VC assigned for each port
    reg [NUM_VC-1:0] VC_assigned_L;
    //there is any grant form VA module?
    //wire [NUM_VC-1:0] VC_assigned = Grant_VA_FromL |  VC_assigned_L;

    reg buf_bc_l;
    reg [FLIT_SIZE-1      : 0] flit_buf;
    reg [FLIT_TYPE_SIZE-1 : 0] ftype_buf;
    reg buf_free;

     /*When a header flit arrives, it requests VA for a channel. Once it has a grant, for each flit in each packet if makes a request for output port to VA.
     Only when it flit achieves two grants (each from VA and SA) it is granted to leave ROUTING module
	*/
    wire granted = (|Grant_SA_FromL);
    //let's get info for routing output computation
    wire bc_l  = Req ? BroadcastFlit :  1'b0;    
    
    //available to ibuffer
    //assign next = granted & (GrantFromN | GrantFromS | GrantFromE | GrantFromW | GrantFromL) ; 
    assign Avail = ((granted) | buf_free);

    wire TailFlit = (ftype_buf == `tail) | (ftype_buf == `header_tail);
    wire TailFlit_granted = (ftype_buf==`tail | ftype_buf==`header_tail) & Grant_SA_FromL[`WIDTH(VC_assigned_L)];

    //output request to va signals
    /*wire Virtual_buf_free = ~(Req | ~buf_free);
    wire incoming_TailFlit = Req ? (FlitType==`header | FlitType==`header_tail) : 1'b0;			
    wire Request_VA = (~Virtual_buf_free & ~VC_assigned) & (incoming_TailFlit | (ftype_buf==`header | ftype_buf==`header_tail));
    */
    //wire Request_VA = (~buf_free) & (ftype_buf==`header | ftype_buf==`header_tail);
    wire Request_VA = (Req) & (FlitType==`header | FlitType==`header_tail);
    assign Request_VA_L = ((Request_VA | VC_req_L) & ~(|Grant_VA_FromL)) ? {NUM_VC{1'b1}} : {NUM_VC{1'b0}};

    //output request to sa signals (Frist of all we need a Grant from VA)
    //assign Request_SA_L = /*~Grant_SA_FromL*/(~granted | (VC_assigned_L & Lant & ~flit_in_header)) & (Grant_VA_FromL | VC_assigned_L | Lant) & ~buf_free;


    //wire [NUM_VC-1:0] pre_Request_SA_L = ((~buf_free) ? {NUM_VC{1'b1}} : {NUM_VC{1'b0}}) & (Grant_VA_FromL | (VC_assigned_L & Lant /*& ~Grant_SA_FromL*/)) /*& ~buf_free*/;//  (~granted | (VC_assigned_L & Lant & ~flit_in_header)) & (VC_assigned_L & Lant) & ~buf_free;
    wire forward_buf_free = (~Req & granted) | buf_free;

    wire [NUM_VC-1:0] pre_Request_SA_L = ((Grant_VA_FromL | VC_assigned_L) &
                                         (((Req)?{NUM_VC{1'b1}}:{NUM_VC{1'b0}}) | (((~buf_free)?{NUM_VC{1'b1}}:{NUM_VC{1'b0}}) & ~Grant_SA_FromL)))|
                                         (((~forward_buf_free) ? {NUM_VC{1'b1}} : {NUM_VC{1'b0}}) & (Grant_VA_FromL));

    assign Request_SA_L = ((~TailFlit_granted)?{NUM_VC{1'b1}}:{NUM_VC{1'b0}}) & pre_Request_SA_L;
    //assign Request_SA_L = ((~granted & (Grant_VA_FromL | VC_assigned_L | Lant)) | (VC_assigned_L & Lant)) & /*(Grant_VA_FromL | VC_assigned_L | Lant) &*/ (~buf_free);

    //output broadcast signals  
    assign BroadcastFlitL =  buf_bc_l;
    assign FlitOut     =  flit_buf;
    assign FlitTypeOut =  ftype_buf;
    
always @ (posedge clk)
    if (rst_p) begin
        Lant     <= `V_ZERO(NUM_VC);
        buf_free <= 1'b1;
        buf_bc_l <= 1'b0;
        VC_req_L <= 1'b0;
        VC_assigned_L <= `V_ZERO(NUM_VC);
        flit_buf    <= `V_ZERO(FLIT_SIZE);   
        ftype_buf   <= `V_ZERO(FLIT_TYPE_SIZE);
    end else begin
        VC_req_L <= (|Request_VA_L) & ~(|Grant_VA_FromL);
        if (Req) begin
            flit_buf  <= Flit;
            ftype_buf <= FlitType;         
            buf_bc_l <= bc_l;
            buf_free  <= 1'b0;
        end else begin
            if (~buf_free & (granted)) begin
                buf_free <= 1'b1;
            end
            if ((|VC_assigned_L) | (|Grant_VA_FromL))begin
                if (|Grant_VA_FromL & ~(ftype_buf == `tail)) begin
                    VC_req_L <= `V_ZERO(NUM_VC);
                    VC_assigned_L[`WIDTH(Grant_VA_FromL)] <= (Grant_VA_FromL[`WIDTH(Grant_VA_FromL)]) & ~granted;
                    Lant[`WIDTH(Grant_VA_FromL)] <= (Grant_VA_FromL[`WIDTH(Grant_VA_FromL)]) & ~granted; 
                end else if(|Lant & ~(ftype_buf == `tail))begin
                    VC_assigned_L[`WIDTH(Lant)] <= (Lant[`WIDTH(Lant)]) /*& ~granted*/;
                    Lant[`WIDTH(Lant)] <= (Lant[`WIDTH(Lant)]) /*& ~granted*/;
                end else if(|Grant_SA_FromL & (ftype_buf == `tail))begin 
                	Lant[`WIDTH(Grant_SA_FromL)] <= 1'b0; VC_assigned_L[`WIDTH(Grant_SA_FromL)] <= 1'b0;
                end                                  
            end
        end//else Req  
        if ((|Grant_SA_FromL) & TailFlit) begin Lant <= `V_ZERO(NUM_VC); VC_assigned_L <= `V_ZERO(NUM_VC); end         
    end//else rst_p
endmodule
