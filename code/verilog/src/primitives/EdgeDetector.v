/**
 * Edge detector:
 * - detects rising edges on the signal line
 * - edges on signal line must be synchronous to the system clock
 * - when FALL_EDGE parameter is set to 1 detects falling edges instead
**/

module EdgeDetector #(

	// parameters
	parameter FALL_EDGE = 0
) (

	// inputs
	input wire sys_clk,
	input wire sig,
	
	// outputs
	output wire edge_sig
);

	// internal registers
	reg old_sig = (FALL_EDGE == 0) ? 1'b1 : 1'b0;
	
	// edge detection logic
	assign edge_sig = (FALL_EDGE == 0) ? (sig & (~old_sig)) : ((~sig) & old_sig);

	always @ (posedge sys_clk)
	begin
		// sample and save old signal value
		old_sig <= sig;
	end

endmodule