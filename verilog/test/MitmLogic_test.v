/**
 * Simulation of MITM Logic module.
**/

// define timescale
`timescale 1 ns / 10 ps

module MitmLogic_test();

	// local constants
	localparam	SYS_CLK	= 12_000_000;	// 12 MHz
	localparam	CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam	SIM_DURATION = 10_000;	// 10 us
	
	localparam	DATA_SIZE = 8;
	
	// internal signals
	wire	[DATA_SIZE-1:0]	fake_miso_data;
	wire	[DATA_SIZE-1:0]	fake_mosi_data;
	wire					fake_miso_select;
	wire					fake_mosi_select;
	wire					done_sig;
	
	// internal registers
	reg					sys_clk = 1'b0;
	reg					rst = 1'b0;
	reg					eval = 1'b0;
	
	reg	[DATA_SIZE-1:0] real_miso_data;
	reg	[DATA_SIZE-1:0] real_mosi_data;
	

	// instantiate uut
	MitmLogic #(
		.DATA_SIZE(DATA_SIZE)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.eval(eval),
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data),
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data),
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		.done_sig(done_sig)
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
		#100;
		
		// set some input data
		real_miso_data = 8'ha3;
		real_mosi_data = 8'h01;
		
		// evaluate
		eval = 1'b1;
		#(CLK_PERIOD_NS);
		eval = 1'b0;
		
		// wait for done signal
		wait (done_sig == 1'b1);
		
		// set some input data
		real_miso_data = 8'h40;
		real_mosi_data = 8'hff;
		
		// evaluate
		eval = 1'b1;
		#(CLK_PERIOD_NS);
		eval = 1'b0;
		
		// wait for done signal
		wait (done_sig == 1'b1);
		
		// wait some time to visualize
		#100;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("MitmLogic_test.vcd");
		$dumpvars(0, MitmLogic_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule