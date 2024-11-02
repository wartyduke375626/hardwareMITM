/**
 * Main MITM logic module:
 * - generates output data based on input data
 * - decides wether to output real and fake data
**/

module MitmLogic # (

	// parameters
	parameter	DATA_SIZE = 8
) (

	// inputs
	input					sys_clk,
	input					rst,
	input					eval,
	input	[DATA_SIZE-1:0] real_miso_data,
	input	[DATA_SIZE-1:0] real_mosi_data,
	
	// outputs
	output	reg	[DATA_SIZE-1:0] fake_miso_data,
	output	reg	[DATA_SIZE-1:0] fake_mosi_data,
	output	reg					fake_miso_select,
	output	reg					fake_mosi_select,
	output	reg					done_sig = 1'b0
	
);

	// states
	localparam	STATE_IDLE	= 2'd0;
	localparam	STATE_MITM	= 2'd1;
	localparam	STATE_RESET	= 2'd2;
	
	// internal registers
	reg	[1:0]			state = STATE_RESET;

	always @ (posedge sys_clk or posedge rst)
	begin
		// on reset signal busy and go to reset state
		if (rst == 1'b1) begin
			done_sig <= 1'b0;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for eval signal
				STATE_IDLE: begin
					if (eval == 1'b1) begin
						done_sig <= 1'b0;
						state <= STATE_MITM;
					end
				end
				
				// MITM logic state
				STATE_MITM: begin
					// set MOSI to forward mode
					fake_mosi_select <= 1'b0;
					fake_mosi_data <= 0;
					
					// forward MOSI data on MISO line as well
					fake_miso_select <= 1'b1;
					fake_miso_data <= real_mosi_data;
					
					// signal done
					done_sig <= 1'b1;
					state <= STATE_IDLE;
				end
				
				// reset internal state
				STATE_RESET: begin
					fake_miso_data <= 0;
					fake_mosi_data <= 0;
					fake_miso_select <= 1'b0;
					fake_mosi_select <= 1'b0;
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