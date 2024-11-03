/**
 * Output multiplexer:
 * - for each of the input bus lines has two inputs and a selector input
 * - each bit of the selector input toggles between the two corresponding BUS line bits
 * - the inputs, outputs and selector bits are organized in WIDTH wide lines
**/

module OutputMux # (

	// parameters
	parameter WIDTH = 4
) (

	// inputs
	input wire [WIDTH-1:0] in_line0,
	input wire [WIDTH-1:0] in_line1,
	input wire [WIDTH-1:0] select_line,
	
	// outputs
	output [WIDTH-1:0] out_line
);

	// multiplexer logic (bitwise selection)
	assign out_line = (~select_line & in_line0) | (select_line & in_line1);

endmodule