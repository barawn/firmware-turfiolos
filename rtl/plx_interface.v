////////////////////////////////////////////////////////////////////////////////
// This file is a part of the Antarctic Impulsive Transient Antenna (ANITA)
// project, a collaborative scientific effort between multiple institutions. For
// more information, contact Peter Gorham (gorham@phys.hawaii.edu).
//
// All rights reserved.
//
// Author: Patrick Allison, Ohio State University (allison.122@osu.edu)
// Author:
// Author:
////////////////////////////////////////////////////////////////////////////////
module plx_interface(input nADS,
		     input 	   WnR,
		     input 	   nBLAST,
		     input 	   nCS2,
		     input 	   nCS3,
		     input [12:2]  LA,
		     inout [31:0]  LD,
		     output 	   nREADY,
		     output 	   nBTERM,
		     
		     input 	   clk_i,
			  output [10:0] mem_burst_addr_o,
			  output			mem_burst_addr_wr_o,
		     output 	   mem_wr_o,
		     output [31:0] mem_dat_o,
		     input [31:0]  mem_dat_i,

		     output 	   tio_wr_o,
		     output [5:0]  tio_addr_o,
		     output [31:0] tio_dat_o,
		     input [31:0]  tio_dat_i,

		     output 	   turf_wr_o,
		     output 	   turf_rd_o,
		     output [5:0]  turf_addr_o,
		     output [31:0] turf_dat_o,
		     input [31:0]  turf_dat_i,
		     input 	   turf_ack_i,
			  output [35:0] debug_o
		     );
   // This is a bit of a custom state, to generate the outputs for READY
   // automatically.
   localparam FSM_BITS = 4;
   localparam [FSM_BITS-1:0] IDLE =     0; 
   localparam [FSM_BITS-1:0] MEMADRWR = 1;
   localparam [FSM_BITS-1:0] MEMDATWR = 2;
   localparam [FSM_BITS-1:0] MEMADRRD = 3; 
   localparam [FSM_BITS-1:0] TIOADRWR = 4; 
   localparam [FSM_BITS-1:0] TIOADRRD = 5; 
   localparam [FSM_BITS-1:0] TFADRWR = 6;   
   localparam [FSM_BITS-1:0] TFDATWR = 7;
   localparam [FSM_BITS-1:0] TFADRRD = 8; 
   localparam [FSM_BITS-1:0] TFDATRD = 9; 
   reg [FSM_BITS-1:0] 		   state = IDLE;

   (* IOB = "TRUE" *)
   reg 				   nads_q = 1;
   (* IOB = "TRUE" *)
   reg 				   wnr_q = 1;
   (* IOB = "TRUE" *)
   reg 				   ncs2_q = 1;
   (* IOB = "TRUE" *)
   reg 				   ncs3_q = 1;
   (* IOB = "TRUE" *)
   reg 				   nblast_q = 1;
   (* IOB = "TRUE" *)
   reg 				   nready_q = 1;   
   (* IOB = "TRUE" *)
   reg [31:0] 			   data_register = {32{1'b0}};
   (* IOB = "TRUE" *)
   reg [10:0] 			   address_register = {11{1'b0}};
   (* IOB = "TRUE" *)
   reg 				   nbterm_q = 0;
   
   // Only the LOS writes can burst.
   wire 			   writing_state = (state == MEMDATWR);

   // The first term is for TURFIO writes and LOS writes.
   // The next terms are to continue asserting READY on LOS burst writes.
   // The next term is to assert READY at the ADR state on TURFIO/LOS reads.
   // The last term is to assert READY for the TURFIO, which is qualified on the ack coming in.
   wire 			   ready = (!nads_q && (state == IDLE) && ncs2_q) || 
				           (((state == MEMADRWR) || (state == MEMDATWR)) && (nBLAST && nblast_q)) ||
				           (state == TFDATRD && turf_ack_i) || (state == TFDATWR && turf_ack_i);
   // Terminate all bursts unless we're writing to CS3.
   wire 			   bterm = ready && (!wnr_q || ncs3_q);
   

   (* IOB = "TRUE" *)
   reg [31:0] 			   data_out_register = {32{1'b0}};
   (* IOB = "TRUE" *)
   reg [31:0] 			   data_out_oe_q = {32{1'b1}};
	wire data_out_oe;
   wire [31:0] 			   data_in;
   
   wire [1:0] 			   mux_sel = {!ncs3_q, !ncs2_q};   
   wire [31:0] 			   data_out_mux[3:0];
   assign data_out_mux[0] = tio_dat_i;
   assign data_out_mux[1] = turf_dat_i;
   assign data_out_mux[2] = mem_dat_i;
   assign data_out_mux[3] = turf_dat_i; // This never happens. It's just here to simplify the decode.   
	
   assign data_out_oe = (state == IDLE && !nads_q && !wnr_q) || 
								(state == MEMADRRD) || (state == TIOADRRD) || 
								(state == TFADRRD) || (state == TFDATRD);      
      
   
   always @(posedge clk_i) begin : IOB_LOGIC
      nads_q <= nADS;
      nblast_q <= nBLAST;
      ncs2_q <= nCS2;
      ncs3_q <= nCS3;
      wnr_q <= WnR;

      if (!nads_q || writing_state) data_register <= data_in;
      if (!nads_q) address_register <= LA;

      nbterm_q <= !bterm; 
      nready_q <= !ready;
      data_out_register <= data_out_mux[mux_sel];

      // For reads there's an extra wait state.
      data_out_oe_q <= {32{!data_out_oe}};
		
   end // IOB_LOGIC

   always @(posedge clk_i) begin : SM_LOGIC
      case (state)
	IDLE: if (!nads_q) begin
	   if (!ncs3_q) begin
	      if (wnr_q) state <= MEMADRWR;
	      else state <= MEMADRRD;
	   end else if (!ncs2_q) begin
	      if (wnr_q) state <= TFADRWR;
	      else state <= TFADRRD;
	   end else begin
	      if (wnr_q) state <= TIOADRWR;
	      else state <= TIOADRRD;
	   end
	end
	MEMADRRD: state <= IDLE;
	MEMADRWR: state <= MEMDATWR;
	MEMDATWR: if (!nblast_q) state <= IDLE;
							      
	TIOADRRD: state <= IDLE;
	TIOADRWR: state <= IDLE;
	TFADRWR: state <= TFDATWR;
	TFADRRD: state <= TFDATRD;
	TFDATRD: if (turf_ack_i) state <= IDLE;
	TFDATWR: if (turf_ack_i) state <= IDLE;	
      endcase // case (state)
   end // SM_LOGIC

   // Memory outputs. 
   // 0x000-0x3FF dump straight into the FIFO.
   // 0x400-0x7FF write to the control register.
	assign mem_burst_addr_o = address_register;	
	assign mem_burst_addr_wr_o = !nads_q;
   assign mem_dat_o = data_register;
   assign mem_wr_o = (state == MEMDATWR);
   // TURFIO outputs
   assign tio_addr_o = address_register[5:0];
   assign tio_dat_o = data_register;
   assign tio_wr_o = (state == TIOADRWR);
   // TURF outputs
   assign turf_addr_o = address_register[5:0];
   assign turf_dat_o = data_register;
   assign turf_wr_o = (state == TFADRWR);
   assign turf_rd_o = (state == TFADRRD);
      
   generate
      genvar i;
      for (i=0;i<32;i=i+1) begin : IOBDATA
	 IOBUF u_iob(.I(data_out_register[i]),.O(data_in[i]),.T(data_out_oe_q[i]),.IO(LD[i]));
      end
   endgenerate
   assign nBTERM = nbterm_q;   
   assign nREADY = nready_q;
   
   assign debug_o[0] = nads_q;
	assign debug_o[1] = ncs2_q;
	assign debug_o[2] = ncs3_q;
	assign debug_o[3] = wnr_q;
	assign debug_o[4 +: 6] = address_register[5:0];
	assign debug_o[10 +: 16] = data_register[15:0];
	assign debug_o[26 +: 4] = state;
	assign debug_o[30] = nblast_q;
	assign debug_o[31] = ready;
	assign debug_o[32] = !bterm;
	assign debug_o[33] = data_out_oe;
	assign debug_o[34] = mem_wr_o;
	assign debug_o[35] = tio_wr_o;
endmodule // plx_interface

      
      
      
      
      
   
   
   
   
   
