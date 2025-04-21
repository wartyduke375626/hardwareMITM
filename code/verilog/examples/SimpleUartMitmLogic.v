/**
 * MITM logic module example:
 * - this is a simple MITM logic example attacking UART communication
 * - utilizes the Bus interface module to intercept and modify communication
 * - an additional mode selecting input is used to switch dynamically between different MITM modes
 * - it has 4 modes of operation:
 *     - MODE_FORWARD: no MITM interference with communication
 *     - MODE_SUB0_BLOCK1: IF1->IF0 sub every byte with 0x23 (ASCI '#'), block IF0->IF1
 *     - MODE_SUB1_BLOCK0: IF0->IF1 sub every byte with 0x24 (ASCI '$'), block IF1->IF0
 *     - MODE_ROT_13: for both directions perform ROT13 operation on [a-zA-Z], other characters remain unchanged
**/

module MitmLogic #(

	// parameters
	parameter NUM_DATA_BITS = 8,
	parameter NUM_MITM_MODES = 4
) (

	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// i/o inputs
	input wire [NUM_MITM_MODES-1:0] mode_select,
	
	// bus control outputs
	output reg fake_if0_select = 1'b0,
	output reg fake_if1_select = 1'b0,
	output reg fake_if0_send_start = 1'b0,
	output reg fake_if1_send_start = 1'b0,
	output reg fake_if0_keep_alive = 1'b0,
	output reg fake_if1_keep_alive = 1'b0,
	
	// bus status inputs
	input wire if0_recv_new_data,
	input wire if1_recv_new_data,
	input wire fake_if0_send_ready,
	input wire fake_if1_send_ready,
	input wire fake_if0_send_done,
	input wire fake_if1_send_done,
	
	// data
	output reg [NUM_DATA_BITS-1:0] fake_if0_send_data = 0,
	output reg [NUM_DATA_BITS-1:0] fake_if1_send_data = 0,
	input wire [NUM_DATA_BITS-1:0] real_if0_recv_data,
	input wire [NUM_DATA_BITS-1:0] real_if1_recv_data
);

	// mode definitions
	localparam MODE_FORWARD = 4'b0001;
	localparam MODE_SUB0_BLOCK1 = 4'b0010;
	localparam MODE_SUB1_BLOCK0 = 4'b0100;
	localparam MODE_ROT_13 = 4'b1000;

	reg [NUM_MITM_MODES-1:0] mode = MODE_FORWARD;
	
	// states
	localparam STATE_READ = 0;
	localparam STATE_WRITE = 1;
	localparam STATE_FINISH = 2;
	localparam STATE_RESET = 3;
	
	reg [1:0] fake_if0_state = STATE_RESET;
	reg [1:0] fake_if1_state = STATE_RESET;
	
	always @ (posedge sys_clk)
	begin
		mode <= mode_select;
			
		if (mode == MODE_FORWARD) begin
			fake_if0_select <= 1'b0;
			fake_if1_select <= 1'b0;
		end
		else begin
			fake_if0_select <= 1'b1;
			fake_if1_select <= 1'b1;
		end
	end
	
	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			fake_if0_state <= STATE_RESET;
		end
		
		else begin
			case (fake_if0_state)
				
				STATE_READ: begin
					if (if1_recv_new_data == 1'b1) begin
						case (mode)
						
							MODE_FORWARD: begin
								fake_if0_state <= STATE_READ;
							end
						
							MODE_SUB0_BLOCK1: begin
								fake_if0_send_data <= 'h23;	// # sign
								fake_if0_state <= STATE_WRITE;
							end
							
							MODE_SUB1_BLOCK0: begin
								fake_if0_state <= STATE_READ;
							end
							
							MODE_ROT_13: begin
								// for A-M,a-m we rotate by +13
								if ((real_if1_recv_data >= 65 && real_if1_recv_data <= 77) || (real_if1_recv_data >= 97 && real_if1_recv_data <= 109)) begin
									fake_if0_send_data <= real_if1_recv_data + 13;
								end
								// for N-Z,n-z we rotate by -13 (+13 == -13 mod 26)
								else if ((real_if1_recv_data >= 78 && real_if1_recv_data <= 90) || (real_if1_recv_data >= 110 && real_if1_recv_data <= 122)) begin
									fake_if0_send_data <= real_if1_recv_data - 13;
								end
								// else don't rotate
								else begin
									fake_if0_send_data <= real_if1_recv_data;
								end
								
								fake_if0_state <= STATE_WRITE;
							end
							
						endcase
					end
				end
				
				STATE_WRITE: begin
					if (fake_if0_send_ready == 1'b1) begin
						fake_if0_send_start <= 1'b1;
						fake_if0_state <= STATE_FINISH;
					end
				end
				
				STATE_FINISH: begin
					fake_if0_send_start <= 1'b0;
					if (fake_if0_send_done == 1'b1) begin
						fake_if0_state <= STATE_READ;
					end
				end

				STATE_RESET: begin
					fake_if0_send_start <= 1'b0;
					fake_if0_keep_alive <= 1'b0;

					fake_if0_send_data <= 0;
					
					fake_if0_state <= STATE_READ;
				end
				
				// this should never occur
				default: begin
					fake_if0_state <= STATE_RESET;
				end
				
			endcase
		end
	end

	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			fake_if1_state <= STATE_RESET;
		end
		
		else begin
			case (fake_if1_state)
				
				STATE_READ: begin
					if (if0_recv_new_data == 1'b1) begin
						case (mode)
							
							MODE_FORWARD: begin
								fake_if1_state <= STATE_READ;
							end
							
							MODE_SUB0_BLOCK1: begin
								fake_if1_state <= STATE_READ;
							end
						
							MODE_SUB1_BLOCK0: begin
								fake_if1_send_data <= 'h24;	// $ sign
								fake_if1_state <= STATE_WRITE;
							end
							
							MODE_ROT_13: begin
								// for A-M,a-m we rotate by +13
								if ((real_if0_recv_data >= 65 && real_if0_recv_data <= 77) || (real_if0_recv_data >= 97 && real_if0_recv_data <= 109)) begin
									fake_if1_send_data <= real_if0_recv_data + 13;
								end
								// for N-Z,n-z we rotate by -13 (+13 == -13 mod 26)
								else if ((real_if0_recv_data >= 78 && real_if0_recv_data <= 90) || (real_if0_recv_data >= 110 && real_if0_recv_data <= 122)) begin
									fake_if1_send_data <= real_if0_recv_data - 13;
								end
								// else don't rotate
								else begin
									fake_if1_send_data <= real_if0_recv_data;
								end
								
								fake_if1_state <= STATE_WRITE;
							end
						endcase
					end
				end
				
				STATE_WRITE: begin
					if (fake_if1_send_ready == 1'b1) begin
						fake_if1_send_start <= 1'b1;
						fake_if1_state <= STATE_FINISH;
					end
				end
				
				STATE_FINISH: begin
					fake_if1_send_start <= 1'b0;
					if (fake_if1_send_done == 1'b1) begin
						fake_if1_state <= STATE_READ;
					end
				end

				STATE_RESET: begin
					fake_if1_send_start <= 1'b0;
					fake_if1_keep_alive <= 1'b0;

					fake_if1_send_data <= 0;
					
					fake_if1_state <= STATE_READ;
				end
				
				// this should never occur
				default: begin
					fake_if1_state <= STATE_RESET;
				end
				
			endcase
		end
	end

endmodule