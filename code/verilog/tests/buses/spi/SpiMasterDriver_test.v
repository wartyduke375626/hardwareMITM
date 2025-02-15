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
	
	localparam NUM_DATA_BITS = 16;
	
	// test signals
	wire bus_ready;
	wire miso_new_data;
	
	wire [NUM_DATA_BITS-1:0] miso_data;
	
	wire ss_out;
	wire sclk_out;
	wire mosi_out;
	
	// test registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg comm_start = 1'b0;
	
	reg [NUM_DATA_BITS-1:0] mosi_data;
	
	reg miso_in = 1'b1;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] miso_data_to_send;
	
	// helper task to simulate slave communication on miso line
	task simulate_slave();
		integer i;
		
		// wait for SS to go active
		wait (ss_out == ((SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0));
		
		// send data clocked by SCLK
		for (i = NUM_DATA_BITS-1; i >= 0; i--) // send most significat bit first
		begin
			wait (sclk_out == 1'b0);	// wait for fall edge
			miso_in = miso_data_to_send[i];
			wait (sclk_out == 1'b1);	// wait for rise edge
		end
		
		// wait for SS to go inactive
		wait (ss_out == ((SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1));
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
		
		.comm_start(comm_start),
		
		.bus_ready(bus_ready),
		.miso_new_data(miso_new_data),
		
		.miso_data(miso_data),
		.mosi_data(mosi_data),

		.miso_in(miso_in),
		.ss_out(ss_out),
		.sclk_out(sclk_out),
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
		miso_data_to_send = {16'h4ac5};
		simulate_slave();
		
		// generate communication
		miso_data_to_send = {16'h16fb};
		simulate_slave();
		
		// generate communication
		miso_data_to_send = {16'h35d9};
		simulate_slave();
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
		
		// send some data on MOSI line
		mosi_data <= {16'h0cf7};
		
		// communication start command
		comm_start = 1'b1;
		#(CLK_PERIOD_NS);
		comm_start = 1'b0;

		// wait for bus to be ready
		wait (bus_ready == 1'b1);
		
		// wait some time before sending more data
		#(3*CLK_PERIOD_NS + 1354);
		
		// send some more data on MOSI line
		mosi_data <= {16'h37e1};
		
		// communication start command
		comm_start = 1'b1;
		#(CLK_PERIOD_NS);
		comm_start = 1'b0;

		// wait for bus to be ready
		wait (bus_ready == 1'b1);
		
		// wait some time before sending more data
		#(3*CLK_PERIOD_NS + 637);
		
		// send some more data on MOSI line
		mosi_data <= {16'h2fa0};
		
		// communication start command
		comm_start = 1'b1;
		#(CLK_PERIOD_NS);
		comm_start = 1'b0;

		// wait for bus to be ready
		wait (bus_ready == 1'b1);
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