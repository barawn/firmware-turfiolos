`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:22:06 07/01/2014
// Design Name:   TURFIOLOS_TOP
// Module Name:   C:/cygwin/home/barawn/firmware/ANITA/TURFIOLOS/sim/TURFIOLOS_TOP_TEST.v
// Project Name:  TURFIOLOS
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: TURFIOLOS_TOP
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module TURFIOLOS_TOP_TEST;

	// Inputs
	reg nADS;
	reg WnR;
	reg nBLAST;
	reg nCS2;
	reg nCS3;
	reg [12:2] LA;
	reg BCLKO;

	// Outputs
	wire nREADY;
	wire nBTERM;
	wire SDAT;
	wire SCLK;
	wire BIPHASE;

	// Bidirs
	wire [31:0] LD;

	// Instantiate the Unit Under Test (UUT)
	TURFIOLOS_TOP uut (
		.nADS(nADS), 
		.WnR(WnR), 
		.nBLAST(nBLAST), 
		.nCS2(nCS2), 
		.nCS3(nCS3), 
		.LA(LA), 
		.LD(LD), 
		.nREADY(nREADY), 
		.nBTERM(nBTERM), 
		.BCLKO(BCLKO), 
		.SDAT(SDAT), 
		.SCLK(SCLK), 
		.BIPHASE(BIPHASE)
	);

	always begin
		#15 BCLKO <= ~BCLKO;
	end

	initial begin
		// Initialize Inputs
		nADS = 1;
		WnR = 1;
		nBLAST = 1;
		nCS2 = 1;
		nCS3 = 1;
		LA = 0;
		BCLKO = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

