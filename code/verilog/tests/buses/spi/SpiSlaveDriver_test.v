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
	
	localparam NUM_DATA_BITS = 16;
	
	// test signals
	wire bus_ready;
	wire mosi_new_data;
	
	wire [NUM_DATA_BITS-1:0] mosi_data;
	
	wire miso_out;
	
	// test registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg miso_send_enable = 1'b0;
	
	reg [NUM_DATA_BITS-1:0] miso_data;
	
	reg ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	reg sclk_in = 1'b0;
	reg mosi_in = 1'b0;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] mosi_data_to_send;
	
	// helper task to simulate master SPI communication
	task simulate_master(input integer unexp_ss_kill);
		integer i;
		integer kill;
		
		if (unexp_ss_kill != 0) begin
			kill = $urandom % NUM_DATA_BITS;
		end
		else begin
			kill = -1;
		end
		
		// set SS line active
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS / 2);
		
		// send data clocked by SCLK
		for (i = NUM_DATA_BITS-1; i >= 0; i--) // send most significat bit first
		begin
			mosi_in = mosi_data_to_send[i];
			#(SPI_CLK_PERIOD_NS / 2);
			sclk_in = 1'b1;
			#(SPI_CLK_PERIOD_NS / 2);
			sclk_in = 1'b0;
			
			if (i == kill) begin
				ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
			end
		end
		mosi_in = 1'b0;
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS / 2);
		ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	endtask
	
	// instantiate uut
	SpiSlaveDriver #(
		.SS_ACTIVE_LOW(SS_ACTIVE_LOW),
		.LSB_FIRST(LSB_FIRST),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.miso_send_enable(miso_send_enable),
		
		.bus_ready(bus_ready),
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
		
		// generate communication
		mosi_data_to_send = {16'h4ac5};
		simulate_master(0);
		
		// wait random time
		#(SPI_CLK_PERIOD_NS + 713);
		
		// generate communication with unexpected communication abort on SS line
		mosi_data_to_send = {16'h16fb};
		simulate_master(1);
		
		// wait random time
		#(SPI_CLK_PERIOD_NS + 229);
		
		// generate communication
		mosi_data_to_send = {16'h35d9};
		simulate_master(0);
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
	
		// wait for bus to be ready
		wait (bus_ready == 1'b1);
		
		// set data to be sent on MISO line
		miso_data <= {16'h0cf7};
		miso_send_enable = 1'b1;
		
		// wait for SPI slave to start processing communication
		wait (bus_ready == 1'b0);

		// wait for bus to be ready
		wait (bus_ready == 1'b1);
		
		// set data to be sent on MISO line
		miso_data <= {16'h37e1};
		miso_send_enable = 1'b1;

		// wait for SPI slave to start processing communication
		wait (bus_ready == 1'b0);
		
		// wait for bus to be ready
		wait (bus_ready == 1'b1);
		
		// set slave to not send any data on MISO line
		miso_send_enable = 1'b0;
		
		// send some more data on MOSI line
		miso_data <= {16'h2fa0};
		
		// wait for SPI slave to start processing communication
		wait (bus_ready == 1'b0);
		
		// wait for bus to be ready
		wait (bus_ready == 1'b1);
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