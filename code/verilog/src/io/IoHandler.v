/**
 * I/O handler module:
 * - processes external inputs and generates user input signals for MITM logic module
 * - external inputs may be asynchronous
 * - generates external output signals based on MITM logic state
**/

module IoHandler #(

	// parameters
	parameter MODE_WIDTH = 3,
	parameter BUTTON_ACTIVE_LOW = 1,
	parameter DEBOUNCE_COUNT = 65_536
) (

	// inputs
	input wire sys_clk,
	
	input wire mode_select_btn,
	input wire comm_active,
	
	// outputs
	output reg [MODE_WIDTH-1:0] mode_select = 1,
	output wire [MODE_WIDTH-1:0] mode_leds,
	
	output wire comm_active_led
);
	
	// local constants
	localparam DEBOUNCED_ACTIVE_LOW = 0;

	// internal signals
	wire debounced_btn;
	
	assign mode_leds = mode_select;
	
	assign comm_active_led = comm_active;

	always @ (posedge sys_clk)
	begin
		// if button is pressed select next mode (cyclic left shift)
		if (debounced_btn == 1'b1) begin
			mode_select <= {mode_select[MODE_WIDTH-2:0], mode_select[MODE_WIDTH-1]};
		end
	end
	
	/******************** MODULE INSTANTIATION ********************/
	
	SignalDebouncer #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT),
		.IN_ACTIVE_LOW(BUTTON_ACTIVE_LOW),
		.OUT_ACTIVE_LOW(DEBOUNCED_ACTIVE_LOW)
	) btnDebouncer (
		.sys_clk(sys_clk),
		.in_sig(mode_select_btn),
		.out_sig(debounced_btn)
	);
	
	/******************** ******************** ********************/

endmodule