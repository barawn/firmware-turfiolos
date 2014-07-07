`timescale 1ns / 1ps
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

module TURF_interface_v2(
		input clk_i,
		input wr_i,
		input rd_i,
		input [5:0] addr_i,
		input [1:0] bank_i,
		input [31:0] dat_i,
		output [31:0] dat_o,
		output ack_o,
		
		inout [7:0] TURF_DIO,
		output TURF_WnR,
		output nCSTURF
    );

	// The TURF interface is relatively straightforward.
	// Assert CS_TURF and place the address {bank_i,addr_i} on the bus.
	// Next cycle is byte 0
	// Next cycle is byte 1
	// Next cycle is byte 2
	// Next cycle is byte 3
	
	// Unlike the old TURFIO firmware, because of the forwarded clock and the IOB-pushed registers, no
	// TURF clock phase shifting should be necessary.
	
	// The TURF does have one tight constraint, in that it will need to fall through 2 16-to-1 muxes
	// in 15 ns, but that shouldn't be a problem.
	//
	// We may push this interface up to 60 MHz at some point, which should be doable.
	
	(* IOB = "TRUE" *)
	reg csturf_q = 0;
	(* IOB = "TRUE" *)
	reg turf_wnr_q = 0;
	
	(* IOB = "TRUE" *)
	reg [7:0] dat_o_turf = {8{1'b0}};
	(* IOB = "TRUE" *)
	reg [7:0] dat_i_turf_q = {8{1'b0}};
	(* IOB = "TRUE" *)
	reg [7:0] dat_oe_turf_q = {8{1'b0}};
	
	reg [7:0] dio_mux;
	reg [23:0] data_in_store = {24{1'b0}};
	wire dat_oe;
	wire transaction_done;
	reg write_done = 0;

	localparam FSM_BITS = 4;
	localparam [FSM_BITS-1:0] IDLE  			= 0;
	localparam [FSM_BITS-1:0] T_SEL_ADDR 	= 1; // CSTURF is asserted, address on bus. If write, prep data 0. Reads tristate.
	localparam [FSM_BITS-1:0] T_WAIT_WR0	= 2; // Wait. If a read, this is a turnaround cycle. If write, prep data 1.
	localparam [FSM_BITS-1:0] T_WR1			= 3; // Prep byte 2 to go out.
	localparam [FSM_BITS-1:0] T_WR2			= 4; // Prep byte 3 to go out. Assert ack (since we're done).
	localparam [FSM_BITS-1:0] T_WR3			= 5; // Byte 3 is on the bus. This is here to stay safe.
	localparam [FSM_BITS-1:0] T_RD0			= 6; // Byte 0 is on dio_turf_q.
	localparam [FSM_BITS-1:0] T_RD1			= 7; // Byte 1 is on dio_turf_q.
	localparam [FSM_BITS-1:0] T_RD2			= 8; // Byte 2 is on dio_turf_q. Assert transaction done (kill csturf on next).
	localparam [FSM_BITS-1:0] T_RD3			= 9; // Byte 3 is on dio_turf_q. Assert ack. 
	reg [FSM_BITS-1:0] state = IDLE;
	
	always @(posedge clk_i) begin
		csturf_q <= !((rd_i || wr_i) && !(transaction_done));
		turf_wnr_q <= !rd_i || transaction_done;
	end

	always @(*) begin
		case (state)
			T_SEL_ADDR: dio_mux <= dat_i[7:0];
			T_WAIT_WR0: dio_mux <= dat_i[15:8];
			T_WR1:		dio_mux <= dat_i[23:16];
			T_WR2:		dio_mux <= dat_i[31:24];
			default:		dio_mux <= {bank_i,addr_i};
		endcase
	end
	
	always @(posedge clk_i) begin
		case (state)
			IDLE: if (rd_i || wr_i) state <= T_SEL_ADDR;
			T_SEL_ADDR: state <= T_WAIT_WR0;
			T_WAIT_WR0: if (rd_i) state <= T_RD0; else state <= T_WR1;
			T_WR1: state <= T_WR2;
			T_WR2: state <= T_WR3;
			T_WR3: state <= IDLE;
			T_RD0: state <= T_RD1;
			T_RD1: state <= T_RD2;
			T_RD2: state <= T_RD3;
			T_RD3: state <= IDLE;
		endcase

		if (state == T_RD0) data_in_store[7:0] 	<= dat_i_turf_q;
		if (state == T_RD1) data_in_store[15:8] 	<= dat_i_turf_q;
		if (state == T_RD2) data_in_store[23:16]	<= dat_i_turf_q;

		dat_i_turf_q <= TURF_DIO;
		dat_o_turf <= dio_mux;

		dat_oe_turf_q <= {8{!dat_oe}};
		
	end
	
	assign dat_oe = !rd_i || (state == IDLE);
	assign ack_o = (state == T_WR2) || (state == T_RD3);
	assign transaction_done = (state == T_RD2) || (state == T_RD3) || (state == T_WR3);
	assign dat_o = {dat_i_turf_q,data_in_store};

	assign nCSTURF 		= csturf_q;
	assign TURF_WnR 		= turf_wnr_q;

	generate
		genvar i;
		for (i=0;i<8;i=i+1) begin : LP
			assign TURF_DIO[i] = (dat_oe_turf_q[i]) ? 1'bZ : dat_o_turf[i];
		end
	endgenerate
endmodule
