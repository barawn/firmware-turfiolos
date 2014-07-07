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
module LOSv3( input clk_i,
				  input wr_i,
				  input [10:0] burst_addr_i,
				  input burst_addr_wr_i,
				  input [31:0] dat_i,
				  output [31:0] dat_o,

				  input ctrl_wr_i,
				  input [31:0] ctrl_dat_i,
				  output [31:0] ctrl_dat_o,
				  output interrupt_o,
				  
				  output SDAT,
				  output SCLK,
				  output BIPHASE
    );

	// Telemetry works by filling a FIFO, and then writing to the control register.

	// Unlike before this now requires writing F00D first into the FIFO.
	reg [10:0] ram_write_address = {11{1'b0}};

	wire [10:0] telem_read_address;
	wire ram_address_reset;
	// Dual-port RAM. 2048x32.
	reg [31:0] ram_buffer[2047:0];
	reg [31:0] ram_data_out_A;
	reg [31:0] ram_data_out_B;

	reg send_buffer = 0;
	reg interrupt = 0;
	reg reset = 0;
	wire sending_buffer_done;
	wire [31:0] control_data_out;

	wire bitce;
	wire bittogce;
	wire wordce;
	wire syncce;

	always @(posedge clk_i) begin		
		if (wr_i) ram_buffer[ram_write_address] <= dat_i;
		ram_data_out_A <= ram_buffer[ram_write_address];
		ram_data_out_B <= ram_buffer[telem_read_address];

		if (ram_address_reset || reset) ram_write_address <= {11{1'b0}};
		else if (burst_addr_wr_i) ram_write_address <= burst_addr_i;
		else if (wr_i) ram_write_address <= ram_write_address + 1;

		if (ctrl_wr_i) reset <= ctrl_dat_i[0];
		else reset <= 0;
		
		if (sending_buffer_done || reset) send_buffer <= 0;
		else if (ctrl_wr_i) send_buffer <= ctrl_dat_i[1];
		
		if (sending_buffer_done) interrupt <= 1;
		else if (ctrl_wr_i  || reset) interrupt <= ctrl_dat_i[2];
	end
	
	telem_clock_v2 u_clock(.clk_i(clk_i),
								  .bitce_o(bitce),
								  .bittogce_o(bittogce),
								  .wordce_o(wordce),
								  .syncce_o(syncce));
	telemetry_generator u_gen(.clk_i(clk_i),
									  .bitce_i(bitce),
									  .bittogce_i(bittogce),
									  .wordce_i(wordce),
									  .syncce_i(syncce),
									  .start_i(send_buffer),
									  .rst_i(reset),
									  .done_o(sending_buffer_done),
									  .addr_o(telem_read_address),
									  .dat_i(ram_data_out_B),
									  .SDAT(SDAT),
									  .SCLK(SCLK),
									  .BIPHASE(BIPHASE));

	assign control_data_out = {{29{1'b0}},interrupt,send_buffer,reset};
	assign dat_o = ram_data_out_A;
	assign ctrl_dat_o = control_data_out;	
	assign interrupt_o = interrupt;

endmodule
