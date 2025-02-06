/**
 * Simulation of Pulse signal generator module.
**/

// define timescale
`timescale 1 ns / 10 ps

module PulseGenerator_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 30_000;	// 30 us

	localparam CYCLE_COUNT = 6;
	localparam CYCLE_LEN = 8;
	localparam PULSE_LEN = 1;
	localparam DELAY = 7;
	localparam ACTIVE_LOW = 0;
	
	// test signals
	wire out_sig;
	wire done_sig;
	
	// test registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	reg start = 1'b0;
	
	// instantiate uut
	PulseGenerator #(
		.CYCLE_COUNT(CYCLE_COUNT),
		.CYCLE_LEN(CYCLE_LEN),
		.PULSE_LEN(PULSE_LEN),
		.DELAY(DELAY),
		.ACTIVE_LOW(ACTIVE_LOW)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(start),
		.out_sig(out_sig),
		.done_sig(done_sig)
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
		#100;
		
		// send reset signal at the beginning
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
	
		// wait some time for initialization
		#(2*CLK_PERIOD_NS);
		
		// send signal to start generating clock
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait while signal generator is busy
		wait (done_sig == 1'b1);
		
		// wait some time
		#2000;
		
		// send signal to start generating signal
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// generate random reset signal
		#3172;
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
		
		// wait while signal generator is busy
		wait (done_sig == 1'b1);
		
		// wait some time
		#2000;
		
		// send signal to start generating signal
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait while signal generator is busy
		wait (done_sig == 1'b1);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("PulseGenerator_test.vcd");
		$dumpvars(0, PulseGenerator_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule