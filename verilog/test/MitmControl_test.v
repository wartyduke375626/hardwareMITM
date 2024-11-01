/**
 * Simulation of MITM Control module.
**/

// define timescale
`timescale 1 ns / 10 ps

module MitmControl_test();

	// local constants
	localparam	SYS_CLK	= 12_000_000;	// 12 MHz
	localparam	CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam	SIM_DURATION = 1_000_000;	// 1000 us
	localparam	DATA_CLK_PERIOD_NS = 20 * CLK_PERIOD_NS; // data rate has to be slower then sys_clk
	
	localparam	DATA_SIZE = 8;
	localparam	BUS_WIDTH = 4;
	
	// internal signals
	wire	miso_out;
	wire	mosi_out;
	wire	sclk_out;
	wire	ss_out;
	
	// internal registers
	reg		sys_clk = 1'b0;
	reg		rst = 1'b0;
	reg		miso_in = 1'b0;
	reg		mosi_in = 1'b0;
	reg		sclk_in = 1'b0;
	reg		ss_in = 1'b0;
	
	// helper variables
	integer					i;
	reg		[DATA_SIZE-1:0]	miso_data_to_send;
	reg		[DATA_SIZE-1:0]	mosi_data_to_send;
	
	// instantiate uut
	MitmControl #(
		.DATA_SIZE(DATA_SIZE),
		.BUS_WIDTH(BUS_WIDTH)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.miso_in(miso_in),
		.mosi_in(mosi_in),
		.sclk_in(sclk_in),
		.ss_in(ss_in),
		.miso_out(miso_out),
		.mosi_out(mosi_out),
		.sclk_out(sclk_out),
		.ss_out(ss_out)
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
		#1371;
		
		
		// generate some data on input lines:
		miso_data_to_send = 8'h3a;
		mosi_data_to_send = 8'he7;
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = DATA_SIZE-1; i >= 0; i--) // send most significat bit first
		begin
			sclk_in = 1'b0;
			miso_in = miso_data_to_send[i];
			mosi_in = mosi_data_to_send[i];
			#(DATA_CLK_PERIOD_NS / 2);
			sclk_in = 1'b1;
			#(DATA_CLK_PERIOD_NS / 2);
		end
		sclk_in = 1'b0;
		miso_in = 1'b0;
		mosi_in = 1'b0;
		
		// fall edge on SS
		#(DATA_CLK_PERIOD_NS);
		ss_in = 1'b0;
		
		
		// wait random time
		#(DATA_CLK_PERIOD_NS + 697);
		
		
		// generate some data on input lines:
		miso_data_to_send = 8'h29;
		mosi_data_to_send = 8'hf1;
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = DATA_SIZE-1; i >= 0; i--) // send most significat bit first
		begin
			sclk_in = 1'b0;
			miso_in = miso_data_to_send[i];
			mosi_in = mosi_data_to_send[i];
			#(DATA_CLK_PERIOD_NS / 2);
			sclk_in = 1'b1;
			#(DATA_CLK_PERIOD_NS / 2);
		end
		sclk_in = 1'b0;
		miso_in = 1'b0;
		mosi_in = 1'b0;
		
		// fall edge on SS
		#(DATA_CLK_PERIOD_NS);
		ss_in = 1'b0;
		
		
		// wait random time
		#(DATA_CLK_PERIOD_NS + 1223);
		
		
		// generate some data on input lines:
		miso_data_to_send = 8'h3a;
		mosi_data_to_send = 8'he7;
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = DATA_SIZE-1; i >= 0; i--) // send most significat bit first
		begin
			sclk_in = 1'b0;
			miso_in = miso_data_to_send[i];
			mosi_in = mosi_data_to_send[i];
			#(DATA_CLK_PERIOD_NS / 2);
			sclk_in = 1'b1;
			#(DATA_CLK_PERIOD_NS / 2);
		end
		sclk_in = 1'b0;
		miso_in = 1'b0;
		mosi_in = 1'b0;
		
		// fall edge on SS
		#(DATA_CLK_PERIOD_NS);
		ss_in = 1'b0;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("MitmControl_test.vcd");
		$dumpvars(0, MitmControl_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule