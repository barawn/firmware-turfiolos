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

// Photoshutter control module.
module PHOTOv2(
		input clk_i,
		input wr_i,
		input [31:0] dat_i,
		output [31:0] dat_o,
		input rst_i,
		input TRIG,
		output P1,
		output P2,
		output P3,
		output TRIG_OUT
    );
	
	// For now just copy the PINGPONG module.
	PINGPONG u_pingpong(.CLK(clk_i),.ENABLE(wr_i),.DIN(dat_i),.DO(dat_o),
							  .P1(P1),.P2(P2),.P3(P3),.TRIG(TRIG),.RESET(rst_i));
	assign TRIG_OUT = TRIG;
endmodule
