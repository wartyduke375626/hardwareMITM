/**
 * Simulation of SPI slave driver module.
**/

// define timescale
`timescale 1 ns / 10 ps

module SpiSlaveDriver_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 100_000;	// 100 us
	
	localparam SPI_CLK_PERIOD_NS = 16 * CLK_PERIOD_NS;
	
	localparam SS_ACTIVE_LOW = 1;
	localparam LSB_FIRST = 0;
	
	localparam NUM_DATA_BITS = 8;
	
	// test signals
	wire miso_ready;
	wire miso_done;
	wire mosi_new_data;
	
	wire [NUM_DATA_BITS-1:0] mosi_data;
	
	wire miso_out;
	
	// test registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg miso_start = 1'b0;
	
	reg [NUM_DATA_BITS-1:0] miso_data;
	
	reg ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	reg sclk_in = 1'b0;
	reg mosi_in = 1'b0;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] mosi_data_to_send;
	
	// helper task to simulate master SPI communication, set ss_kill to negatve for no abort
	task simulate_master(input integer ss_kill);
		integer i;
		
		// send data clocked by SCLK
		for (i = NUM_DATA_BITS-1; i >= 0; i--) // send most significat bit first
		begin
			mosi_in = mosi_data_to_send[i];
			#(SPI_CLK_PERIOD_NS / 2);
			sclk_in = 1'b1;
			#(SPI_CLK_PERIOD_NS / 2);
			sclk_in = 1'b0;
			
			if (i == ss_kill) begin
				ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
			end
		end
		mosi_in = 1'b0;
	endtask
	
	// instantiate uut
	SpiSlaveDriver #(
		.SS_ACTIVE_LOW(SS_ACTIVE_LOW),
		.LSB_FIRST(LSB_FIRST),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.miso_start(miso_start),
		
		.miso_ready(miso_ready),
		.miso_done(miso_done),
		.mosi_new_data(mosi_new_data),
		
		.miso_data(miso_data),
		.mosi_data(mosi_data),

		.ss_in(ss_in),
		.sclk_in(sclk_in),
		.miso_out(miso_out),
		.mosi_in(mosi_in)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// generate some moster communication
	initial
	begin
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// set SS line active
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send 1 chunk of data
		mosi_data_to_send = {8'hc5};
		simulate_master(-1);
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// wait random time
		#(SPI_CLK_PERIOD_NS + 713);
		
		// set SS line active
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send 3 chunks of data -- unexpected SS kill in third one
		mosi_data_to_send = {8'h1a};
		simulate_master(-1);
		mosi_data_to_send = {8'he3};
		simulate_master(-1);
		mosi_data_to_send = {8'hd9};
		simulate_master(3);
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// wait random time
		#(SPI_CLK_PERIOD_NS + 713);
		
		// set SS line active
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send 2 chunks of data
		mosi_data_to_send = {8'h57};
		simulate_master(-1);
		mosi_data_to_send = {8'hb4};
		simulate_master(-1);
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	end
	
	// test spi master communication
	initial
	begin
		// wait some time
		#100;
		
		// send reset signal at the beginning
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
	
		// wait for miso to be ready
		wait (miso_ready == 1'b1);
		
		// set data to be sent on MISO line
		miso_data <= {8'hf7};
		
		// signal start
		miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		miso_start = 1'b0;
		
		// wait for SPI slave to start processing communication
		wait (miso_ready == 1'b0);

		// wait for MISO to be ready
		wait (miso_ready == 1'b1);
		
		// signal start -- this should be aborted as SS should go inactive now
		miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		miso_start = 1'b0;
		
		// wait for MISO to be ready again
		wait (miso_ready == 1'b1);
		
		// set data to be sent on MISO line
		miso_data <= {8'he1};
		
		// signal start
		miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		miso_start = 1'b0;

		// wait for SPI slave to start processing communication
		wait (miso_ready == 1'b0);
		
		// wait for MISO to be ready
		wait (miso_ready == 1'b1);
		
		// attempt sending MISO too late
		wait (sclk_in == 1'b1);
		#(CLK_PERIOD_NS);
		// signal start
		miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		miso_start = 1'b0;
		
		// wait for MISO to be ready
		wait (miso_ready == 1'b1);
		
		// set data to be sent on MISO line
		miso_data <= {8'h1b};
		
		// signal start
		miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		miso_start = 1'b0;
		
		// wait for SPI slave to start processing communication
		wait (miso_ready == 1'b0);
		
		// wait for MISO to be ready
		wait (miso_ready == 1'b1);
		
		// wait for bus to be ready
		wait (miso_ready == 1'b1);
		
		// no data sent on MISO this time
		wait (miso_ready == 1'b0);
		
		// wait for MISO to be ready
		wait (miso_ready == 1'b1);
		
		// set data to be sent on MISO line
		miso_data <= {8'hf3};
		
		// signal start
		miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		miso_start = 1'b0;
		
		// wait for SPI slave to start processing communication
		wait (miso_ready == 1'b0);
		
		// wait for MISO to be ready
		wait (miso_ready == 1'b1);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("SpiSlaveDriver_test.vcd");
		$dumpvars(0, SpiSlaveDriver_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule