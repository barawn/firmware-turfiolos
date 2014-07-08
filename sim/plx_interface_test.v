`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:47:05 06/30/2014
// Design Name:   plx_interface
// Module Name:   C:/cygwin/home/barawn/firmware/ANITA/TURFIOLOS/sim/plx_interface_test.v
// Project Name:  TURFIOLOS
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: plx_interface
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module plx_interface_test;

	// Inputs
	reg nADS;
	reg WnR;
	reg nBLAST;
	reg nCS2;
	reg nCS3;
	reg [12:2] LA;
	reg [31:0] LD_o;
	wire [31:0] LD;
	reg ld_oe = 0;
	assign LD = (ld_oe) ? LD_o : {32{1'bZ}};
	reg clk_i;

	// Outputs
	wire nREADY;
	wire nBTERM;

	// Instantiate the Unit Under Test (UUT)
	plx_interface uut (
		.nADS(nADS), 
		.WnR(WnR), 
		.nBLAST(nBLAST), 
		.nCS2(nCS2), 
		.nCS3(nCS3), 
		.LA(LA), 
		.LD(LD), 
		.nREADY(nREADY), 
		.nBTERM(nBTERM), 
		.clk_i(clk_i),
		.mem_dat_i(32'hA5A5A5A5)
	);

	always begin
		#15 clk_i <= ~clk_i;
	end

	initial begin
		// Initialize Inputs
		nADS = 1;
		WnR = 1;
		nBLAST = 1;
		nCS2 = 1;
		nCS3 = 1;
		LA = 0;
		LD_o = 0;
		ld_oe = 0;
		clk_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		
		// Test burst write to mem
		@(posedge clk_i);
		nADS <= 0;
		nCS3 <= 0;
		LA <= 11'h000;
		ld_oe <= 1;
		LD_o <= 32'h01234567;
		@(posedge clk_i);
		nADS <= 1;
		// wait for nREADY
		while (nREADY) @(posedge clk_i);
		// now write three more...
		LD_o <= 32'h89ABCDEF; @(posedge clk_i);
		LD_o <= 32'hFEDCBA98; @(posedge clk_i);
		LD_o <= 32'h76543210; nBLAST <= 0; @(posedge clk_i);
		nBLAST <= 1;
		nCS3 <= 1;
		ld_oe <= 0;
		@(posedge clk_i);
		@(posedge clk_i);
		nADS <= 0;
		nCS3 <= 0;
		WnR <= 0;
		LA <= 11'h000;
		@(posedge clk_i);
		nADS <= 1;
		nBLAST <= 0;
		while (nREADY) begin
			@(posedge clk_i);
			nBLAST <= 1;
		end
		@(posedge clk_i);
		WnR <= 1;

		
	end

      
endmodule

