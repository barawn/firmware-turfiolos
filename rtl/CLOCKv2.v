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

// Clock monitoring/reset module.
module CLOCKv2(
		input clk_i,
		input wr_i,
		input [31:0] dat_i,
		output [31:0] dat_o,
		input [7:0] tstatus_i,
		input tlock_i,
		output treset_o,
		output reset_o,
		output sel_o,
		output FPROG
    );

	reg clock_sel = 0;
	reg reset_reg = 0;
	reg fprog_reg = 0;
	wire reset_fprog;
	reg [3:0] counter = {4{1'b0}};
	wire [4:0] counter_plus_one = counter + 1;
	assign reset_fprog = counter_plus_one[4];
	
	always @(posedge clk_i) begin
		if (reset_o) clock_sel <= 0;
		else if (wr_i) clock_sel <= dat_i[0];
		
		if (wr_i) reset_reg <= dat_i[1];
		else reset_reg <= 0;

		if (reset_o || reset_fprog) fprog_reg <= 0;
		else if (wr_i) fprog_reg <= dat_i[1];
	
		if (!fprog_reg) counter <= {4{1'b0}};
		else if (fprog_reg) counter <= counter_plus_one;
	end
	
	// This module is basically deprecated, other than the reset output and FPROG output.
	// We don't need a TURF clock shifter anymore.
	assign FPROG = fprog_reg;
	assign sel_o = clock_sel;
	assign reset_o = reset_reg;
	assign dat_o = {{29{1'b0}},fprog_reg, reset_reg, clock_sel};

endmodule
