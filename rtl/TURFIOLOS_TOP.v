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
module TURFIOLOS_TOP(
		// PLX interface
		input nADS,
		input WnR,
		input nBLAST,
		input nCS2,
		input nCS3,
		input [12:2] LA,
		inout [31:0] LD,
		output nREADY,
		output nBTERM,
		input BCLKO,
		// Driver enables.
		output DRV_0123,
		output DRV_4567,
		output DRV_8,
		
		// 125 MHz clock
		input HS_REFCLK,
		
		// LOS outputs
		output SDAT,
		output SCLK,
		output BIPHASE,
		output SYNC,
		
		// SMA inputs/outputs
		input PPS_ADU5A,
		input PPS_ADU5B,
		input PPS_G12,		
		output PHOTO_ADU5A,
		output PHOTO_ADU5B,
		output PHOTO_G12,
		input EXT_TRIG,
		output TRIG_OUT,
		
		input TURF_TRIG_IN,
		output TURF_TRIG_OUT,
		output PPS,
		output PPS_BURST,
		
		// TURF interface
		inout [7:0] TURF_DIO,
		output TURF_WnR,
		output nCSTURF,
		output TURFCLK_P,
		output TURFCLK_N,
		output REFCLK_P,
		output REFCLK_N,
		// TURF reprogramming
		output FPROG,
		
		input MTCK,
		input MTMS,
		input MTDI,
		inout MTDO
    );
	
	parameter [3:0] VER_MONTH = 7;
	parameter [7:0] VER_DAY = 7;
	parameter [3:0] VER_MAJOR = 2;
	parameter [3:0] VER_MINOR = 0;
	parameter [7:0] VER_REV = 0;
	parameter [3:0] VER_BOARDREV = 1;
	parameter [31:0] VERSION = {VER_BOARDREV, VER_MONTH, VER_DAY, VER_MAJOR, VER_MINOR, VER_REV};
	
	wire bclk_to_bufg;
	wire refclk_to_bufg;
	wire pclk;
	wire refclk;
	wire refclk_sel;
	
	IBUFG u_ibufg(.I(BCLKO),.O(bclk_to_bufg));
	IBUFG u_refclk(.I(HS_REFCLK),.O(refclk_to_bufg));
	BUFG u_pclk_bufg(.I(bclk_to_bufg),.O(pclk));
//	BUFG u_refclk_bufg(.I(refclk_to_bufg),.O(refclk));

//	BUFGMUX u_pclk_bufgmux(.I0(bclk_to_bufg),.I1(refclk_to_bufg),.O(pclk),.S(1'b0));
	BUFGMUX u_refclk_bufgmux(.I0(refclk_to_bufg),.I1(pclk),.O(refclk),.S(refclk_sel));

	////////////////////////////////////////////////////////////////////////////////
	// LOS signals.
	////////////////////////////////////////////////////////////////////////////////
	
	wire mem_wr;
	wire mem_burst_addr_wr;
	wire [11:0] mem_burst_addr;
	wire los_ctrl_wr;
	wire [31:0] los_ctrl_dat_from_plx;
	wire [31:0] los_ctrl_dat_to_plx;
	wire los_interrupt;
	wire [31:0] mem_dat_from_plx;
	wire [31:0] mem_dat_to_plx;
	
	////////////////////////////////////////////////////////////////////////////////
	// TURFIO signals.
	////////////////////////////////////////////////////////////////////////////////

	wire tio_wr;
	wire [5:0] tio_addr;
	wire [31:0] tio_dat_from_plx;
	wire [31:0] tio_dat_to_plx;
	wire [31:0] pps_dat_from_plx;
	wire [31:0] pps_dat_to_plx;
	wire [31:0] photo_dat_from_plx;
	wire [31:0] photo_dat_to_plx;
	wire [31:0] clock_dat_from_plx;
	wire [31:0] clock_dat_to_plx;
	
	////////////////////////////////////////////////////////////////////////////////
	// TURF signals.
	////////////////////////////////////////////////////////////////////////////////
	
	wire turf_wr;
	wire turf_rd;
	wire [5:0] turf_addr;
	wire [31:0] turf_dat_from_plx;
	wire [31:0] turf_dat_to_plx;
	wire turf_ack;
	wire [35:0] debug;
	wire [1:0] turf_bank;
	
	////////////////////////////////////////////////////////////////////////////////
	// PCI9030 Local Bus interface.
	////////////////////////////////////////////////////////////////////////////////

	plx_interface u_interface(.clk_i(pclk),
									  .WnR(WnR),
									  .nADS(nADS),
									  .nBLAST(nBLAST),
									  .nCS2(nCS2),
									  .nCS3(nCS3),
									  .LA(LA),
									  .LD(LD),
									  .nREADY(nREADY),
									  .nBTERM(nBTERM),
									  .mem_wr_o(mem_wr),
									  .mem_burst_addr_o(mem_burst_addr),
									  .mem_burst_addr_wr_o(mem_burst_addr_wr),
									  .mem_dat_o(mem_dat_from_plx),
									  .mem_dat_i(mem_dat_to_plx),
									  .tio_wr_o(tio_wr),
									  .tio_addr_o(tio_addr),
									  .tio_dat_o(tio_dat_from_plx),
									  .tio_dat_i(tio_dat_to_plx),
									  .turf_wr_o(turf_wr),
									  .turf_rd_o(turf_rd),
									  .turf_addr_o(turf_addr),
									  .turf_dat_o(turf_dat_from_plx),
									  .turf_dat_i(turf_dat_to_plx),
									  .turf_ack_i(turf_ack),
									  .debug_o(debug));

	////////////////////////////////////////////////////////////////////////////////
	// LOS top-level module.
	////////////////////////////////////////////////////////////////////////////////
	LOSv3 u_los(.clk_i(pclk),
					.wr_i(mem_wr),
					.burst_addr_wr_i(mem_burst_addr_wr),
					.burst_addr_i(mem_burst_addr),
					.ctrl_wr_i(los_ctrl_wr),
					.ctrl_dat_i(los_ctrl_dat_from_plx),
					.ctrl_dat_o(los_ctrl_dat_to_plx),
					.interrupt_o(los_interrupt),
					.dat_i(mem_dat_from_plx),
					.dat_o(mem_dat_to_plx),
					.SDAT(SDAT),
					.SCLK(SCLK),
					.BIPHASE(BIPHASE));
	assign SYNC = 0;

	////////////////////////////////////////////////////////////////////////////////
	// TURFIO top-level module.
	////////////////////////////////////////////////////////////////////////////////									  
	TURFIOv3 #(.VERSION(VERSION)) u_turfio(.clk_i(pclk),
							.wr_i(tio_wr),
							.dat_i(tio_dat_from_plx),
							.dat_o(tio_dat_to_plx),
							.addr_i(tio_addr),
							.losctrl_wr_o(los_ctrl_wr),
							.losctrl_dat_o(los_ctrl_dat_from_plx),
							.losctrl_dat_i(los_ctrl_dat_to_plx),

							.pps_wr_o(pps_wr),
							.pps_dat_o(pps_dat_from_plx),
							.pps_dat_i(pps_dat_to_plx),
							
							.photo_wr_o(photo_wr),
							.photo_dat_o(photo_dat_from_plx),
							.photo_dat_i(photo_dat_to_plx),
							
							.clock_wr_o(clock_wr),
							.clock_dat_o(clock_dat_from_plx),
							.clock_dat_i(clock_dat_to_plx),
							
							.turf_bank_o(turf_bank)
							);
	////////////////////////////////////////////////////////////////////////////////
	// PPS register module.
	////////////////////////////////////////////////////////////////////////////////									  
	PPSv2 u_pps(.clk_i(pclk),
					.wr_i(pps_wr),
					.dat_i(pps_dat_from_plx),
					.dat_o(pps_dat_to_plx),	
					.rst_i(global_reset),
					.pps_o(PPS),
					.pps_burst_o(PPS_BURST),
					.PPS_ADU5A(PPS_ADU5A),
					.PPS_ADU5B(PPS_ADU5B),
					.PPS_G12(PPS_G12));
	////////////////////////////////////////////////////////////////////////////////
	// Photoshutter control.
	////////////////////////////////////////////////////////////////////////////////									  
	PHOTOv2 u_photo(.clk_i(pclk),
						 .wr_i(photo_wr),
						 .dat_i(photo_dat_from_plx),
						 .dat_o(photo_dat_to_plx),
						 .rst_i(global_reset),
						 .TRIG(TURF_TRIG_IN),
						 .P1(PHOTO_ADU5A),
						 .P2(PHOTO_ADU5B),
						 .P3(PHOTO_G12),
						 .TRIG_OUT(TRIG_OUT));
	////////////////////////////////////////////////////////////////////////////////
	// Clock control.
	////////////////////////////////////////////////////////////////////////////////									  
	CLOCKv2 u_clock(.clk_i(pclk),
						 .wr_i(clock_wr),
						 .dat_i(clock_dat_from_plx),
						 .dat_o(clock_dat_to_plx),
						 .tstatus_i(turf_dcm_status),
						 .tlock_i(turf_lock_status),
						 .treset_o(turf_dcm_reset),
						 .reset_o(global_reset),
						 .sel_o(refclk_sel),
						 .FPROG(FPROG));
	////////////////////////////////////////////////////////////////////////////////
	// Dynamic phase shift module. Controls TURF clock.
	// Is this needed? Probably not anymore.
	////////////////////////////////////////////////////////////////////////////////									  
	TURF_interface_v2 u_turfif(.clk_i(pclk),
										.wr_i(turf_wr),
										.rd_i(turf_rd),
										.addr_i(turf_addr),
										.bank_i(turf_bank),
										.ack_o(turf_ack),
										.dat_i(turf_dat_from_plx),
										.dat_o(turf_dat_to_plx),
										.TURF_DIO(TURF_DIO),
										.TURF_WnR(TURF_WnR),
										.nCSTURF(nCSTURF));
	// TURF bus clock output.
	wire turfclk_to_obufds;
	FDDRRSE u_turfclk_fddr(.D0(1'b1),.D1(1'b0),.C0(pclk),.C1(~pclk),.CE(1'b1),.R(1'b0),.S(1'b0),.Q(turfclk_to_obufds));
	OBUFDS u_turfclk_obufds(.I(turfclk_to_obufds),.O(TURFCLK_P),.OB(TURFCLK_N));
	// Ref clock output.
	wire refclk_to_obufds;
	FDDRRSE u_refclk_fddr(.D0(1'b1),.D1(1'b0),.C0(refclk),.C1(~refclk),.CE(1'b1),.R(1'b0),.S(1'b0),.Q(refclk_to_obufds));
	OBUFDS u_refclk_obufds(.I(refclk_to_obufds),.O(REFCLK_P),.OB(REFCLK_N));
	
	assign DRV_0123 = 1'b1;
	assign DRV_4567 = 1'b0;
	assign DRV_8 = 1'b1;
	
	
	// Boundary scan equivalent module, connected to monitoring pins. For ChipScope.
	wire SEL1, SEL2, DRCK1, DRCK2;
	wire TDO1, TDO2, TDI, RESET, CAPTURE, UPDATE, SHIFT;
	assign TDO2 = TDI;
	bscan_equiv u_bscan(.JTCK(MTCK),.JTMS(MTMS),.JTDI(MTDI),.JTDO(MTDO),
							  .SEL1(SEL1),.SEL2(SEL2),.DRCK1(DRCK1),.DRCK2(DRCK2),
							  .TDO1(TDO1),.TDO2(TDO2),.TDI(TDI),.RESET(RESET),.CAPTURE(CAPTURE),
							  .UPDATE(UPDATE),.SHIFT(SHIFT));
	wire [35:0] ila_control;
	wire [35:0] ila_debug = debug;

//	assign ila_debug[0] = mem_wr;
//	assign ila_debug[1] = mem_addr;
//	assign ila_debug[2 +: 32] = mem_dat_from_plx;
//	assign ila_debug[35] = SDAT;
	
	tiolos_icon u_icon(.RESET_IN(RESET),.CAPTURE_IN(CAPTURE),.UPDATE_IN(UPDATE),.SHIFT_IN(SHIFT),
							 .SEL_IN(SEL1),.DRCK_IN(DRCK1),.TDO_OUT(TDO1),.TDI_IN(TDI),
							 .CONTROL0(ila_control));
	tiolos_ila u_ila(.CONTROL(ila_control),.CLK(pclk),.TRIG0(ila_debug));
	

endmodule
