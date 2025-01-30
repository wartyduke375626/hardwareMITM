/**
 * Serial data write buffer:
 * - writes n bits of data to a serial line from internal buffer, synchronizing on write signals
 * - the number of bits can be controlled dynamically with the write_count input
 * - the write signal must be synchronous to the system clock
 * - BUF_SIZE is the maximum number of bits which can be buffered
 * - the first bit will be written to the output line when the start signal is triggered
 * - each consecutive write signal causes the next bit to be written
 * - once the last bit has been written, it is maintained on the output line until the next write signal, which terminates writing
 * - by default, bits are left-shifted from the buffer, meaning bits are written most significant bit first
 * - if LSB_FISRT is set to 1, bits are right-shifted instead (i.e. least significant bit is written first) 
 * - if n < BUF_SIZE, the remaining BUF_SIZE-n bits in data_in are ignored and not written
 * - the position of the ignored bits depends whether the bits are left-shifted or right-shifted
 * - the ACTVE_LOW parameter determines the passive state of the output line (out_line)
**/

module SerialWriteBuffer #(

	// parameters
	parameter BUF_SIZE = 8,
	parameter LSB_FIRST = 0,
	parameter ACTIVE_LOW = 0
) (
	
	// inputs
	input wire sys_clk,
	input wire rst,
	input wire start,
	input wire write_sig,
	input wire [BUF_SIZE-1:0] data_in,
	input wire [CTR_SIZE-1:0] write_count,
	
	// outputs
	output reg out_line = (ACTIVE_LOW == 0) ? 1'b0 : 1'b1,
	output reg done_sig = 1'b0
);

	// local constants
	localparam CTR_SIZE = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits

	// states
	localparam STATE_IDLE = 2'd0;
	localparam STATE_WRITE = 2'd1;
	localparam STATE_RESET = 2'd2;
	
	// internal registers
	reg [1:0] state = STATE_RESET;
	reg [BUF_SIZE-2:0] write_buf;	// we don't need to store the first bit as it is output immediately when start signal triggers
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
						out_line <= (LSB_FIRST == 0) ? data_in[BUF_SIZE-1] : data_in[0];	// write first bit (msb)
						write_buf <= (LSB_FIRST == 0) ? data_in[BUF_SIZE-2:0] : data_in[BUF_SIZE-1:1];	// copy the rest in internal buffer
						ctr <= write_count - 1;	// now we need to write the remaining write_count - 1 bits
						state <= STATE_WRITE;
					end
				end
				
				// buffering state
				STATE_WRITE: begin
					// on write signal change output
					if (write_sig == 1'b1) begin
						// if all bits have been written, clear output, signal done and go to idle state
						if (ctr == 0) begin
							done_sig <= 1'b1;
							out_line <= (ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
							state <= STATE_IDLE;
						end
					
						// else write next bit
						else begin
							out_line <= (LSB_FIRST == 0) ? write_buf[BUF_SIZE-2] : write_buf[0]; // write next bit
							write_buf <= (LSB_FIRST == 0) ? write_buf << 1 : write_buf >> 1;	// shift buffer
							ctr <= ctr - 1;
						end
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					out_line <= (ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
					write_buf <= 0;
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