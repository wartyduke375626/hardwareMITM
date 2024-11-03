/**
 * Edge detector:
 * - detects rising edges on the signal line
 * - synchronizes edge detection to the system clock
 * - when FALL_EDGE parameter is set detects falling edges instead
**/

module EdgeDetector # (

	// parameters
	parameter FALL_EDGE = 0
) (

	// inputs
	input wire sys_clk,
	input wire rst,
	input wire sig,
	
	// outputs
	output reg edge_sig = 1'b0
);

	// internal registers
	reg sig_sync1 = 1'b0;
	reg sig_sync2 = 1'b0;
	reg old_val = 1'b0;
	reg [1:0] rst_ctr = 2'd0;

	always @ (posedge sys_clk or posedge rst)
	begin
		// reset internal state and output
		if (rst == 1'b1) begin
			sig_sync1 <= 1'b0;
			sig_sync2 <= 1'b0;
			old_val <= 1'b0;
			edge_sig <= 1'b0;
			rst_ctr <= 2'd0;
		end
		
		else begin
			// shift signal input through synchronization registers
			sig_sync1 <= sig;
			sig_sync2 <= sig_sync1;
			
			// save old signal value
			old_val <= sig_sync2;
			
			// after reset we need to wait 3 cycles to stabilize signal
			if (rst_ctr < 2'd3) begin
				rst_ctr <= rst_ctr + 1;
			end
			
			// if signal is stable detect edge
			else begin
				if (FALL_EDGE == 0) begin
					edge_sig <= sig_sync2 && (~old_val);
				end
				else begin
					edge_sig <= (~sig_sync2) && old_val;
				end
			end
		end
	end
	
endmodule