/**
 * Simulation of Synchronizer module.
**/

// define timescale
`timescale 1 ns / 10 ps

module Synchronizer_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 20_000;	// 20 us
	
	localparam WIDTH = 4;
	
	// test signals
	wire [WIDTH-1:0] out_line;
	
	// test registers
	reg sys_clk = 1'b0;
	reg [WIDTH-1:0] in_line = 1'b0;
	
	// instantiate uut
	Synchronizer #(
		.WIDTH(WIDTH)
	) UUT (
		.sys_clk(sys_clk),
		.in_line(in_line),
		.out_line(out_line)
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
		#1000
		
		// generate some low frequency signal on input line
		in_line = 4'hc;
		#(CLK_PERIOD_NS * 4);
		in_line = 4'h1;
		#(CLK_PERIOD_NS * 4);
		in_line = 4'h5;
		#(CLK_PERIOD_NS * 4);
		
		// generate some higher frequency signal on input line
		in_line = 4'h3;
		#(CLK_PERIOD_NS);
		in_line = 4'h9;
		#(CLK_PERIOD_NS);
		in_line = 4'hb;
		#(CLK_PERIOD_NS);
		in_line = 4'h4;
		#(CLK_PERIOD_NS);
		
		// generate very high frewuency signal on input line
		in_line = 4'h3;
		#(CLK_PERIOD_NS / 4);
		in_line = 4'h9;
		#(CLK_PERIOD_NS / 4);
		in_line = 4'hb;
		#(CLK_PERIOD_NS / 4);
		in_line = 4'h4;
		#(CLK_PERIOD_NS / 4);
		in_line = 4'h1;
		#(CLK_PERIOD_NS / 4);
		in_line = 4'h0;
		#(CLK_PERIOD_NS / 4);
		in_line = 4'ha;
		#(CLK_PERIOD_NS / 4);
		in_line = 4'hf;
		#(CLK_PERIOD_NS / 4);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("Synchronizer_test.vcd");
		$dumpvars(0, Synchronizer_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule