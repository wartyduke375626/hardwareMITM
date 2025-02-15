/**
 * Counter module:
 * - waits for a start signal, then counts from 0 to n-1, then asserts a done signal
 * - MAX_COUNT is the maximum n value, which can be input
**/

module Counter #(

	// parameters
	parameter MAX_N = 64
) (

	// inputs
	input wire sys_clk,
	input wire rst,
	input wire start,
	input wire [CTR_SIZE-1:0] n_val,
	
	// outputs
	output reg [CTR_SIZE-1:0] ctr_val,
	output reg done_sig = 1'b0
);

	// local constants
	localparam CTR_SIZE = $clog2(MAX_N+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// states
	localparam STATE_IDLE = 2'd0;
	localparam STATE_COUNT = 2'd1;
	localparam STATE_RESET = 2'd2;

	// internal registers
	reg [1:0] state = STATE_RESET;
	reg [CTR_SIZE-1:0] ctr_max;

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
						ctr_max <= n_val - 1;	// we count from 0 to n-1
						state <= STATE_COUNT;
					end
				end
				
				// main counting state
				STATE_COUNT: begin
					// if counter reached max, signal done and go to idle state
					if (ctr_val == ctr_max) begin
						ctr_val <= 0;
						ctr_max <= 0;
						done_sig <= 1'b1;
						state <= STATE_IDLE;
					end
					
					// else increase counter
					else begin
						ctr_val <= ctr_val + 1;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					ctr_val <= 0;
					ctr_max <= 0;
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

			