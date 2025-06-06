/**
 * Signal debouncer module:
 * - signal debouncer with internal synchronisation registers
 * - input signal must be syncrhonous to system clock
 * - debounces signal pulses by sampling the signal at slower rates
 * - if input signal is detected to be in active state, generates one output active pulse synchronous to the system clock
 * - sampling rate is determined by system clock frequency / DEBOUNCE_COUNT parameter
 * - IN_ACTIVE_LOW parameter determines input signal polarity
 * - OUT_ACTIVE_LOW parameter determines output pulse polarity
**/

module SignalDebouncer #(

	// parameters
	parameter DEBOUNCE_COUNT = 65_536,
	parameter IN_ACTIVE_LOW = 1,
	parameter OUT_ACTIVE_LOW = 0
) (

	// inputs
	input wire sys_clk,
	input wire in_sig,
	
	// outputs
	output reg out_sig = (OUT_ACTIVE_LOW == 1) ? 1'b1 : 1'b0
);

	// local constants
	localparam CTR_MAX = DEBOUNCE_COUNT - 1;
	localparam CTR_SIZE = $clog2(CTR_MAX+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal registers
	reg old_sig = (IN_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;
	reg [CTR_SIZE-1:0] ctr;
	reg last_active = 1'b0;
	
	always @ (posedge sys_clk)
	begin
		
		// sample and save old signal value for edge detection
		old_sig <= in_sig;
		
		// if any edge is detected on signal, reset counter, set output to inactive
		if (old_sig ^ in_sig == 1'b1) begin
			out_sig <= (OUT_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;;
			ctr <= 0;
		end
		
		// if counter reached max, pulse output signal active iff 1) input is active, and 2) last time counter reached max, signal was inactive
		else if (ctr == CTR_MAX) begin
			out_sig <= (IN_ACTIVE_LOW == OUT_ACTIVE_LOW) ? ~last_active & in_sig : ~last_active & ~in_sig;
			last_active <= (IN_ACTIVE_LOW == 1) ? ~in_sig : in_sig;
			ctr <= 0;
		end
		
		// else set output to inactive and increment counter
		else begin
			out_sig <= (OUT_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;
			ctr <= ctr + 1;
		end
	end
	
endmodule
	