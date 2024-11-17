/**
 * Synchronizer module:
 * - synchronizes changes on input lines to the system clock
 * - inputs are organized in a WIDTH wide line
**/

module Synchronizer #(

	// parameters
	parameter WIDTH = 4
) (

	// inputs
	input wire sys_clk,
	input wire [WIDTH-1:0] in_line,
	
	// outputs
	output wire [WIDTH-1:0] out_line
);

	// internal registers
	reg [WIDTH-1:0] sync1;
	reg [WIDTH-1:0] sync2;
	
	// set last sync register as output
	assign out_line = sync2;
	
	always @ (posedge sys_clk)
	begin
		// shift input through synchronization registers
		sync1 <= in_line;
		sync2 <= sync1;
	end

endmodule