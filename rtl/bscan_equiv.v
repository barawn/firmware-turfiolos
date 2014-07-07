`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 - 2014 Authors                            ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  bscan_equiv module                                          ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////  Author(s):                                                  ////
////       Patrick Allison (pallison@opencores.org)					////
//////////////////////////////////////////////////////////////////////

module bscan_equiv(
							input JTCK,
							input JTMS,
							input JTDI,
							inout JTDO,

							input  TDO1,
							input  TDO2,
							output SEL1,
							output DRCK1,
							output SEL2,
							output DRCK2,
							output UPDATE,
							output SHIFT,
							output RESET,
							output TDI,
							output CAPTURE
    );

	wire tdo_tap, tdo_oe_tap;
	assign JTDO = (tdo_oe_tap) ? tdo_tap : 1'bZ;
	tap_top u_tap(.tms_pad_i(JTMS),
					  .tck_pad_i(JTCK),
					  .trstn_pad_i(1'b1),
					  .tdi_pad_i(JTDI),
					  .tdo_pad_o(tdo_tap),
					  .tdo_padoe_o(tdo_oe_tap),
					  .test_logic_reset_o(RESET),
					  .run_test_idle_o(),
					  .shift_dr_o(SHIFT),
					  .pause_dr_o(),
					  .update_dr_o(UPDATE),
					  .capture_dr_o(CAPTURE),
					  .user1_select_o(SEL1),
					  .user2_select_o(SEL2),
					  .tdi_o(TDI),
					  .user1_tdo_i(TDO1),
					  .user2_tdo_i(TDO2));
	assign DRCK1 = (JTCK && SEL1);
	assign DRCK2 = (JTCK && SEL2);

endmodule

// The following code is lifted from the Advanced Debug System
// on OpenCores.org, and changed to provide USER1/USER2 registers only
// and mock a configured Spartan-3.

// mock a spartan-3 minimally
`define IDCODE_VALUE 32'h22228093
`define USERCODE_VALUE 32'hFFFFFFFF
`define IR_LENGTH 6
// Fake that we're configured already.
`define IR_OUTPUT			6'b110101
`define IDCODE          6'b001001
`define USERCODE			6'b001000
`define USER1				6'b000010
`define USER2				6'b000011
`define BYPASS				6'b111111
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  tap_top module															   ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////  This module is part of the JTAG Test Access Port (TAP)      ////
////                                                              ////
////  Author(s):                                                  ////
////       Igor Mohor (igorm@opencores.org)                       ////
////       Nathan Yawn (nathan.yawn@opencores.org)                ////
////       Patrick Allison (pallison@opencores.org)					////
////                                                              ////
////  All additional information is avaliable in the jtag.pdf     ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

module tap_top(
                // JTAG pads
                tms_pad_i, 
                tck_pad_i, 
                trstn_pad_i, 
                tdi_pad_i, 
                tdo_pad_o, 
                tdo_padoe_o,
 
                // TAP states
 					 test_logic_reset_o,
					 run_test_idle_o,
                shift_dr_o,
                pause_dr_o, 
                update_dr_o,
                capture_dr_o,
 
                // Select signals for USER1 or USER2 register
                user1_select_o, 
                user2_select_o,
 
                // TDO signal that is connected to TDI of sub-modules.
                tdi_o, 
 
                // TDI signals from sub-modules
                user1_tdo_i,
					 user2_tdo_i
					);
 
 
// JTAG pins
input   tms_pad_i;      // JTAG test mode select pad
input   tck_pad_i;      // JTAG test clock pad
input   trstn_pad_i;     // JTAG test reset pad
input   tdi_pad_i;      // JTAG test data input pad
output  tdo_pad_o;      // JTAG test data output pad
output  tdo_padoe_o;    // Output enable for JTAG test data output pad 
 
// TAP states
output  test_logic_reset_o;
output  run_test_idle_o;
output  shift_dr_o;
output  pause_dr_o;
output  update_dr_o;
output  capture_dr_o;
 
// Select signals for boundary scan or mbist
output	user1_select_o;
output	user2_select_o;
 
// TDO signal that is connected to TDI of sub-modules.
output  tdi_o;
 
// TDI signals from sub-modules
input		user1_tdo_i;
input		user2_tdo_i;
 
// Wires which depend on the state of the TAP FSM
reg     test_logic_reset;
reg     run_test_idle;
reg     select_dr_scan;
reg     capture_dr;
reg     shift_dr;
reg     exit1_dr;
reg     pause_dr;
reg     exit2_dr;
reg     update_dr;
reg     select_ir_scan;
reg     capture_ir;
reg     shift_ir;
reg     exit1_ir;
reg     pause_ir;
reg     exit2_ir;
reg     update_ir;
 
// Wires which depend on the current value in the IR
reg	  user1_select;
reg	  user2_select;
reg	  idcode_select;
reg	  bypass_select;
reg     usercode_select;

// TDO and enable
reg     tdo_pad_o;
reg     tdo_padoe_o;
 
assign tdi_o = tdi_pad_i;
 
assign test_logic_reset_o = test_logic_reset;
assign run_test_idle_o = run_test_idle;
assign shift_dr_o = shift_dr;
assign pause_dr_o = pause_dr;
assign update_dr_o = update_dr;
assign capture_dr_o = capture_dr;

assign user1_select_o = user1_select;
assign user2_select_o = user2_select; 
 
/**********************************************************************************
*                                                                                 *
*   TAP State Machine: Fully JTAG compliant                                       *
*                                                                                 *
**********************************************************************************/
// Definition of machine state values.  We could one-hot encode this, and use 16
// registers, but this uses binary encoding for the minimum of 4 DFF's instead.
`define STATE_test_logic_reset 4'hF
`define STATE_run_test_idle    4'hC
`define STATE_select_dr_scan   4'h7
`define STATE_capture_dr       4'h6
`define STATE_shift_dr         4'h2
`define STATE_exit1_dr         4'h1
`define STATE_pause_dr         4'h3
`define STATE_exit2_dr         4'h0
`define STATE_update_dr        4'h5
`define STATE_select_ir_scan   4'h4
`define STATE_capture_ir       4'hE
`define STATE_shift_ir         4'hA
`define STATE_exit1_ir         4'h9
`define STATE_pause_ir         4'hB
`define STATE_exit2_ir         4'h8
`define STATE_update_ir        4'hD
 
reg [3:0] TAP_state = `STATE_test_logic_reset;  // current state of the TAP controller
reg [3:0] next_TAP_state;  // state TAP will take at next rising TCK, combinational signal
 
// sequential part of the FSM
always @ (posedge tck_pad_i or negedge trstn_pad_i)
begin
	if(trstn_pad_i == 0)
		TAP_state = `STATE_test_logic_reset;
	else
		TAP_state = next_TAP_state;
end
 
 
// Determination of next state; purely combinatorial
always @ (TAP_state or tms_pad_i)
begin
	case(TAP_state)
		`STATE_test_logic_reset:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_test_logic_reset; 
			else next_TAP_state = `STATE_run_test_idle;
			end
		`STATE_run_test_idle:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_select_dr_scan; 
			else next_TAP_state = `STATE_run_test_idle;
			end
		`STATE_select_dr_scan:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_select_ir_scan; 
			else next_TAP_state = `STATE_capture_dr;
			end
		`STATE_capture_dr:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_exit1_dr; 
			else next_TAP_state = `STATE_shift_dr;
			end
		`STATE_shift_dr:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_exit1_dr; 
			else next_TAP_state = `STATE_shift_dr;
			end
		`STATE_exit1_dr:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_update_dr; 
			else next_TAP_state = `STATE_pause_dr;
			end
		`STATE_pause_dr:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_exit2_dr; 
			else next_TAP_state = `STATE_pause_dr;
			end
		`STATE_exit2_dr:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_update_dr; 
			else next_TAP_state = `STATE_shift_dr;
			end
		`STATE_update_dr:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_select_dr_scan; 
			else next_TAP_state = `STATE_run_test_idle;
			end
		`STATE_select_ir_scan:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_test_logic_reset;
			else next_TAP_state = `STATE_capture_ir;
			end
		`STATE_capture_ir:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_exit1_ir; 
			else next_TAP_state = `STATE_shift_ir;
			end
		`STATE_shift_ir:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_exit1_ir; 
			else next_TAP_state = `STATE_shift_ir;
			end
		`STATE_exit1_ir:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_update_ir;
			else next_TAP_state = `STATE_pause_ir;
			end
		`STATE_pause_ir:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_exit2_ir;
			else next_TAP_state = `STATE_pause_ir;
			end
		`STATE_exit2_ir:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_update_ir;
			else next_TAP_state = `STATE_shift_ir;
			end
		`STATE_update_ir:
			begin
			if(tms_pad_i) next_TAP_state = `STATE_select_dr_scan;
			else next_TAP_state = `STATE_run_test_idle;
			end
		default: next_TAP_state = `STATE_test_logic_reset;  // can't actually happen
	endcase
end
 
 
// Outputs of state machine, pure combinatorial
always @ (TAP_state)
begin
	// Default everything to 0, keeps the case statement simple
	test_logic_reset = 1'b0;
	run_test_idle = 1'b0;
	select_dr_scan = 1'b0;
	capture_dr = 1'b0;
	shift_dr = 1'b0;
	exit1_dr = 1'b0;
	pause_dr = 1'b0;
	exit2_dr = 1'b0;
	update_dr = 1'b0;
	select_ir_scan = 1'b0;
	capture_ir = 1'b0;
	shift_ir = 1'b0;
	exit1_ir = 1'b0;
	pause_ir = 1'b0;
	exit2_ir = 1'b0;
	update_ir = 1'b0;
 
	case(TAP_state)
		`STATE_test_logic_reset: test_logic_reset = 1'b1;
		`STATE_run_test_idle:    run_test_idle = 1'b1;
		`STATE_select_dr_scan:   select_dr_scan = 1'b1;
		`STATE_capture_dr:       capture_dr = 1'b1;
		`STATE_shift_dr:         shift_dr = 1'b1;
		`STATE_exit1_dr:         exit1_dr = 1'b1;
		`STATE_pause_dr:         pause_dr = 1'b1;
		`STATE_exit2_dr:         exit2_dr = 1'b1;
		`STATE_update_dr:        update_dr = 1'b1;
		`STATE_select_ir_scan:   select_ir_scan = 1'b1;
		`STATE_capture_ir:       capture_ir = 1'b1;
		`STATE_shift_ir:         shift_ir = 1'b1;
		`STATE_exit1_ir:         exit1_ir = 1'b1;
		`STATE_pause_ir:         pause_ir = 1'b1;
		`STATE_exit2_ir:         exit2_ir = 1'b1;
		`STATE_update_ir:        update_ir = 1'b1;
		default: ;
	endcase
end
 
/**********************************************************************************
*                                                                                 *
*   End: TAP State Machine                                                        *
*                                                                                 *
**********************************************************************************/
 
 
 
/**********************************************************************************
*                                                                                 *
*   jtag_ir:  JTAG Instruction Register                                           *
*                                                                                 *
**********************************************************************************/
reg [`IR_LENGTH-1:0]  jtag_ir;          // Instruction register
reg [`IR_LENGTH-1:0]  latched_jtag_ir; //, latched_jtag_ir_neg;
wire                  instruction_tdo;
 
always @ (posedge tck_pad_i or negedge trstn_pad_i)
begin
  if(trstn_pad_i == 0)
    jtag_ir[`IR_LENGTH-1:0] <= `IR_LENGTH'b0;
  else if (test_logic_reset == 1)
	jtag_ir[`IR_LENGTH-1:0] <= `IR_LENGTH'b0;
  else if(capture_ir)
    jtag_ir <= `IR_OUTPUT;          // This value is fixed for easier fault detection
  else if(shift_ir)
    jtag_ir[`IR_LENGTH-1:0] <= {tdi_pad_i, jtag_ir[`IR_LENGTH-1:1]};
end
 
assign instruction_tdo = jtag_ir[0];  // This is latched on a negative TCK edge after the output MUX
 
// Updating jtag_ir (Instruction Register)
// jtag_ir should be latched on FALLING EDGE of TCK when capture_ir == 1
always @ (negedge tck_pad_i or negedge trstn_pad_i)
begin
  if(trstn_pad_i == 0)
    latched_jtag_ir <= `IDCODE;   // IDCODE selected after reset
  else if (test_logic_reset)
    latched_jtag_ir <= `IDCODE;   // IDCODE selected after reset
  else if(update_ir)
    latched_jtag_ir <= jtag_ir;
end
 
/**********************************************************************************
*                                                                                 *
*   End: jtag_ir                                                                  *
*                                                                                 *
**********************************************************************************/
 
 
 
/**********************************************************************************
*                                                                                 *
*   idcode logic                                                                  *
*                                                                                 *
**********************************************************************************/
reg [31:0] idcode_reg;
wire        idcode_tdo;
always @ (posedge tck_pad_i or negedge trstn_pad_i)
begin
  if(trstn_pad_i == 0)
    idcode_reg <= `IDCODE_VALUE;   // IDCODE selected after reset
  else if (test_logic_reset)
    idcode_reg <= `IDCODE_VALUE;   // IDCODE selected after reset
  else if(idcode_select & capture_dr)
    idcode_reg <=  `IDCODE_VALUE;
  else if(idcode_select & shift_dr)
    idcode_reg <=  {tdi_pad_i, idcode_reg[31:1]}; 
end

assign idcode_tdo = idcode_reg[0];   // This is latched on a negative TCK edge after the output MUX

reg [31:0] usercode_reg;
wire        usercode_tdo;
 
always @ (posedge tck_pad_i or negedge trstn_pad_i)
begin
  if(trstn_pad_i == 0)
    usercode_reg <= `USERCODE_VALUE;   // IDCODE selected after reset
  else if (test_logic_reset)
    usercode_reg <= `USERCODE_VALUE;   // IDCODE selected after reset
  else if(idcode_select & capture_dr)
    usercode_reg <=  `USERCODE_VALUE;
  else if(idcode_select & shift_dr)
    usercode_reg <=  {tdi_pad_i, usercode_reg[31:1]}; 
end

assign usercode_tdo = usercode_reg[0];
 
/**********************************************************************************
*                                                                                 *
*   End: idcode logic                                                             *
*                                                                                 *
**********************************************************************************/
 
 
/**********************************************************************************
*                                                                                 *
*   Bypass logic                                                                  *
*                                                                                 *
**********************************************************************************/
wire  bypassed_tdo;
reg   bypass_reg;  // This is a 1-bit register
 
always @ (posedge tck_pad_i or negedge trstn_pad_i)
begin
  if (trstn_pad_i == 0)
     bypass_reg <=  1'b0;
  else if (test_logic_reset == 1)
     bypass_reg <=  1'b0;
  else if (bypass_select & capture_dr)
    bypass_reg<= 1'b0;
  else if(bypass_select & shift_dr)
    bypass_reg<= tdi_pad_i;
end
 
assign bypassed_tdo = bypass_reg;   // This is latched on a negative TCK edge after the output MUX
 
/**********************************************************************************
*                                                                                 *
*   End: Bypass logic                                                             *
*                                                                                 *
**********************************************************************************/
 
 
/**********************************************************************************
*                                                                                 *
*   Selecting active data register                                                *
*                                                                                 *
**********************************************************************************/
always @ (latched_jtag_ir)
begin
  user1_select           	= 1'b0;
  user2_select   				= 1'b0;
  idcode_select           	= 1'b0;
  usercode_select				= 1'b0;
  bypass_select				= 1'b0;
  
  case(latched_jtag_ir)    /* synthesis parallel_case */ 
    `IDCODE:            idcode_select           = 1'b1;    // ID Code
	 `USERCODE:				usercode_select			= 1'b1;
	 `USER1:					user1_select				= 1'b1;
	 `USER2:					user2_select				= 1'b1;
    `BYPASS:            bypass_select           = 1'b1;    // BYPASS
    default:            bypass_select           = 1'b1;    // BYPASS
  endcase
end
 
 
/**********************************************************************************
*                                                                                 *
*   Multiplexing TDO data                                                         *
*                                                                                 *
**********************************************************************************/
reg tdo_mux_out;  // really just a wire
 
always @ (shift_ir or instruction_tdo or latched_jtag_ir or idcode_tdo or
			 usercode_tdo or bypassed_tdo or user1_tdo_i or user2_tdo_i)
begin
  if(shift_ir)
    tdo_mux_out = instruction_tdo;
  else
    begin
      case(latched_jtag_ir)    // synthesis parallel_case
        `IDCODE:            tdo_mux_out = idcode_tdo;       // Reading ID code
		  `USERCODE:			 tdo_mux_out = usercode_tdo;
		  `USER1:				 tdo_mux_out = user1_tdo_i;
		  `USER2:				 tdo_mux_out = user2_tdo_i;
        default:            tdo_mux_out = bypassed_tdo;     // BYPASS instruction
      endcase
    end
end
 
 
// TDO changes state at negative edge of TCK
always @ (negedge tck_pad_i)
begin
	tdo_pad_o = tdo_mux_out;
end
 
 
// Tristate control for tdo_pad_o pin
always @ (posedge tck_pad_i)
begin
  tdo_padoe_o <= shift_ir | shift_dr;
end
/**********************************************************************************
*                                                                                 *
*   End: Multiplexing TDO data                                                    *
*                                                                                 *
**********************************************************************************/
 
endmodule
