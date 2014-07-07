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

// PPS control module
module PPSv2(
		input clk_i,
		input wr_i,
		input [31:0] dat_i,
		output [31:0] dat_o,
		input rst_i,
		output pps_o,
		output pps_burst_o,
		input PPS_ADU5A,
		input PPS_ADU5B,
		input PPS_G12
    );

	// Stupid internal PPS.
	reg [15:0] pps_ring_1 = 16'h0001;
	reg [15:0] pps_ring_2 = 16'h0001;
	reg [15:0] pps_ring_3 = 16'h0001;
	reg [15:0] pps_ring_4 = 16'h0001;
	reg two_ms_flag = 0;
	reg two_ms_flag_div2 = 1;
	reg [15:0] pps_ring_5 = 16'h0001;
	reg [15:0] pps_ring_6 = 16'h0001;
	reg pps_internal = 0;
	always @(posedge clk_i) begin
		pps_ring_1 <= {pps_ring_1[14:0],pps_ring_1[15]};
		if (pps_ring_1[15]) pps_ring_2 <= {pps_ring_2[14:0],pps_ring_2[15]};
		if (pps_ring_1[15] && pps_ring_2[15]) pps_ring_3 <= {pps_ring_3[14:0],pps_ring_3[15]};
		if (pps_ring_1[15] && pps_ring_2[15] && pps_ring_3[15]) pps_ring_4 <= {pps_ring_4[14:0],pps_ring_4[15]};
		// This gets us to roughly 2 ms.
		two_ms_flag <= (pps_ring_1[15] && pps_ring_2[15] && pps_ring_3[15] && pps_ring_4[15]);
		if (two_ms_flag) pps_ring_5 <= {pps_ring_5[14:0],pps_ring_5[15]};
		if (two_ms_flag && pps_ring_5[15]) pps_ring_6 <= {pps_ring_6[14:0],pps_ring_6[15]};
		// This gets us to roughly 500 ms, so we just have a toggle flop generate the last flip.
		if (two_ms_flag && pps_ring_5[15] && pps_ring_6[15]) pps_internal <= ~pps_internal;
	end
	
	reg [1:0] pps_select_reg = {2{1'b0}};
	always @(posedge clk_i) begin
		if (rst_i) pps_select_reg <= {2{1'b0}};
		else if (wr_i) pps_select_reg <= dat_i[1:0];
	end
	wire [3:0] pps_mux;
	assign pps_mux[0] = PPS_ADU5A;
	assign pps_mux[1] = PPS_ADU5B;
	assign pps_mux[2] = PPS_G12;
	assign pps_mux[3] = pps_internal;

	assign pps_o = pps_mux[pps_select_reg];
	assign pps_burst_o = PPS_G12;
	assign dat_o = {{30{1'b0}},pps_select_reg};

endmodule
