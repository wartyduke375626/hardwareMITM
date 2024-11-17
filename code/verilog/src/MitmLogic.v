/**
 * Main MITM logic module:
 * - generates output data based on input data
 * - decides wether to output real and fake data
**/

module MitmLogic (

	// inputs
	input wire sys_clk,
	input wire rst,
	input wire eval,
	input wire mitm_start,
	input wire [MAX_DATA_SIZE-1:0] real_miso_data,
	input wire [MAX_DATA_SIZE-1:0] real_mosi_data,
	
	// outputs
	output reg [MAX_DATA_SIZE-1:0] fake_miso_data,
	output reg [MAX_DATA_SIZE-1:0] fake_mosi_data,
	output reg [DATA_SIZE_WIDTH-1:0] data_size,
	output reg fake_miso_select,
	output reg fake_mosi_select,
	
	output reg eval_done = 1'b0,
	output reg mitm_done = 1'b0
	
);

	// local constants
	localparam MAX_DATA_SIZE = 9;
	localparam DATA_SIZE_WIDTH = $clog2(MAX_DATA_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits

	// states
	localparam STATE_IDLE = 3'd0;
	localparam STATE_MITM_INSTR = 3'd1;
	localparam STATE_MITM_ADDR = 3'd2;
	localparam STATE_MITM_DATA = 3'd3;
	localparam STATE_DONE = 3'd4;
	localparam STATE_RESET = 3'd5;

	// internal registers
	reg [2:0] state = STATE_RESET;

	always @ (posedge sys_clk)
	begin
		// on reset signal busy and go to reset state
		if (rst == 1'b1) begin
			eval_done <= 1'b0;
			mitm_done <= 1'b0;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for MITM start signal
				STATE_IDLE: begin
					if (mitm_start == 1'b1) begin
						mitm_done <= 1'b0;
						state <= STATE_MITM_INSTR;
					end
				end
				
				// when communication starts read instruction (1 start bit + 2 instruction bits)
				STATE_MITM_INSTR: begin
					if (eval == 1'b1) begin
						data_size <= 3;
						fake_miso_select <= 1'b0;
						fake_mosi_select <= 1'b0;
						state <= STATE_MITM_ADDR;
					end
				end
				
				// evaluate if instruction is "read" and read address operand
				STATE_MITM_ADDR: begin
					if (eval == 1'b1) begin
						// if instruction is "read", read address operand
						if (real_mosi_data[2:0] == 3'b110) begin
							data_size <= 9;
							state <= STATE_MITM_DATA;
						end
						
						// else signal MITM done and go to idle state
						else begin
							mitm_done <= 1'b1;
							data_size <= 0;
							state <= STATE_IDLE;
						end
					end
				end
				
				// after address operand, send fake constant on MISO line
				STATE_MITM_DATA: begin
					if (eval == 1'b1) begin
						data_size = 8;
						fake_miso_data <= 8'h24 << 1; // write buffers operate from most significant bit
						fake_miso_select <= 1'b1;
						state <= STATE_DONE;
					end
				end
				
				// after fake data has been sent, signal end of MITM
				STATE_DONE: begin
					if (eval == 1'b1) begin
						mitm_done <= 1'b1;
						data_size <= 0;
						fake_miso_select <= 1'b0;
						fake_mosi_select <= 1'b0;
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					fake_miso_data <= 0;
					fake_mosi_data <= 0;
					data_size <= 0;
					fake_miso_select <= 1'b0;
					fake_mosi_select <= 1'b0;
					mitm_done <= 1'b1;
					eval_done <= 1'b1;
					state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					eval_done <= 1'b0;
					mitm_done <= 1'b0;
					state <= STATE_RESET;
				end
				
			endcase
		end
	end

endmodule