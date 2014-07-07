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
module telemetry_generator(
		input clk_i,
		input rst_i,
		input bitce_i,
		input bittogce_i,
		input wordce_i,
		input syncce_i,
		input start_i,
		output done_o,
		output [10:0] addr_o,
		input [31:0] dat_i,
		output SDAT,
		output SCLK,
		output BIPHASE
    );
	localparam [15:0] SYNC_WORD = 16'hEB90;
	localparam [15:0] IDLE_WORD = 16'hB3A5;
	localparam [15:0] END_WORD_1 = 16'hC0FE;
	localparam [15:0] END_WORD_2 = 16'hD0CC;
	
	(* IOB = "TRUE" *)
	reg sdat_reg = 0;
	(* IOB = "TRUE" *)
	reg sclk_reg = 0;
	(* IOB = "TRUE" *)
	reg biphase_reg = 0;

	reg [15:0] next_serial_data = IDLE_WORD;
	reg [15:0] shift_register = IDLE_WORD;
	reg sclk = 0;
	
	reg [11:0] addr_reg = {12{1'b0}};
	wire [12:0] addr_reg_next = addr_reg + 1;
	reg seen_c0fe = 0;
	reg last_word = 0;
	reg last_word_finishing = 0;
	reg buffer_done = 0;
	reg sending_buffer = 0;
	reg start_seen = 0;
	
	wire end_write = (seen_c0fe && (next_serial_data == END_WORD_2)) || addr_reg_next[12];
	
	always @(posedge clk_i) begin
		if (rst_i) start_seen <= 0;
		else if (start_i) start_seen <= 1;
		else if (sending_buffer) start_seen <= 0;
		
		if (rst_i) addr_reg <= {12{1'b0}};
		else if (sending_buffer && wordce_i && !syncce_i) addr_reg <= addr_reg_next[11:0];
		else addr_reg <= {12{1'b0}};
		
		if (rst_i) seen_c0fe <= 0;
		else if (sending_buffer && (next_serial_data == END_WORD_1)) seen_c0fe <= 1;
		else if (!sending_buffer) seen_c0fe <= 0;
		
		// sending_buffer goes low before D0CC is loaded onto the outgoing shift register.
		// So sending_buffer_done needs 2 more wordce's before it's good.
		if (rst_i) sending_buffer <= 0;
		else if (sending_buffer && end_write) sending_buffer <= 0;
		else if (start_seen && wordce_i) sending_buffer <= 1;
		
		if (rst_i) last_word <= 0;
		else if (sending_buffer && end_write) last_word <= 1;
		else if (wordce_i) last_word <= 0;
		
		if (rst_i) last_word_finishing <= 0;
		else if (wordce_i) last_word_finishing <= last_word;
		
		if (rst_i) buffer_done <= 0;
		else if (wordce_i && last_word_finishing) buffer_done <= 1;
		else buffer_done <= 0;
		
		if (rst_i) next_serial_data <= IDLE_WORD;
		else if (syncce_i) next_serial_data <= SYNC_WORD;
		else if (sending_buffer && wordce_i && !addr_reg[0]) next_serial_data <= dat_i[15:0];
		else if (sending_buffer && wordce_i && addr_reg[0]) next_serial_data <= dat_i[31:16];
		else if (wordce_i) next_serial_data <= IDLE_WORD;
		
		if (rst_i) shift_register <= IDLE_WORD;
		else if (wordce_i) shift_register <= next_serial_data;
		else if (bitce_i) shift_register <= {shift_register[14:0],1'b0};
		
		if (rst_i) sclk <= 0;
		else if (bitce_i || bittogce_i) sclk <= ~sclk;

		sclk_reg <= sclk;
		sdat_reg <= shift_register[15];
		biphase_reg <= sclk ^ shift_register[15];
	end
	
	assign SCLK = sclk_reg;
	assign SDAT = sdat_reg;
	assign BIPHASE = biphase_reg;
	assign addr_o = addr_reg[11:1];
	assign done_o = buffer_done;
endmodule
