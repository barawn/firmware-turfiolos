`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:16:21 06/01/2008 
// Design Name: 
// Module Name:    PINGPONG 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module PINGPONG(
	 input [31:0] DIN,
    output [31:0] DO,
	 output P1,
    output P2,
    output P3,
	 input CLK,
    input TRIG,
	 input ENABLE,
	 input RESET
    );

	wire [4:0] PHOTO; // PHOTO[2:0] are the photo masks. PHOTO[3] is enable.
	                  // PHOTO[4] is a reset toggle.
	wire LRESET;
	wire PHOTODIS=PHOTO[3];
	wire [2:0] PHOTO_MASK=PHOTO[2:0];
	
	reg [4:0] photo_reg = {5{1'b0}};
	always @(posedge CLK) begin
		if (ENABLE) photo_reg[3:0] <= DIN[3:0];
		if (ENABLE) photo_reg[4] <= DIN[4];
		else photo_reg[4] <= 0;
	end
	
	assign PHOTO = photo_reg;
	assign LRESET = PHOTO[4];
		
	reg photoTrig;
	reg photoTrig1;
	reg photoTrig2;
	reg photoTrig3;
	reg [1:0] curPhotoOut;
	reg [8:0] counter1;
	reg [8:0] counter2;
	reg [8:0] counter3;
	reg startCounter1;
	reg startCounter2;
	reg startCounter3;

	reg nextPhotoOut;
	reg startCount;

	wire MYRESET;
	assign MYRESET = (LRESET || RESET);

	assign DO[31:18] = 0;
	assign DO[15:5] = 0;
	assign DO[4:0] = PHOTO;
	assign DO[17:16] = curPhotoOut;

				
	parameter SIZE = 3;
	parameter IDLE = 1,
				START_COUNT = 2,
				NEXT = 4;
	reg [SIZE-1:0] state;
	
	initial begin
		counter1 <= 9'h000;
		counter2 <= 9'h000;
		counter3 <= 9'h000;
		photoTrig <= 0;
		photoTrig1 <= 0;
		photoTrig2 <= 0;
		photoTrig3 <= 0;
		curPhotoOut <= 2'b00;
		state <= IDLE;
		nextPhotoOut <= 1;
		startCount <= 1;
	end
		
	wire RESET_1 = (counter1[8] || MYRESET);
	wire RESET_2 = (counter2[8] || MYRESET);
	wire RESET_3 = (counter3[8] || MYRESET);
	
	
	always @(posedge TRIG or posedge RESET_1) begin
		if (RESET_1) begin
			photoTrig1 <= 0;
		end else if (curPhotoOut == 2'b00 && ~PHOTODIS) begin
			photoTrig1 <= 1;
		end
	end
	always @(posedge TRIG or posedge RESET_2) begin
		if (RESET_2) begin
			photoTrig2 <= 0;
		end else if (curPhotoOut == 2'b01 && ~PHOTODIS) begin
			photoTrig2 <= 1;
		end
	end
	always @(posedge TRIG or posedge RESET_3) begin
		if (RESET_3) begin
			photoTrig3 <= 0;
		end else if (curPhotoOut == 2'b10 && ~PHOTODIS) begin
			photoTrig3 <= 1;
		end
	end
	
	always @(posedge CLK) begin
		if (MYRESET) begin
			photoTrig <= 0;
		end else begin
			case (curPhotoOut)
				2'b00: if (photoTrig1) photoTrig <= 1; else photoTrig <= 0;
				2'b01: if (photoTrig2) photoTrig <= 1; else photoTrig <= 0;
				2'b10: if (photoTrig3) photoTrig <= 1; else photoTrig <= 0;
				2'b11: photoTrig <= 0;
			endcase
		end
	end
	
	always @(posedge CLK) begin
		case (state)
			IDLE: if (photoTrig) state <= START_COUNT;
			START_COUNT: state <= NEXT;
			NEXT: state <= IDLE;
			default: state <= IDLE;
		endcase
	end
	always @(state) begin
		if (MYRESET) begin
			nextPhotoOut <= 0;
			startCount <= 0;
		end else begin
			case (state)
				IDLE: begin
					nextPhotoOut <= 0;
					startCount <= 0;
				end
				START_COUNT: begin
					nextPhotoOut <= 0;
					startCount <= 1;
				end
				NEXT: begin
					nextPhotoOut <= 1;
					startCount <= 0;
				end
				default: begin
					nextPhotoOut <= 0;
					startCount <= 0;
				end
			endcase
		end
	end
	always @(posedge CLK) begin
		if (counter1[8] || MYRESET) begin
			startCounter1 <= 0;
		end else if (startCount && photoTrig1) begin
			startCounter1 <= 1;
		end
	end
	always @(posedge CLK) begin
		if (counter2[8] || MYRESET) begin
			startCounter2 <= 0;
		end else if (startCount && photoTrig2) begin
			startCounter2 <= 1;
		end
	end
	always @(posedge CLK) begin
		if (counter3[8] || MYRESET) begin
			startCounter3 <= 0;
		end else if (startCount && photoTrig3) begin
			startCounter3 <= 1;
		end
	end

	
	always @(posedge CLK) begin
		if (counter1[8] || MYRESET) begin
			counter1 <= 0;
		end else if (startCounter1) begin
			counter1 <= counter1 + 1;
		end
	end
	always @(posedge CLK) begin
		if (counter2[8] || MYRESET) begin
			counter2 <= 0;
		end else if (startCounter2) begin
			counter2 <= counter2 + 1;
		end
	end
	always @(posedge CLK) begin
		if (counter3[8] || MYRESET) begin
			counter3 <= 0;
		end else if (startCounter3) begin
			counter3 <= counter3 + 1;
		end
	end
	
	always @(posedge CLK) begin
		if (MYRESET) begin
			curPhotoOut[0] <= ((PHOTO_MASK[0] && PHOTO_MASK[1] && PHOTO_MASK[2]) ||
									(~PHOTO_MASK[1] && PHOTO_MASK[0]));
			curPhotoOut[1] <= (PHOTO_MASK[0] && PHOTO_MASK[1]);
		end else if (nextPhotoOut) begin
			case (curPhotoOut)
				2'b00: begin
					// Use PHOTO_MASK [2,1] to generate curPhotoOut[1:0]
					// X0 => 01
					// 01 => 10
					// 11 => 00
					//
					curPhotoOut[0] <= ~PHOTO_MASK[1];
					curPhotoOut[1] <= PHOTO_MASK[1] && ~PHOTO_MASK[2];
				end
				2'b01: begin
					// Use PHOTO_MASK[0,2] to generate curPhotoOut[1:0]
					// X0 => 10
					// 01 => 00
					// 11 => 01
					//
					curPhotoOut[0] <= PHOTO_MASK[2] && PHOTO_MASK[0];
					curPhotoOut[1] <= ~PHOTO_MASK[2];
				end
				2'b10: begin
					// Use PHOTO_MASK[1,0] to generate curPhotoOut[1:0]
					// X0 => 00
					// 01 => 01
					// 11 => 10
					//
					curPhotoOut[0] <= ~PHOTO_MASK[1] && PHOTO_MASK[0];
					curPhotoOut[1] <= PHOTO_MASK[1] && PHOTO_MASK[0];
				end
				// 2'b11 is a nonvalid state. We also use it for a 'total disable', but this bails out.
				2'b11: begin
					// Same as the MYRESET logic.
					curPhotoOut[0] <= ((PHOTO_MASK[0] && PHOTO_MASK[1] && PHOTO_MASK[2]) ||
											(~PHOTO_MASK[1] && PHOTO_MASK[0]));
					curPhotoOut[1] <= (PHOTO_MASK[0] && PHOTO_MASK[1]);
				end
			endcase
		end
	end

assign P1 = photoTrig1;
assign P2 = photoTrig2;
assign P3 = photoTrig3;

endmodule
