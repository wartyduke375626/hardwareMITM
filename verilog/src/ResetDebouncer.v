/**
 * Reset signal debouncer module:
 * - dedicated reset signal debouncer with internal synchronisation registers
 * - reset pulses may be asynchronous to system clock
 * - debounces reset pulses by sampling the signal at slower rates
 * - sampling rate is determined by system clock frequency / DEBOUNCE_COUNT parameter
 * - ACTIVE_LOW parameter determines input reset signal polarity
 * - output polarity is active-high
**/

module ResetDebouncer #(

	// parameters
	parameter DEBOUNCE_COUNT = 65_536,
	parameter ACTIVE_LOW = 1
) (

	// inputs
	input wire sys_clk,
	input wire in_sig,
	
	// outputs
	output reg rst_sig = 1'b0
);

	// local constants
	localparam CTR_MAX = DEBOUNCE_COUNT - 1;
	localparam CTR_SIZE = $clog2(CTR_MAX+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal registers
	reg sync1 = 1'b0;
	reg sync2 = 1'b0;
	reg sync3 = 1'b0;
	reg [CTR_SIZE-1:0] ctr;
	
	always @ (posedge sys_clk)
	begin
		
		// shift signal through synchronization registers
		sync1 <= in_sig;
		sync2 <= sync1;
		sync3 <= sync2;
		
		// if any edge is detected on signal, reset counter and sample again
		if (sync3 ^ sync2 == 1'b1) begin
			rst_sig <= 0;
			ctr <= 0;
		end
		
		// if counter reached max, pulse reset signal for one clock cycle if detected
		else if (ctr == CTR_MAX) begin
			rst_sig <= (ACTIVE_LOW == 1) ? ~sync3 : sync3;
			ctr <= 0;
		end
		
		// else increment counter
		else begin
			rst_sig <= 0;
			ctr <= ctr + 1;
		end
	end
	
endmodule
	