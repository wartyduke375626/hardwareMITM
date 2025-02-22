/**
 * Simulation of SPI controller module.
**/

// define timescale
`timescale 1 ns / 10 ps

module SpiController_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 1_000_000;	// 1000 us
	localparam SPI_CLK_PERIOD_NS = 12 * CLK_PERIOD_NS;	// data rate has to be slower then sys_clk
	
	localparam SPI_FREQ_HZ = SYS_CLK / 12;
	localparam SS_ACTIVE_LOW = 1;
	localparam LSB_FIRST = 0;	
	localparam NUM_DATA_BITS = 12;
	
	// internal signals
	wire if0_mosi_new_data_ready;
	wire if1_miso_new_data_ready;
	wire if0_miso_send_ready;
	wire if1_mosi_send_ready;
	wire if0_miso_send_done;
	wire if1_mosi_send_done;
	
	wire [NUM_DATA_BITS-1:0] real_if0_mosi_data;
	wire [NUM_DATA_BITS-1:0] real_if1_miso_data;
	
	wire if1_ss_out;
	wire if1_sclk_out;
	wire if0_miso_out;
	wire if1_mosi_out;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg fake_if0_miso_select = 1'b0;
	reg fake_if1_mosi_select = 1'b0;
	reg fake_if0_miso_start = 1'b0;
	reg fake_if1_mosi_start = 1'b0;
	reg fake_if1_keep_alive = 1'b0;
	
	reg [NUM_DATA_BITS-1:0] fake_if0_miso_data = 0;
	reg [NUM_DATA_BITS-1:0] fake_if1_mosi_data = 0;
	
	reg if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	reg if0_sclk_in = 1'b0;
	reg if1_miso_in = 1'b0;
	reg if0_mosi_in = 1'b0;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] if0_mosi_data_to_send;
	reg [NUM_DATA_BITS-1:0] if1_miso_data_to_send;
	
	// helper task to simulate real master
	task simulate_master();
		integer i;
		
		// send data clocked by SCLK
		for (i = NUM_DATA_BITS-1; i >= 0; i--) // send most significat bit first
		begin
			if0_mosi_in = if0_mosi_data_to_send[i];
			
			#(SPI_CLK_PERIOD_NS / 2);
			if0_sclk_in = 1'b1;
			#(SPI_CLK_PERIOD_NS / 2);
			if0_sclk_in = 1'b0;
		end
		if0_mosi_in = 1'b0;
	endtask
	
	// helper task to simulate real slave
	task simulate_slave();
		integer i;
		
		// wait for SS to be active
		wait (if1_ss_out == ((SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0));
		
		// send data clocked by SCLK
		for (i = NUM_DATA_BITS-1; i >= 0; i--) // send most significat bit first
		begin
			if1_miso_in = if1_miso_data_to_send[i];
			wait (if1_sclk_out == 1'b1);	// wait for rise edge
			wait (if1_sclk_out == 1'b0);	// wait for fall edge
		end
		if1_miso_in = 1'b0;
	endtask
	
	// instantiate uut
	SpiController #(
		.SYS_FREQ_HZ(SYS_CLK),
		.SPI_FREQ_HZ(SPI_FREQ_HZ),
		.SS_ACTIVE_LOW(SS_ACTIVE_LOW),
		.LSB_FIRST(LSB_FIRST),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.fake_if0_miso_select(fake_if0_miso_select),
		.fake_if1_mosi_select(fake_if1_mosi_select),
		.fake_if0_miso_start(fake_if0_miso_start),
		.fake_if1_mosi_start(fake_if1_mosi_start),
		.fake_if1_keep_alive(fake_if1_keep_alive),
		
		.if0_mosi_new_data_ready(if0_mosi_new_data_ready),
		.if1_miso_new_data_ready(if1_miso_new_data_ready),
		.if0_miso_send_ready(if0_miso_send_ready),
		.if1_mosi_send_ready(if1_mosi_send_ready),
		.if0_miso_send_done(if0_miso_send_done),
		.if1_mosi_send_done(if1_mosi_send_done),
		
		.fake_if0_miso_data(fake_if0_miso_data),
		.fake_if1_mosi_data(fake_if1_mosi_data),
		.real_if0_mosi_data(real_if0_mosi_data),
		.real_if1_miso_data(real_if1_miso_data),
		
		.if0_ss_in(if0_ss_in),
		.if0_sclk_in(if0_sclk_in),
		.if1_miso_in(if1_miso_in),
		.if0_mosi_in(if0_mosi_in),
		.if1_ss_out(if1_ss_out),
		.if1_sclk_out(if1_sclk_out),
		.if0_miso_out(if0_miso_out),
		.if1_mosi_out(if1_mosi_out)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// generate some master communication on if0
	initial
	begin
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// set SS line active
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send some data
		if0_mosi_data_to_send = {12'h3a2};
		simulate_master();
		if0_mosi_data_to_send = {12'haf8};
		simulate_master();
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// wait random time
		#(1002);
		
		// set SS line active
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send some data
		if0_mosi_data_to_send = {12'hf89};
		simulate_master();
		if0_mosi_data_to_send = {12'h56d};
		simulate_master();
		if0_mosi_data_to_send = {12'h17f};
		simulate_master();
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// wait some long time
		#(14*SPI_CLK_PERIOD_NS + 697);
		
		// set SS line active
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send some data
		if0_mosi_data_to_send = {12'ha55};
		simulate_master();
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	end
	
	// generate some slave communication on input lines
	initial
	begin
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// send some data
		if1_miso_data_to_send = {12'h4ca};
		simulate_slave();
		if1_miso_data_to_send = {12'h412};
		simulate_slave();
		
		// wait random time
		#(1002);
		
		// send some data
		if1_miso_data_to_send = {12'h321};
		simulate_slave();
		if1_miso_data_to_send = {12'hbca};
		simulate_slave();
		if1_miso_data_to_send = {12'h91e};
		simulate_slave();
		
		// wait some long time
		#(14*SPI_CLK_PERIOD_NS + 697);
		
		// send some data
		if1_miso_data_to_send = {12'h289};
		simulate_slave();
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
	
		// for the first data chunk forward everything
		fake_if0_miso_select = 1'b0;
		fake_if1_mosi_select = 1'b0;
		fake_if0_miso_start = 1'b0;
		fake_if1_mosi_start = 1'b0;
		fake_if1_keep_alive = 1'b0;
		
		// wait to receive the data
		wait(if0_mosi_new_data_ready == 1'b1);
		fake_if1_mosi_data = real_if0_mosi_data;
		
		// wait for window to switch mode
		wait(if0_miso_send_ready == 1'b1);		
		
		// wait for fake master to be ready
		wait(if1_mosi_send_ready == 1'b1);
		fake_if1_mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if1_mosi_start = 1'b0;
		
		// for the next data chunk send fake data on if1 and block if0
		fake_if0_miso_select = 1'b1;
		fake_if1_mosi_select = 1'b1;
		
		// wait for transmit to complete
		wait (if1_mosi_send_ready == 1'b1);
		
		// for the next 3 chunks we want to block first chunk, then send the chunks we received
		fake_if0_miso_select = 1'b1;
		fake_if1_mosi_select = 1'b1;
		
		// on if1 we are master -- we need to be active
		// wait till we detect the real master initiated communication
		wait(if0_miso_send_ready == 1'b1);
		
		// start sending a dummy 0 immediatelly 
		wait(if1_mosi_send_ready == 1'b1);
		fake_if1_mosi_data = 0;
		fake_if1_mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if1_mosi_start = 1'b0;
		
		// wait to receive the data on both interfaces
		wait(if1_miso_new_data_ready == 1'b1);
		fake_if0_miso_data = real_if1_miso_data;
		wait(if0_mosi_new_data_ready == 1'b1);
		fake_if1_mosi_data = real_if0_mosi_data;
		
		// on if1 we are master -- start sending immediatelly
		wait(if1_mosi_send_ready == 1'b1);
		fake_if1_keep_alive = 1'b1;
		fake_if1_mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if1_mosi_start = 1'b0;
		
		// on if0 we are slave -- wait tilll we can send data
		wait(if0_miso_send_ready == 1'b1);
		fake_if0_miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if0_miso_start = 1'b0;
		
		// wait to receive next data on both interfaces
		wait(if0_mosi_new_data_ready == 1'b1);
		fake_if1_mosi_data = real_if0_mosi_data;
		wait(if1_miso_new_data_ready == 1'b1);
		fake_if0_miso_data = real_if1_miso_data;
		
		// on if0 we are slave -- wait tilll we can send data
		wait(if0_miso_send_ready == 1'b1);
		fake_if0_miso_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if0_miso_start = 1'b0;
		
		// on if1 we are master -- start sending when we are ready
		wait(if1_mosi_send_ready == 1'b1);
		fake_if1_mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if1_mosi_start = 1'b0;
		
		// wait to receive next data on master interface (slave->master can no longer be forwarded as real master will end communication)
		wait(if0_mosi_new_data_ready == 1'b1);
		fake_if1_mosi_data = real_if0_mosi_data;
		
		// send the last chunk on if1
		wait(if1_mosi_send_ready == 1'b1);
		fake_if1_mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if1_mosi_start = 1'b0;
		
		// disable keep-alive
		fake_if1_keep_alive = 1'b0;
		
		// wait for transmit to complete
		wait (if1_mosi_send_ready == 1'b1);
		
		// block master->slave but forward slave->master -- we can achieve this by sending 0 as fake master
		fake_if0_miso_select = 1'b0;
		fake_if1_mosi_select = 1'b1;
		fake_if1_mosi_data = 0;
		
		// wait till real master begins communication
		wait(if0_miso_send_ready == 1'b1);
		
		// send fake data to slave
		wait(if1_mosi_send_ready == 1'b1);
		fake_if1_mosi_start = 1'b1;
		#(CLK_PERIOD_NS);
		fake_if1_mosi_start = 1'b0;
		
		// wait for transmit to complete
		wait (if1_mosi_send_ready == 1'b1);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("SpiController_test.vcd");
		$dumpvars(0, SpiController_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule