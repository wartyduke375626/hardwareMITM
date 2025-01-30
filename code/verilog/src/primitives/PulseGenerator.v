/**
 * Pulse signal generator module:
 * - generates a pulsing signal on the output line
 * - waits for a start signal, after which generates a periodig signal for CYCLE_COUNT cycles, then returns to passive state (logic 0)
 * - when ACTIVE_LOW parameter is set, passive state is logic 1 instead
 * - the CYCLE_LEN parameter specifies the duration of one cycle in system clock cycles (effectivelly a division factor)
 * - the PULSE_LEN parameter specifies the duration of the active signal pulse (again in system clock cycles)
 * - the DELAY parameter specifies a delay between the start of a cycle and the pulse (again in system clock cycles)
 * - CYCLE_LEN >= DELAY + PULSE_LEN
**/

module PulseGenerator #(

	// parameters
	parameter CYCLE_COUNT = 8,
	parameter CYCLE_LEN = 12,
	parameter PULSE_LEN = 1,
	parameter DELAY = 0,
	parameter ACTIVE_LOW = 0
) (

	// inputs
	input wire sys_clk,
	input wire rst,
	input wire start,
	
	// outputs
	output reg out_sig = (ACTIVE_LOW == 0) ? 1'b0 : 1'b1,
	output reg done_sig = 1'b0
);

	// local constants
	localparam CYCLE_CTR_SIZE = $clog2(CYCLE_COUNT+1);	// storing A requires exactly ceil(lg(A+1)) bits
	localparam PULSE_CTR_MAX = CYCLE_LEN - 1;	// we count 0, 1, ..., CYCLE_LEN-1
	localparam PULSE_CTR_SIZE = $clog2(PULSE_CTR_MAX+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// states
	localparam STATE_IDLE = 2'd0;
	localparam STATE_PULSE = 2'd1;
	localparam STATE_RESET = 2'd2;

	// internal registers
	reg [1:0] state = STATE_RESET;
	reg [CYCLE_CTR_SIZE-1:0] cycle_ctr = 0;
	reg [PULSE_CTR_SIZE-1:0] pulse_ctr = 0;

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
						state <= STATE_PULSE;
					end
				end
				
				// main pulse generation state
				STATE_PULSE: begin
					// if all cycles were generated output passive clock level and signal done
					if (cycle_ctr == CYCLE_COUNT) begin
						out_sig <= (ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
						cycle_ctr <= 0;
						pulse_ctr <= 0;
						done_sig <= 1'b1;
						state <= STATE_IDLE;
					end
					
					else begin
						
						// if pulse counter reached max, reset it and increment cycle counter
						if (pulse_ctr == PULSE_CTR_MAX) begin
							pulse_ctr <= 0;
							cycle_ctr <= cycle_ctr + 1;
						end
						
						// else increment pulse counter
						else begin
							pulse_ctr <= pulse_ctr + 1;
						end
						
						// set the output according to the value of pulse counter
						if (pulse_ctr >= DELAY && pulse_ctr < DELAY + PULSE_LEN) begin
							out_sig <= (ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
						end
						else begin
							out_sig <= (ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
						end
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					cycle_ctr <= 0;
					pulse_ctr <= 0;
					out_sig <= (ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
					done_sig <= 1'b1;
					state <= STATE_IDLE;
				end
				
			endcase
			
		end
	end
	
endmodule

			