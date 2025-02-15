/**
 * Simulation of Counter module.
**/

// define timescale
`timescale 1 ns / 10 ps

module Counter_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 10_000;	// 10 us

	localparam MAX_N = 9;
	localparam CTR_SIZE = $clog2(MAX_N+1);
	
	// test signals
	wire [CTR_SIZE-1:0] ctr_val;
	wire done_sig;
	
	// test registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	reg start = 1'b0;
	reg [CTR_SIZE-1:0] n_val = 0;
	
	// instantiate uut
	Counter #(
		.MAX_N(MAX_N)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(start),
		.n_val(n_val),
		.ctr_val(ctr_val),
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
		
		// send signal to start counting
		n_val = 7;
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait while counter is busy
		wait (done_sig == 1'b1);
		
		// wait some time
		#2000;
		
		// send signal to start counting
		n_val = 9;
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// generate random reset signal
		#1172;
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
		
		// wait while counter is busy
		wait (done_sig == 1'b1);
		
		// wait some time
		#2000;
		
		// send signal to start counting
		n_val = 3;
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait while counter is busy
		wait (done_sig == 1'b1);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("Counter_test.vcd");
		$dumpvars(0, Counter_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule