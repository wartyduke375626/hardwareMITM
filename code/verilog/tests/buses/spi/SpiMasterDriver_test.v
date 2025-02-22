/**
 * Simulation of SPI master driver module.
**/

// define timescale
`timescale 1 ns / 10 ps

module SpiMasterDriver_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 100_000;	// 100 us
	
	localparam CLOCK_DIV = 16;
	localparam SS_ACTIVE_LOW = 1;
	localparam LSB_FIRST = 0;
	
	localparam NUM_DATA_BITS = 8;
	
	// test signals
	wire mosi_ready;
	wire mosi_done;
	wire miso_new_data;
	
	wire [NUM_DATA_BITS-1:0] miso_data;
	
	wire ss_out;
	wire sclk_out;
	wire mosi_out;
	
	// test registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg mosi_start = 1'b0;
	reg keep_alive = 1'b0;
	
	reg [NUM_DATA_BITS-1:0] mosi_data;
	
	reg miso_in = 1'b0;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] miso_data_to_send;
	
	// helper task to simulate slave communication on miso line
	task simulate_slave();
		integer i;
		
		// wait for SS to be active
		wait (ss_out == ((SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0));
		
		// send data clocked by SCLK
		for (i = NUM_DATA_BITS-1; i >= 0; i--) // send most significat bit first
		begin
			miso_in = miso_data_to_send[i];
			wait (sclk_out == 1'b1);	// wait for rise edge
			wait (sclk_out == 1'b0);	// wait for fall edge
		end
		miso_in = 1'b0;
	endtask
	
	// instantiate uut
	SpiMasterDriver #(
		.CLOCK_DIV(CLOCK_DIV),
		.SS_ACTIVE_LOW(SS_ACTIVE_LOW),
		.LSB_FIRST(LSB_FIRST),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.mosi_start(mosi_start),
		.keep_alive(keep_alive),
		
		.mosi_ready(mosi_ready),
		.mosi_done(mosi_done),
		.miso_new_data(miso_new_data),
		
		.miso_data(miso_data),
		.mosi_data(mosi_data),

		.ss_out(ss_out),
		.sclk_out(sclk_out),
		.miso_in(miso_in),
		.mosi_out(mosi_out)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// generate some slave communication on MISO line
	initial
	begin
		// generate communication
		miso_data_to_send = {8'hc5};
		simulate_slave();
		
		// generate communication
		miso_data_to_send = {8'h6b};
		simulate_slave();
		
		// generate communication
		miso_data_to_send = {8'hd9};
		simulate_slave();
	end
	
	// test SPI master communication
	initial
	begin
		// wait some time
		#100;
		
		// send reset signal at the beginning
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
	
		// wait for MOSI to be ready
		wait (mosi_ready == 1'b1);
		
		// send some data on MOSI line -- no keep-alive
		mosi_data <= {8'hcf};
		
		// MOSI start command
		mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		mosi_start = 1'b0;

		// wait for MOSI to be ready
		wait (mosi_ready == 1'b1);
		
		// wait some time before sending more data
		#(3*CLK_PERIOD_NS + 1354);
		
		// send two bytes on MOSI line -- with keep-alive
		mosi_data <= {8'h37};
		keep_alive <= 1'b1;
		
		// MOSI start command
		mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		mosi_start = 1'b0;

		// wait for MOSI to be ready
		wait (mosi_ready == 1'b1);
		
		// send second byte on MOSI line
		mosi_data <= {8'h2f};
		
		// MOSI start command
		mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		mosi_start = 1'b0;
		
		// turn off keep-alive
		keep_alive <= 1'b0;

		// wait for MOSI to be ready
		wait (mosi_ready == 1'b1);
		
		// send some more data on MOSI line -- with keep-alive
		mosi_data <= {8'ha0};
		keep_alive <= 1'b1;
		
		// MOSI start command
		mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		mosi_start = 1'b0;
		
		// wait for MOSI to be ready
		wait (mosi_ready == 1'b1);
		
		// test turning off keep-alive late -- should result in abort of communication
		keep_alive <= 1'b0;
		
		// wait for MOSI to be ready
		wait (mosi_ready == 1'b1);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("SpiMasterDriver_test.vcd");
		$dumpvars(0, SpiMasterDriver_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule