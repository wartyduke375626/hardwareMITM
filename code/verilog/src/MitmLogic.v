/**
 * Main MITM logic module:
 * - utilizes the Bus interface module to intercept and modify communication
 * - an additional mode selecting input is used to switch dynamically between different MITM modes
**/

module MitmLogic #(

	// parameters
	parameter NUM_DATA_BITS = 8
) (

	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// i/o inputs
	input wire [NUM_MODES-1:0] mode_select,
	
	// bus control outputs
	output reg fake_if0_send_select = 1'b0,
	output reg fake_if1_send_select = 1'b0,
	output reg fake_if0_send_start = 1'b0,
	output reg fake_if1_send_start = 1'b0,
	
	// bus status inputs
	input wire if0_recv_new_data_ready,
	input wire if1_recv_new_data_ready,
	input wire if0_send_ready,
	input wire if1_send_ready,
	
	// data
	output reg [NUM_DATA_BITS-1:0] fake_if0_send_data = 0,
	output reg [NUM_DATA_BITS-1:0] fake_if1_send_data = 0,
	input wire [NUM_DATA_BITS-1:0] real_if0_recv_data,
	input wire [NUM_DATA_BITS-1:0] real_if1_recv_data
);

	// mode definitions
	localparam NUM_MODES = 4;
	localparam MODE_FORWARD = 4'b0001;
	localparam MODE_SUB0_BLOCK1 = 4'b0010;
	localparam MODE_SUB1_BLOCK0 = 4'b0100;
	localparam MODE_ROT_13 = 4'b1000;

	reg [NUM_MODES-1:0] mode = MODE_FORWARD;

	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			fake_if0_send_select <= 1'b0;
			fake_if1_send_select <= 1'b0;
			fake_if0_send_start <= 1'b0;
			fake_if1_send_start <= 1'b0;

			fake_if0_send_data <= 0;
			fake_if1_send_data <= 0;
			
			mode <= MODE_FORWARD;
		end
		
		else begin
			
			mode <= mode_select;
			
			case (mode)
				
				// forward mode -- set fake selects to 0
				MODE_FORWARD: begin
					
					fake_if0_send_select <= 1'b0;
					fake_if1_send_select <= 1'b0;
					
				end
				
				// substitute constant on if0 and block communication on if1 
				MODE_SUB0_BLOCK1: begin
				
					fake_if0_send_select <= 1'b1;
					fake_if1_send_select <= 1'b1;
					
					if (if0_recv_new_data_ready == 1'b1) begin
						fake_if1_send_data <= 36;	// 0x24 -- $ sign
						fake_if1_send_start <= 1'b1;
					end
					else begin
						fake_if1_send_start <= 1'b0;
					end
					
				end
				
				// substitute constant on if1 and block communication on if0
				MODE_SUB1_BLOCK0: begin
				
					fake_if0_send_select <= 1'b1;
					fake_if1_send_select <= 1'b1;
					
					if (if1_recv_new_data_ready == 1'b1) begin
						fake_if0_send_data <= 35;	// 0x23 -- # sign
						fake_if0_send_start <= 1'b1;
					end
					else begin
						fake_if0_send_start <= 1'b0;
					end
					
				end
				
				// perform ROT 13 encoding on if0->if1, decoding on if1->if0
				MODE_ROT_13: begin
				
					fake_if0_send_select <= 1'b1;
					fake_if1_send_select <= 1'b1;
					
					if (if0_recv_new_data_ready == 1'b1) begin
						fake_if1_send_data <= real_if0_recv_data + 13;
						fake_if1_send_start <= 1'b1;
					end
					else begin
						fake_if1_send_start <= 1'b0;
					end
					
					if (if1_recv_new_data_ready == 1'b1) begin
						fake_if0_send_data <= real_if1_recv_data - 13;
						fake_if0_send_start <= 1'b1;
					end
					else begin
						fake_if0_send_start <= 1'b0;
					end
					
				end
				
				// this should never occur
				default: begin
					fake_if0_send_select <= 1'b0;
					fake_if1_send_select <= 1'b0;
					fake_if0_send_start <= 1'b0;
					fake_if1_send_start <= 1'b0;

					fake_if0_send_data <= 0;
					fake_if1_send_data <= 0;
					
					mode <= MODE_FORWARD;
				end
				
			endcase
		end
	end

endmodule