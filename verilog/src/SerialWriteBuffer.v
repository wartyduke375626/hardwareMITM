/**
 * Serial data write buffer:
 * - writes BUF_SIZE bits of data to a serial line from internal buffer, synchronizing on write signals
 * - the write signal must be synchronous to the system clock
 * - the output signal is maintained on the output line until the next write signal
 * - the last bit written remains on the output line until the next writing sequence
**/

module SerialWriteBuffer # (

	// parameters
	parameter	BUF_SIZE = 8
) (
	
	// inputs
	input					sys_clk,
	input					rst,
	input					start,
	input					write_sig,
	input	[BUF_SIZE-1:0]	data_in,
	
	// outputs
	output	reg	data_out = 1'b0,
	output	reg	busy = 1'b0
);

	// local constants
	localparam	CTR_SIZE = $clog2(BUF_SIZE+1); // storing A requires exactly ceil(lg(A+1)) bits, max buf_ctr value is BUF_SIZE

	// states
	localparam	STATE_IDLE	= 2'd0;
	localparam	STATE_WRITE	= 2'd1;
	localparam	STATE_DONE	= 2'd2;
	localparam	STATE_RESET	= 2'd3;
	
	// internal registers
	reg	[1:0]			state = STATE_RESET;
	reg [BUF_SIZE-1:0]	write_buf = 0;
	reg	[CTR_SIZE-1:0]	buf_ctr = 0;
	
	always @ (posedge sys_clk or posedge rst)
	begin
		// on reset signal busy and go to reset state
		if (rst == 1'b1) begin
			busy <= 1'b1;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for start signal
				STATE_IDLE: begin
					if (start == 1'b1) begin
						busy <= 1'b1;
						data_out <= 1'b0;
						write_buf <= data_in;
						state <= STATE_WRITE;
					end
				end
				
				// main buffering state
				STATE_WRITE: begin
					// if buffer is empty go to next state
					if (buf_ctr == BUF_SIZE) begin
						state <= STATE_DONE;
					end
					
					// else write next bit on edge signal
					else if (write_sig == 1'b1) begin
						data_out <= write_buf[BUF_SIZE-1];
						write_buf <= write_buf << 1;
						buf_ctr <= buf_ctr + 1;
					end
				end
				
				// prepare internal state for next buffering
				STATE_DONE: begin
					write_buf <= 0;
					buf_ctr <= 0;
					busy <= 1'b0;
					state <= STATE_IDLE;
				end
				
				// reset internal state
				STATE_RESET: begin
					data_out <= 1'b0;
					write_buf <= 0;
					buf_ctr <= 0;
					busy <= 1'b0;
					state <= STATE_IDLE;
				end
				
			endcase
		end
	end
	
endmodule