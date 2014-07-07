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
module telem_clock_v2(
		input clk_i,
		output bitce_o,
		output bittogce_o,
		output wordce_o,
		output syncce_o
    );
	reg bitce = 0;
	reg bittogce = 0;
	reg wordce = 0;
	reg syncce = 0;
	// This gets correctly inferred into two SRL16s.
	reg [33:0] bit_shift_reg = 34'h0001;
	// This gets correctly inferred into a single SRL16.
	reg [15:0] word_shift_reg = 16'h0001;
	// Ditto.
	reg [15:0] sync_shift_reg_1 = 16'h0001;
	// Ditto ditto.
	reg [7:0] sync_shift_reg_2 = 8'h01;
	always @(posedge clk_i) begin
		bit_shift_reg <= {bit_shift_reg[32:0],bit_shift_reg[33]};
		
		bittogce <= bit_shift_reg[16];
		bitce <= bit_shift_reg[33];

		if (bit_shift_reg[33]) word_shift_reg <= {word_shift_reg[14:0],word_shift_reg[15]};
		if (word_shift_reg[15] && bit_shift_reg[33]) sync_shift_reg_1 <= {sync_shift_reg_1[14:0],sync_shift_reg_1[15]};
		if (sync_shift_reg_1[15] && word_shift_reg[15] && bit_shift_reg[33]) sync_shift_reg_2 <= {sync_shift_reg_2[6:0],sync_shift_reg_2[7]};

		wordce <= word_shift_reg[15] && bit_shift_reg[33];
		syncce <= sync_shift_reg_2[7] && sync_shift_reg_1[15] && word_shift_reg[15] && bit_shift_reg[33];
	end
			
	assign bitce_o = bitce;
	assign bittogce_o = bittogce;
	assign wordce_o = wordce;
	assign syncce_o = syncce;
endmodule
