/**
 * Serial data read buffer:
 * - buffers BUF_SIZE bits of data reading from a serial line, synchronizing on read signals
 * - the read signal must be synchronous to the system clock
**/

module SerialReadBuffer # (

	// parameters
	parameter BUF_SIZE = 8
) (
	
	// inputs
	input wire sys_clk,
	input wire rst,
	input wire start,
	input wire read_sig,
	input wire data_in,
	
	// outputs
	output reg [BUF_SIZE-1:0] data_out,
	output reg done_sig = 1'b0
);

	// local constants
	localparam CTR_SIZE = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits, max buf_ctr value is BUF_SIZE

	// states
	localparam STATE_IDLE = 2'd0;
	localparam STATE_READ = 2'd1;
	localparam STATE_RESET = 2'd2;
	
	// internal registers
	reg [1:0] state = STATE_RESET;
	reg [CTR_SIZE-1:0] buf_ctr;
	
	always @ (posedge sys_clk or posedge rst)
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
						buf_ctr <= 0;
						state <= STATE_READ;
					end
				end
				
				// buffering state
				STATE_READ: begin
					// if buffer is full, signal done and go to idle state
					if (buf_ctr == BUF_SIZE) begin
						done_sig <= 1'b1;
						state <= STATE_IDLE;
					end
					
					// else read next bit on read signal
					else if (read_sig == 1'b1) begin
						data_out <= {data_out[BUF_SIZE-2:0], data_in}; // left shift next data bit
						buf_ctr <= buf_ctr + 1;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					data_out <= 0;
					buf_ctr <= 0;
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