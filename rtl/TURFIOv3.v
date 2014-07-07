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
module TURFIOv3(
		input clk_i,
		input wr_i,
		input [5:0] addr_i,
		input [31:0] dat_i,
		output [31:0] dat_o,
		
		output losctrl_wr_o,
		output [31:0] losctrl_dat_o,
		input [31:0] losctrl_dat_i,

		output pps_wr_o,
		output [31:0] pps_dat_o,
		input [31:0] pps_dat_i,
		
		output photo_wr_o,
		output [31:0] photo_dat_o,
		input [31:0] photo_dat_i,
		
		output clock_wr_o,
		output [31:0] clock_dat_o,
		input [31:0] clock_dat_i,

		output [1:0] turf_bank_o
    );

	parameter [31:0] ID = "TFIO";
	parameter [31:0] VERSION = 32'h00000000;
	
	// 6 bits is 64 total registers. We use 16.
	wire [31:0] turfio_registers[15:0];
	
	// 2 are the ID/version registers.
	wire [31:0] turfio_id_registers[1:0];
	// 1 is the photo register.
	wire [31:0] photo_register = photo_dat_i;
	
	// 1 is the PPS register.
	wire [31:0] pps_register = pps_dat_i;
	
	// 1 is the TURF bank register.
	reg [1:0] turfbank = {2{1'b0}};
	wire [31:0] turfbank_register;
	assign turfbank_register = {{30{1'b0}},turfbank};
	
	// 1 is the clock register
	wire [31:0] clock_register = clock_dat_i;
	
	// 1 is the DPS register.
	wire [31:0] dps_register;
	assign dps_register = {32{1'b0}};
	
	always @(posedge clk_i) begin
		if (wr_i && (addr_i[2:0] == 3'h6)) turfbank <= dat_i[1:0];
	end
	
	assign turfio_registers[0] = turfio_id_registers[0];
	assign turfio_registers[1] = turfio_id_registers[1];
	assign turfio_registers[2] = turfio_registers[0];		// reserve
	assign turfio_registers[3] = turfio_registers[1];		// reserve
	assign turfio_registers[4] = photo_register;
	assign turfio_registers[5] = pps_register;
	assign turfio_registers[6] = turfbank_register;
	assign turfio_registers[7] = clock_register;
	assign turfio_registers[8] = dps_register;
	assign turfio_registers[9] = losctrl_dat_i;
	assign turfio_registers[10] = turfio_registers[2]; 	// reserve 1010
	assign turfio_registers[11] = turfio_registers[3];		// reserve 1011
	assign turfio_registers[12] = turfio_registers[4];		// reserve 1100
	assign turfio_registers[13] = turfio_registers[5];		// reserve
	assign turfio_registers[14] = turfio_registers[6];		// reserve
	assign turfio_registers[15] = turfio_registers[7];		// reserve
	assign dat_o = turfio_registers[addr_i[3:0]];

	assign turfio_id_registers[0] = ID;
	assign turfio_id_registers[1] = VERSION;
	
	assign losctrl_dat_o = dat_i;
	assign losctrl_wr_o = (wr_i && (addr_i[3:0] == 4'h9)); // 1001

	assign pps_dat_o = dat_i;
	assign pps_wr_o = (wr_i && (addr_i[2:0] == 3'h5));     // x101
	
	assign photo_dat_o = dat_i;
	assign photo_wr_o = (wr_i && (addr_i[2:0] == 3'h4));	 // x100
	
	assign clock_dat_o = dat_i;
	assign clock_wr_o = (wr_i && (addr_i[2:0] == 3'h7));   // x111
	
	assign turf_bank_o = turfbank;
endmodule
