/**
 * Simulation of I/O handler module.
**/

// define timescale
`timescale 1 ns / 10 ps

module IoHandler_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 30_000;	// 30 us
	
	localparam MODE_WIDTH = 4;
	localparam BUTTON_ACTIVE_LOW = 1;
	localparam DEBOUNCE_COUNT = 16;
	
	// internal signals
	wire [MODE_WIDTH-1:0] mode_select;
	wire [MODE_WIDTH-1:0] mode_leds;
	wire comm_active_led;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg mode_select_btn = 1'b1;

	reg comm_active = 1'b0;
	
	// helper variables
	integer i;
	integer n;

	// instantiate uut
	IoHandler #( 
		.MODE_WIDTH(MODE_WIDTH),
		.BUTTON_ACTIVE_LOW(BUTTON_ACTIVE_LOW),
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT)
	) UUT (
		.sys_clk(sys_clk),
		.mode_select_btn(mode_select_btn),
		.comm_active(comm_active),
		.mode_select(mode_select),
		.mode_leds(mode_leds),
		.comm_active_led(comm_active_led)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// test code
	initial
	begin
		// wait some time
		#1000;
	
		// generate noisy random button bounces
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			mode_select_btn = ~mode_select_btn;
			#($urandom % 100);
		end
		// set button pressed
		mode_select_btn = 1'b0;
		
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 500);
		
		// generate noisy random button bounces
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			mode_select_btn = ~mode_select_btn;
			#($urandom % 100);
		end
		// set button released
		mode_select_btn = 1'b1;
		
		
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 123);
		// set button pressed
		mode_select_btn = 1'b0;
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 498);
		// set button released
		mode_select_btn = 1'b1;
		
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 258);
		// set button pressed
		mode_select_btn = 1'b0;
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 1235);
		// set button released
		mode_select_btn = 1'b1;
		
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 1222);
		// set button pressed
		mode_select_btn = 1'b0;
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 973);
		// set button released
		mode_select_btn = 1'b1;
		
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 2001);
		// set button pressed
		mode_select_btn = 1'b0;
		// wait some time
		#(CLK_PERIOD_NS * DEBOUNCE_COUNT + 1258);
		// set button released
		mode_select_btn = 1'b1;
		
		// test comm_active LED
		comm_active = 1'b1;
		#(4 * CLK_PERIOD_NS);
		comm_active = 1'b0;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("IoHandler_test.vcd");
		$dumpvars(0, IoHandler_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule