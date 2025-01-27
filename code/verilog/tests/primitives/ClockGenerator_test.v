/**
 * Simulation of Clock signal generator module.
**/

// define timescale
`timescale 1 ns / 10 ps

module ClockGenerator_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 10_000;	// 10 us
	
	localparam DIV_FACTOR = 12;
	localparam CYCLE_COUNT = 8;
	localparam ACTIVE_LOW = 0;
	
	// internal signals
	wire out_clk;
	wire busy;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	reg start = 1'b0;
	
	// instantiate uut
	ClockGenerator #(
		.DIV_FACTOR(DIV_FACTOR),
		.CYCLE_COUNT(CYCLE_COUNT),
		.ACTIVE_LOW(ACTIVE_LOW)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(start),
		.out_clk(out_clk),
		.busy(busy)
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
		
		// wait while clock generator is busy
		wait (busy == 1'b0);
		
		// send signal to start reading byte
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// generate random reset signal
		#3172;
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
		
		// wait while clock generator is busy
		wait (busy == 1'b0);
		
		// send signal to start reading byte 2
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait while clock generator is busy
		wait (busy == 1'b0);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("ClockGenerator_test.vcd");
		$dumpvars(0, ClockGenerator_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule