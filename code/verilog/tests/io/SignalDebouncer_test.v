/**
 * Simulation of Signal debouncer module.
**/

// define timescale
`timescale 1 ns / 10 ps

module SignalDebouncer_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 30_000;	// 30 us
	
	localparam DEBOUNCE_COUNT = 16;
	localparam IN_ACTIVE_LOW = 1;
	localparam OUT_ACTIVE_LOW = 0;
	
	// test signals
	wire out_sig;
	
	// test registers
	reg sys_clk = 1'b0;
	reg in_sig = 1'b1;
	
	// helper task to simulate noisy random signal
	task gen_noisy_signal();
		integer n;
		integer i;
		
		// noisy signal bounces
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			in_sig = ~in_sig;
			#($urandom % 100);
		end
	endtask
	
	// instantiate uut
	SignalDebouncer #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT),
		.IN_ACTIVE_LOW(IN_ACTIVE_LOW),
		.OUT_ACTIVE_LOW(OUT_ACTIVE_LOW)
	) UUT (
		.sys_clk(sys_clk),
		.in_sig(in_sig),
		.out_sig(out_sig)
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
		
		// noisy signal
		gen_noisy_signal();
		// set real signal value
		in_sig = 1'b0;
		
		// wait some time for next signal
		#(5 * CLK_PERIOD_NS * DEBOUNCE_COUNT + 1234);
		
		// noisy signal
		gen_noisy_signal();
		// set real signal value
		in_sig = 1'b1;
		
		// wait some time for next signal
		#(5 * CLK_PERIOD_NS * DEBOUNCE_COUNT + 2431);
		
		// noisy signal
		gen_noisy_signal();
		// set real signal value
		in_sig = 1'b0;
		
		// wait some time for next signal
		#(5 * CLK_PERIOD_NS * DEBOUNCE_COUNT + 987);
		
		// noisy signal
		gen_noisy_signal();
		// set real signal value
		in_sig = 1'b1;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("SignalDebouncer_test.vcd");
		$dumpvars(0, SignalDebouncer_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule