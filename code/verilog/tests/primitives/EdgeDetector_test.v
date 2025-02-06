/**
 * Simulation of Edge detector module.
**/

// define timescale
`timescale 1 ns / 10 ps

module EdgeDetector_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 20_000;	// 20 us
	
	localparam FALL_EDGE = 1;
	
	// test signals
	wire edge_sig;
	
	// test registers
	reg sys_clk = 1'b0;
	reg sig = 1'b0;
	
	// helper variables
	integer i;
	
	// instantiate uut
	EdgeDetector #(
		.FALL_EDGE(FALL_EDGE)
	) UUT (
		.sys_clk(sys_clk),
		.sig(sig),
		.edge_sig(edge_sig)
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
	
		// wait some time for initialization
		#(2*CLK_PERIOD_NS);
		
		// generate rising edge
		sig = 1'b1;
		
		// wait for at least 3 sys_clk periods
		#(CLK_PERIOD_NS * 3);
		
		// generate falling edge
		sig = 1'b0;
		
		// wait for at least 3 sys_clk periods
		#(CLK_PERIOD_NS * 3);
		
		#50; // create a small phase shift
		for (i = 0; i < 20; i++)
		begin
			// generate clock signal on signal line
			sig = ~sig;
			#(CLK_PERIOD_NS * 3 + 100);
		end
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("EdgeDetector_test.vcd");
		$dumpvars(0, EdgeDetector_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule