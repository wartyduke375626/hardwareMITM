/**
 * Serial data read buffer:
 * - buffers BUF_SIZE bits of data reading from a serial line, synchronizing on read signals
 * - the read signal must be synchronous to the system clock
**/

module SerialReadBuffer # (

	// parameters
	parameter	BUF_SIZE = 8
) (
	
	// inputs
	input		sys_clk,
	input		rst,
	input		start,
	input		read_sig,
	input		data_in,
	
	// outputs
	output	reg	[BUF_SIZE-1:0]	data_out = 0,
	output	reg					busy = 1'b0,
	output	reg					data_ready = 1'b0
);

	// local constants
	localparam	CTR_SIZE = $clog2(BUF_SIZE+1); // storing A requires exactly ceil(lg(A+1)) bits, max buf_ctr value is BUF_SIZE

	// states
	localparam	STATE_IDLE	= 2'd0;
	localparam	STATE_READ	= 2'd1;
	localparam	STATE_DONE	= 2'd2;
	localparam	STATE_RESET	= 2'd3;
	
	// internal registers
	reg	[1:0]			state = STATE_RESET;
	reg [BUF_SIZE-1:0]	read_buf = 0;
	reg	[CTR_SIZE-1:0]	buf_ctr = 0;
	
	always @ (posedge sys_clk or posedge rst)
	begin
		// on reset signal busy, invalidate data and go to reset state
		if (rst == 1'b1) begin
			busy <= 1'b1;
			data_ready <= 1'b0;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for start signal
				STATE_IDLE: begin
					if (start == 1'b1) begin
						busy <= 1'b1;
						data_ready <= 1'b0;
						state <= STATE_READ;
					end
				end
				
				// main buffering state
				STATE_READ: begin
					// if buffer is full go to next state
					if (buf_ctr == BUF_SIZE) begin
						data_out <= read_buf;
						data_ready <= 1'b1;
						state <= STATE_DONE;
					end
					
					// else read next bit on edge signal
					else if (read_sig == 1'b1) begin
						read_buf <= {read_buf[BUF_SIZE-2:0], data_in}; // left shift next data bit
						buf_ctr <= buf_ctr + 1;
					end
				end
				
				// prepare internal state for next buffering
				STATE_DONE: begin
					read_buf <= 0;
					buf_ctr <= 0;
					busy <= 1'b0;
					state <= STATE_IDLE;
				end
				
				// reset internal state
				STATE_RESET: begin
					data_ready <= 1'b0;
					data_out <= 0;
					read_buf <= 0;
					buf_ctr <= 0;
					busy <= 1'b0;
					state <= STATE_IDLE;
				end
				
			endcase
		end
	end
	
endmodule