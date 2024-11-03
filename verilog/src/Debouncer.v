/**
 * Signal logic debouncer module:
 * - debounces input signal by sampling the signal at slower rates
 * - sampling rate is determined by system clock frequency / DEBOUNCE_COUNT parameter
 * - signal must be synchronous to system clock
**/

module Debouncer #(

	// parameters
	parameter DEBOUNCE_COUNT = 65_536
) (

	// inputs
	input wire sys_clk,
	input wire rst,
	input wire in_sig,
	
	// outputs
	output reg out_sig = 1'b0
);

	// local constants
	localparam CTR_MAX = DEBOUNCE_COUNT - 1;
	localparam CTR_SIZE = $clog2(CTR_MAX+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal registers
	reg old_sig = 1'b0;
	reg [CTR_SIZE-1:0] ctr;
	
	always @ (posedge sys_clk or posedge rst)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			old_sig <= 1'b0;
			out_sig <= 1'b0;
			ctr <= 0;
		end
		
		else begin
			// shift signal through synchronization registers
			old_sig <= in_sig;
			
			// if any edge is detected on signal, reset counter and sample again
			if (old_sig ^ in_sig == 1'b1) begin
				ctr <= 0;
			end
			
			// if counter reached max, reset counter and output signal value
			else if (ctr == CTR_MAX) begin
				out_sig <= old_sig;
				ctr <= 0;
			end
			
			// else increment counter
			else begin
				ctr <= ctr + 1;
			end
		end
	end
	
endmodule
	