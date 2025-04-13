/**
 * I/O handler module:
 * - processes external inputs and generates user input signals for MITM logic module
 * - external inputs may be asynchronous
 * - generates external output signals based on MITM logic state
 * - DEBOUNCE_LEN_US is the duration (in us) for which a button input signal must be stable before detecting it
**/

module IoHandler #(

	// parameters
	parameter NUM_MITM_MODES = 4,
	parameter BUTTONS_ACTIVE_LOW = 1,
	parameter DEBOUNCED_RST_ACTIVE_LOW = 0,
	parameter SYS_FREQ_HZ = 12_000_000,
	parameter DEBOUNCE_LEN_US = 1_000
) (

	// inputs
	input wire sys_clk,
	
	input wire rst_btn,
	input wire mode_select_btn,
	input wire comm_active,
	
	// outputs
	output wire debounced_rst,
	output reg [NUM_MITM_MODES-1:0] mode_select = 1,
	output wire [NUM_MITM_MODES-1:0] mode_leds,
	output wire comm_active_led
);
	
	// local constants
	localparam DEBOUNCE_COUNT = DEBOUNCE_LEN_US * (SYS_FREQ_HZ / 1_000_000);

	// internal signals
	wire sync_rst;
	wire sync_mode_select;
	
	wire debounced_mode_select;
	
	assign mode_leds = mode_select;
	
	assign comm_active_led = comm_active;

	always @ (posedge sys_clk)
	begin
		// if button is pressed select next mode (cyclic left shift)
		if (debounced_mode_select == 1'b1) begin
			mode_select <= {mode_select[NUM_MITM_MODES-2:0], mode_select[NUM_MITM_MODES-1]};
		end
	end
	
	/******************** MODULE INSTANTIATION ********************/
	
	Synchronizer #(
		.WIDTH(2)
	) btnSynchronizer (
		.sys_clk(sys_clk),
		.in_line({rst_btn, mode_select_btn}),
		.out_line({sync_rst, sync_mode_select})
	);
	
	SignalDebouncer #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT),
		.IN_ACTIVE_LOW(BUTTONS_ACTIVE_LOW),
		.OUT_ACTIVE_LOW(0)
	) modeSelectDebouncer (
		.sys_clk(sys_clk),
		.in_sig(sync_mode_select),
		.out_sig(debounced_mode_select)
	);
	
	SignalDebouncer #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT),
		.IN_ACTIVE_LOW(BUTTONS_ACTIVE_LOW),
		.OUT_ACTIVE_LOW(DEBOUNCED_RST_ACTIVE_LOW)
	) rstDebouncer (
		.sys_clk(sys_clk),
		.in_sig(sync_rst),
		.out_sig(debounced_rst)
	);
	
	/******************** ******************** ********************/

endmodule