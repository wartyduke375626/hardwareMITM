/**
 * Simulation of UART driver module.
**/

// define timescale
`timescale 1 ns / 10 ps

module UartDriver_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 1_000_000;	// 1000 us
	
	localparam BAUD_RATE = 115_200;
	localparam BIT_DURATION_NS = 1_000_000_000 / BAUD_RATE;	// how long a bit lasts on the bus line (ns)
	localparam BIT_DURATION_CLK = SYS_CLK / BAUD_RATE; // how many system clock cycles a bit lasts on the bus line
	
	localparam NUM_DATA_BITS = 12;
	
	// internal signals
	wire tx_out;
	
	wire rx_new_data;
	wire rx_ready;
	wire tx_ready;
	
	wire [NUM_DATA_BITS-1:0] rx_data;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg rx_in = 1'b1;
	
	reg cmd_tx_start = 1'b0;
	
	reg [NUM_DATA_BITS-1:0] tx_data;
	
	// helper variables
	integer i;
	reg [NUM_DATA_BITS-1:0] rx_data_to_send;
	
	// instantiate uut
	UartDriver #(
		.BIT_DURATION(BIT_DURATION_CLK),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.rx_in(rx_in),
		
		.cmd_tx_start(cmd_tx_start),
		
		.tx_data(tx_data),
		
		.tx_out(tx_out),
		
		.rx_new_data(rx_new_data),
		.rx_ready(rx_ready),
		.tx_ready(tx_ready),

		.rx_data(rx_data)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// generate some communication on RX line
	initial
	begin
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// generate communication
		rx_data_to_send = {12'h4ca};
		
		// send data with defined baud rate
		rx_in = 1'b0;	// start bit
		#(BIT_DURATION_NS);
		for (i = 0; i < NUM_DATA_BITS; i++) // send least significat bit first
		begin
			rx_in = rx_data_to_send[i];
			#(BIT_DURATION_NS);
		end
		rx_in = 1'b1;	// stop bit
		#(BIT_DURATION_NS);
		
		// wait random time
		#(BIT_DURATION_NS + 697);
		
		// generate more communication
		rx_data_to_send = {12'hf10};
		
		// send data with defined baud rate
		rx_in = 1'b0;	// start bit
		#(BIT_DURATION_NS);
		for (i = 0; i < NUM_DATA_BITS; i++) // send least significat bit first
		begin
			rx_in = rx_data_to_send[i];
			#(BIT_DURATION_NS);
		end
		rx_in = 1'b1;	// stop bit
		#(BIT_DURATION_NS);
		
		// wait random time
		#(BIT_DURATION_NS/2 + 1223);
		
		// generate more communication
		rx_data_to_send = {12'h51d};
		
		// send data with defined baud rate
		rx_in = 1'b0;	// start bit
		#(BIT_DURATION_NS);
		for (i = 0; i < NUM_DATA_BITS; i++) // send least significat bit first
		begin
			rx_in = rx_data_to_send[i];
			#(BIT_DURATION_NS);
		end
		rx_in = 1'b1;	// stop bit
		#(BIT_DURATION_NS);
	end
	
	// test sending some data on TX line
	initial
	begin
		// wait some time
		#100;
		
		// send reset signal at the beginning
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
	
		// wait for buffer to be ready
		wait (tx_ready == 1'b1);
		
		// send some data over TX line
		tx_data <= {12'h4f6};
		
		// tx start command
		cmd_tx_start = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_tx_start = 1'b0;

		// wait for buffer to be ready
		wait (tx_ready == 1'b1);
		
		// wait some time before sending more data
		#(2*BIT_DURATION_NS + 1354);
		
		// send some more data over TX line
		tx_data <= {12'h0b5};
		
		// tx start command
		cmd_tx_start = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_tx_start = 1'b0;
		
		// wait for buffer to be ready
		wait (tx_ready == 1'b1);
		
		// wait some time before sending more data
		#(2*BIT_DURATION_NS + 637);
		
		// send some more data over TX line
		tx_data <= {12'he91};
		
		// tx start command
		cmd_tx_start = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_tx_start = 1'b0;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("UartDriver_test.vcd");
		$dumpvars(0, UartDriver_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule