/**
 * Simulation of I/O handler module.
**/

// define timescale
`timescale 1 ns / 10 ps

module IoHandler_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 50_000;	// 50 us
	
	localparam MODE_WIDTH = 4;
	localparam BUTTON_ACTIVE_LOW = 1;
	localparam DEBOUNCE_COUNT = 8;
	
	// test signals
	wire [MODE_WIDTH-1:0] mode_select;
	wire [MODE_WIDTH-1:0] mode_leds;
	wire comm_active_led;
	
	// test registers
	reg sys_clk = 1'b0;
	reg mode_select_btn = 1'b1;
	reg comm_active = 1'b0;
	
	// helper variables
	integer i;
	
	// helper task to simulate noisy button presses
	task simulate_noisy_btn_press();
		integer n;
		integer i;
		
		// noisy signal bounces
		n = $urandom % 30;
		for (i = 0; i < n; i++)
		begin
			mode_select_btn = ~mode_select_btn;
			#($urandom % 100);
		end
		
		// actual button pressed
		mode_select_btn = (BUTTON_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(DEBOUNCE_COUNT * CLK_PERIOD_NS + $urandom % 500 + 100);
		
		// noisy signal bounces
		n = $urandom % 30;
		for (i = 0; i < n; i++)
		begin
			mode_select_btn = ~mode_select_btn;
			#($urandom % 100);
		end
		
		// button released
		mode_select_btn = (BUTTON_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		#(DEBOUNCE_COUNT * CLK_PERIOD_NS + $urandom % 500 + 100);
	endtask

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
	
		// generate noisy random button presses
		for (i = 0; i < 9; i++)
		begin
			simulate_noisy_btn_press();
		end
		
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