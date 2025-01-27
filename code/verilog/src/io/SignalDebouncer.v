/**
 * Signal debouncer module:
 * - signal debouncer with internal synchronisation registers
 * - input signal may be asynchronous to system clock
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
	reg sync1 = (IN_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;
	reg sync2 = (IN_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;
	reg sync3 = (IN_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;
	reg [CTR_SIZE-1:0] ctr;
	reg last_active = 1'b0;
	
	always @ (posedge sys_clk)
	begin
		
		// shift signal through synchronization registers
		sync1 <= in_sig;
		sync2 <= sync1;
		sync3 <= sync2;
		
		// if any edge is detected on signal, reset counter, set output to inactive
		if (sync3 ^ sync2 == 1'b1) begin
			out_sig <= (OUT_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;;
			ctr <= 0;
		end
		
		// if counter reached max, pulse output signal active iff 1) input is active, and 2) last time counter reached max, signal was inactive
		else if (ctr == CTR_MAX) begin
			out_sig <= (IN_ACTIVE_LOW == OUT_ACTIVE_LOW) ? ~last_active & sync3 : ~last_active & ~sync3;
			last_active <= (IN_ACTIVE_LOW == 1) ? ~sync3 : sync3;
			ctr <= 0;
		end
		
		// else set output to inactive and increment counter
		else begin
			out_sig <= (OUT_ACTIVE_LOW == 1) ? 1'b1 : 1'b0;
			ctr <= ctr + 1;
		end
	end
	
endmodule
	