/**
 * Simulation of I/O handler module.
**/

// define timescale
`timescale 1 ns / 10 ps

module IoHandler_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 70_000;	// 70 us
	
	localparam MODE_WIDTH = 4;
	localparam BUTTONS_ACTIVE_LOW = 1;
	localparam DEBOUNCED_RST_ACTIVE_LOW = 0;
	localparam DEBOUNCE_DURATION_US = 1;
	
	// test signals
	wire debounced_rst;
	wire [MODE_WIDTH-1:0] mode_select;
	wire [MODE_WIDTH-1:0] mode_leds;
	wire comm_active_led;
	
	// test registers
	reg sys_clk = 1'b0;
	reg rst_btn = (BUTTONS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	reg mode_select_btn = (BUTTONS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	reg comm_active = 1'b0;
	
	// helper variables
	integer i;
	
	// helper task to simulate noisy button presses
	task simulate_noisy_btn_press(input string btn);
		integer n;
		integer i;
		
		if (btn != "RST" && btn != "MODE") begin
			$error("Invalid button specified.");
		end
		
		// noisy signal bounces
		n = $urandom % 30;
		for (i = 0; i < n; i++)
		begin
			if (btn == "RST") begin rst_btn = ~rst_btn; end
			if (btn == "MODE") begin mode_select_btn = ~mode_select_btn; end
			#($urandom % 100);
		end
		
		// actual button pressed
		if (btn == "RST") begin rst_btn = (BUTTONS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0; end
		if (btn == "MODE") begin mode_select_btn = (BUTTONS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0; end
		#(1_000 * DEBOUNCE_DURATION_US + 3 * CLK_PERIOD_NS + $urandom % 500);
		
		// noisy signal bounces
		n = $urandom % 30;
		for (i = 0; i < n; i++)
		begin
			if (btn == "RST") begin rst_btn = ~rst_btn; end
			if (btn == "MODE") begin mode_select_btn = ~mode_select_btn; end
			#($urandom % 100);
		end
		
		// button released
		if (btn == "RST") begin rst_btn = (BUTTONS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1; end
		if (btn == "MODE") begin mode_select_btn = (BUTTONS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1; end
		#(1_000 * DEBOUNCE_DURATION_US + 3 * CLK_PERIOD_NS + $urandom % 500 + 100);
	endtask

	// instantiate uut
	IoHandler #( 
		.MODE_WIDTH(MODE_WIDTH),
		.BUTTONS_ACTIVE_LOW(BUTTONS_ACTIVE_LOW),
		.DEBOUNCED_RST_ACTIVE_LOW(DEBOUNCED_RST_ACTIVE_LOW),
		.SYS_FREQ_HZ(SYS_CLK),
		.DEBOUNCE_DURATION_US(DEBOUNCE_DURATION_US)
	) UUT (
		.sys_clk(sys_clk),
		.rst_btn(rst_btn),
		.mode_select_btn(mode_select_btn),
		.comm_active(comm_active),
		.debounced_rst(debounced_rst),
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
		
		// generate reset button press
		simulate_noisy_btn_press("RST");
	
		// generate mode select button presses
		for (i = 0; i < 9; i++)
		begin
			simulate_noisy_btn_press("MODE");
		end
		
		// generate reset button press
		simulate_noisy_btn_press("RST");
		
		// test comm_active LED
		comm_active = 1'b1;
		#(4 * CLK_PERIOD_NS);
		comm_active = 1'b0;
		
		// generate reset button press
		simulate_noisy_btn_press("RST");
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