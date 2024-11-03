/**
 * Simulation of Debouncer module.
**/

// define timescale
`timescale 1 ns / 10 ps

module Debouncer_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 50_000;	// 50 us
	
	localparam DEBOUNCE_COUNT = 16;
	
	// internal signals
	wire out_sig;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	reg in_sig = 1'b0;
	
	// helper variables
	integer i;
	integer n;
	
	// instantiate uut
	Debouncer #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.in_sig(in_sig),
		.out_sig(out_sig)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// pulse reset line high at the begining
	initial
	begin
		#10;
		rst = 1'b1;
		#1;
		rst = 1'b0;
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
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("Debouncer_test.vcd");
		$dumpvars(0, Debouncer_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule