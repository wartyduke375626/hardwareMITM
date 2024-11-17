/**
 * Simulation of Reset signal debouncer module.
**/

// define timescale
`timescale 1 ns / 10 ps

module ResetDebouncer_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 50_000;	// 50 us
	
	localparam DEBOUNCE_COUNT = 16;
	localparam ACTIVE_LOW = 1;
	
	// internal signals
	wire rst_sig;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg in_sig = 1'b1;
	
	// helper variables
	integer i;
	integer n;
	
	// instantiate uut
	ResetDebouncer #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT),
		.ACTIVE_LOW(ACTIVE_LOW)
	) UUT (
		.sys_clk(sys_clk),
		.in_sig(in_sig),
		.rst_sig(rst_sig)
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
		// wait some time for initialization
		#1000;
		
		// generate noisy random signal bounces
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			in_sig = ~in_sig;
			#($urandom % 100);
		end
		// set real signal value
		in_sig = 1'b0;
		
		// wait some time for next signal
		#10_000;
		
		// generate noisy random signal bounces
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			in_sig = ~in_sig;
			#($urandom % 100);
		end
		// set real signal value
		in_sig = 1'b1;
		
		// wait some time for next signal
		#10_000;
		
		// generate noisy random signal bounces
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			in_sig = ~in_sig;
			#($urandom % 100);
		end
		// set real signal value
		in_sig = 1'b0;
		
		// wait some time for next signal
		#10_000;
		
		// generate noisy random signal bounces
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			in_sig = ~in_sig;
			#($urandom % 100);
		end
		// set real signal value
		in_sig = 1'b1;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("ResetDebouncer_test.vcd");
		$dumpvars(0, ResetDebouncer_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule