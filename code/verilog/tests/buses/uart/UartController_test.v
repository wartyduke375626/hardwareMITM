/**
 * Simulation of UART controller module.
**/

// define timescale
`timescale 1 ns / 10 ps

module UartController_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 1_000_000;	// 1000 us
	localparam DATA_CLK_PERIOD_NS = 20 * CLK_PERIOD_NS;	// data rate has to be slower then sys_clk
	
	localparam BAUD_RATE = 115_200;
	localparam BIT_DURATION_NS = 1_000_000_000 / BAUD_RATE; 
	localparam NUM_DATA_BITS = 12;
	
	// internal signals
	wire if0_rx_new_data_ready;
	wire if1_rx_new_data_ready;
	wire if0_tx_write_ready;
	wire if1_tx_write_ready;
	wire if0_tx_write_done;
	wire if1_tx_write_done;
	
	wire [NUM_DATA_BITS-1:0] real_if0_receive_data;
	wire [NUM_DATA_BITS-1:0] real_if1_receive_data;
	
	wire if0_tx_out;
	wire if1_tx_out;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg fake_if0_tx_select = 1'b0;
	reg fake_if1_tx_select = 1'b0;
	reg fake_if0_tx_start = 1'b0;
	reg fake_if1_tx_start = 1'b0;
	
	reg [NUM_DATA_BITS-1:0] fake_if0_transmit_data = 0;
	reg [NUM_DATA_BITS-1:0] fake_if1_transmit_data = 0;
	
	reg if0_rx_in = 1'b1;
	reg if1_rx_in = 1'b1;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] if0_rx_data_to_send;
	reg [NUM_DATA_BITS-1:0] if1_rx_data_to_send;
	
	// helper task to simulate a frame being received on if0, if1 or both
	task simulate_frame(input integer if0, input integer if1);
		integer i;
		
		if0_rx_in = (if0 == 0) ? 1'b1 : 1'b0; // start bit
		if1_rx_in = (if1 == 0) ? 1'b1 : 1'b0; // start bit
		#(BIT_DURATION_NS);
		for (i = 0; i < NUM_DATA_BITS; i++) // send least significat bit first
		begin
			if0_rx_in = (if0 == 0) ? 1'b1 : if0_rx_data_to_send[i];
			if1_rx_in = (if1 == 0) ? 1'b1 : if1_rx_data_to_send[i];
			#(BIT_DURATION_NS);
		end
		if0_rx_in = 1'b1;	// stop bit
		if1_rx_in = 1'b1;	// stop bit
		#(BIT_DURATION_NS);
	endtask
	
	// instantiate uut
	UartController #(
		.SYS_FREQ_HZ(SYS_CLK),
		.BAUD_RATE(BAUD_RATE),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.fake_if0_tx_select(fake_if0_tx_select),
		.fake_if1_tx_select(fake_if1_tx_select),
		.fake_if0_tx_start(fake_if0_tx_start),
		.fake_if1_tx_start(fake_if1_tx_start),
		
		.if0_rx_new_data_ready(if0_rx_new_data_ready),
		.if1_rx_new_data_ready(if1_rx_new_data_ready),
		.if0_tx_write_ready(if0_tx_write_ready),
		.if1_tx_write_ready(if1_tx_write_ready),
		.if0_tx_write_done(if0_tx_write_done),
		.if1_tx_write_done(if1_tx_write_done),
		
		.fake_if0_transmit_data(fake_if0_transmit_data),
		.fake_if1_transmit_data(fake_if1_transmit_data),
		.real_if0_receive_data(real_if0_receive_data),
		.real_if1_receive_data(real_if1_receive_data),
		
		.if0_rx_in(if0_rx_in),
		.if1_rx_in(if1_rx_in),
		.if0_tx_out(if0_tx_out),
		.if1_tx_out(if1_tx_out)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// generate some communication on input lines
	initial
	begin
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// send a frame on interface 0
		if0_rx_data_to_send = {12'h4ca};
		simulate_frame(1, 0);
		
		// wait random time
		#(697);
		
		// generate a response on interface 1
		if1_rx_data_to_send = {12'hf10};
		simulate_frame(0, 1);
		
		// wait random time
		#(BIT_DURATION_NS + 1223);
		
		// send 2 frames on interface 0
		if0_rx_data_to_send = {12'h95b};
		simulate_frame(1, 0);
		if0_rx_data_to_send = {12'hd38};
		simulate_frame(1, 0);
		
		// wait random time
		#(697);
		
		// generate a response on interface 1 (2 frames)
		if1_rx_data_to_send = {12'h0a5};
		simulate_frame(0, 1);
		if1_rx_data_to_send = {12'h6e9};
		simulate_frame(0, 1);
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
	
		// for the first frame replicate data received on interface 0 to interface 1
		fake_if0_tx_select = 1'b1;
		fake_if1_tx_select = 1'b0;
		fake_if0_tx_start = 1'b0;
		fake_if1_tx_start = 1'b0;
		
		// wait to receive the data on interface 0 and copy it
		wait(if0_rx_new_data_ready == 1'b1);
		#(CLK_PERIOD_NS);
		fake_if0_transmit_data = real_if0_receive_data;
		
		// wait for write to be ready on interface 0 and send data
		wait (if0_tx_write_ready == 1'b1);
		#(CLK_PERIOD_NS);
		fake_if0_tx_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if0_tx_start = 1'b0;
		
		// wait for transmit to complete
		wait (if0_tx_write_ready == 1'b1);
		#(CLK_PERIOD_NS);
		
		// for the second frames forward the first one and block the second
		// then in the response frame block the first one and replicate data received in the fisrt one on the second
		fake_if0_tx_select = 1'b0;
		fake_if1_tx_select = 1'b0;
		fake_if0_tx_start = 1'b0;
		fake_if1_tx_start = 1'b0;
		
		// after first frame is received block the second
		wait(if0_rx_new_data_ready == 1'b1);
		#(CLK_PERIOD_NS);
		fake_if1_tx_select = 1'b1;
		fake_if1_tx_start = 1'b0;
		
		// wait for second frame to complete and block first frame of response
		wait(if0_rx_new_data_ready == 1'b1);
		#(CLK_PERIOD_NS);
		fake_if0_tx_select = 1'b1;
		fake_if1_tx_select = 1'b0;
		fake_if0_tx_start = 1'b0;
		fake_if1_tx_start = 1'b0;
		
		// wait for the frame to be received and send it
		wait(if1_rx_new_data_ready == 1'b1);
		#(CLK_PERIOD_NS);
		fake_if0_transmit_data = real_if1_receive_data;
		fake_if0_tx_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if0_tx_start = 1'b0;
		
		// wait for write to be ready on interface 1 and send data
		wait (if0_tx_write_ready == 1'b1);
		#(CLK_PERIOD_NS);
		fake_if1_tx_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if1_tx_start = 1'b0;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("UartController_test.vcd");
		$dumpvars(0, UartController_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule