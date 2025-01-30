/**
 * Serial data read buffer:
 * - buffers n bits of data reading from a serial line, synchronizing on read signals
 * - the number of bits can be controlled dynamically with the read_count input
 * - the read signal must be synchronous to the system clock
 * - BUF_SIZE is the maximum number of bits which can be buffered
 * - by default, bits are left-shifted into the buffer, meaning bits are read most significant bit first
 * - if LSB_FISRT is set to 1, bits are right-shifted instead (i.e. least significant bit is read first) 
 * - if n < BUF_SIZE, the remaining BUF_SIZE-n bits in data_out are invalid
 * - the position of invalid bits depends whether the bits are left-shifted or right-shifted
**/

module SerialReadBuffer #(

	// parameters
	parameter BUF_SIZE = 8,
	parameter LSB_FIRST = 0
) (
	
	// inputs
	input wire sys_clk,
	input wire rst,
	input wire start,
	input wire read_sig,
	input wire in_line,
	input wire [CTR_SIZE-1:0] read_count,
	
	// outputs
	output reg [BUF_SIZE-1:0] data_out,
	output reg done_sig = 1'b0
);

	// local constants
	localparam CTR_SIZE = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits

	// states
	localparam STATE_IDLE = 2'd0;
	localparam STATE_READ = 2'd1;
	localparam STATE_RESET = 2'd2;
	
	// internal registers
	reg [1:0] state = STATE_RESET;
	reg [CTR_SIZE-1:0] ctr;
	
	always @ (posedge sys_clk)
	begin
		// on reset signal busy and go to reset state
		if (rst == 1'b1) begin
			done_sig <= 1'b0;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for start signal
				STATE_IDLE: begin
					if (start == 1'b1) begin
						done_sig <= 1'b0;
						data_out <= 0;
						ctr <= read_count;
						state <= STATE_READ;
					end
				end
				
				// buffering state
				STATE_READ: begin
					// if all bits have been read, signal done and go to idle state
					if (ctr == 0) begin
						done_sig <= 1'b1;
						state <= STATE_IDLE;
					end
					
					// else read next bit on read signal
					else if (read_sig == 1'b1) begin
						data_out <= (LSB_FIRST == 0) ? {data_out[BUF_SIZE-2:0], in_line} : {in_line, data_out[BUF_SIZE-1:1]};
						ctr <= ctr - 1;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					data_out <= 0;
					ctr <= 0;
					done_sig <= 1'b1;
					state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					done_sig <= 1'b0;
					state <= STATE_RESET;
				end
				
			endcase
		end
	end
	
endmodule