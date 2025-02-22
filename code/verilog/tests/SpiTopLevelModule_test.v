/**
 * Simulation of Top level module.
**/

// define timescale
`timescale 1 ns / 10 ps

// general configuration
`define TEST_FREQ_HZ 12_000_000
`define DEBOUNCE_DURATION_US 1
`define MODE_WIDTH 4
`define NUM_DATA_BITS 8

// bus specific configuration
`define SPI_FREQ_HZ 500_000
`define SPI_SS_ACTIVE_LOW 1
`define SPI_LSB_FIRST 0

// set SPI bus
`define BUS_SPI 1

module SpiTopLevelModule_test();

	// local constants
	localparam CLK_PERIOD_NS = 1_000_000_000 / `TEST_FREQ_HZ;
	localparam SIM_DURATION = 2_000_000;	// 2000 us
	
	localparam DEBOUNCE_DURATION_US = `DEBOUNCE_DURATION_US;
	localparam MODE_WIDTH = `MODE_WIDTH;
	
	localparam NUM_DATA_BITS = `NUM_DATA_BITS;
	localparam SPI_CLK_PERIOD_NS = 1_000_000_000 / `SPI_FREQ_HZ;
	localparam SS_ACTIVE_LOW = `SPI_SS_ACTIVE_LOW;
	
	// internal signals
	wire [MODE_WIDTH-1:0] mode_leds;
	wire comm_active_led;
	
	wire if1_ss_out;
	wire if1_sclk_out;
	wire if0_miso_out;
	wire if1_mosi_out;
	
	// internal registers
	reg ref_clk = 1'b0;
	
	reg rst_btn = 1'b1;
	reg mode_select_btn = 1'b1;
	
	reg if0_ss_in = (`SPI_SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	reg if0_sclk_in = 1'b0;
	reg if1_miso_in = 1'b0;
	reg if0_mosi_in = 1'b0;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] if0_mosi_data_to_send;
	reg [NUM_DATA_BITS-1:0] if1_miso_data_to_send;
	
	integer comm_session = 0;
	
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
	
	// helper task to simulate noisy button presses (active-low)
	task simulate_noisy_btn_press(input string btn);
		integer n;
		integer i;
		
		if (btn != "RST" && btn != "MODE") begin
			$error("Invalid button specified.");
		end
		
		// noisy button press
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			if (btn == "RST") begin rst_btn = ~rst_btn; end
			if (btn == "MODE") begin mode_select_btn = ~mode_select_btn; end
			#($urandom % 100);
		end
		
		// actual button pressed
		if (btn == "RST") begin rst_btn = 1'b0; end
		if (btn == "MODE") begin mode_select_btn = 1'b0; end
		#(1_000 * DEBOUNCE_DURATION_US + 3 * CLK_PERIOD_NS + $urandom % 200);
		
		// noisy button press
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			if (btn == "RST") begin rst_btn = ~rst_btn; end
			if (btn == "MODE") begin mode_select_btn = ~mode_select_btn; end
			#($urandom % 100);
		end
		
		// button released
		if (btn == "RST") begin rst_btn = 1'b1; end
		if (btn == "MODE") begin mode_select_btn = 1'b1; end
		#(5 * CLK_PERIOD_NS + $urandom % 500);
	endtask
	
	// instantiate uut
	TopLevelModule UUT (
		.ref_clk(ref_clk),
		
		.rst_btn(rst_btn),
		.mode_select_btn(mode_select_btn),
		
		.mode_leds(mode_leds),
		.comm_active_led(comm_active_led),
		
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
		ref_clk = ~ref_clk;
	end

	// generate some master communication on if0
	initial
	begin
		// wait some time for initial reset and initialization
		#(1_000 * DEBOUNCE_DURATION_US + 10 * CLK_PERIOD_NS);
		
		// session 0 -- send data and receive dummy byte, then send dummy byte and receive data
		
		// set SS line active
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send some data
		if0_mosi_data_to_send = {8'hca};
		simulate_master();
		
		// send dummy byte to receive data
		if0_mosi_data_to_send = {8'h00};
		simulate_master();
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// wait random time
		#(697);
		
		// signal end of session
		comm_session++;
		
		// wait before next session
		#(1_000 * DEBOUNCE_DURATION_US);
		
		// session 1 -- send data and receive dummy byte, then send and receive data simmultaniously
		
		// set SS line active
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send some data
		if0_mosi_data_to_send = {8'h9b};
		simulate_master();
		if0_mosi_data_to_send = {8'h38};
		simulate_master();
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// signal end of session
		comm_session++;
		
		// wait before next session
		#(1_000 * DEBOUNCE_DURATION_US);
		
		// session 2 -- send 2 data frames, then send dummy byte to receive data
		
		// set SS line active
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send some data
		if0_mosi_data_to_send = {8'he5};
		simulate_master();
		if0_mosi_data_to_send = {8'h90};
		simulate_master();
		
		// send dummy byte to receive data
		if0_mosi_data_to_send = {8'h00};
		simulate_master();
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// signal end of session
		comm_session++;
		
		// wait before next session
		#(1_000 * DEBOUNCE_DURATION_US);
		
		// session 3 -- send and receive 3 data frames simultaniously
		
		// set SS line active
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		
		// send some data
		if0_mosi_data_to_send = {8'h62};
		simulate_master();
		if0_mosi_data_to_send = {8'h5a};
		simulate_master();
		if0_mosi_data_to_send = {8'hf4};
		simulate_master();
		
		// set SS line inactive
		#(SPI_CLK_PERIOD_NS);
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		
		// signal end of session
		comm_session++;
	end
	
	// generate some slave communication on input lines
	initial
	begin
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// send dummy to receive command
		if1_miso_data_to_send = {8'h00};
		simulate_slave();
		
		// send response
		if1_miso_data_to_send = {8'hf1};
		simulate_slave();
		
		// wait random time
		#(1002);
		
		// send dummy to receive command
		if1_miso_data_to_send = {8'h00};
		simulate_slave();
		
		// send response
		if1_miso_data_to_send = {8'h26};
		simulate_slave();
		
		// wait random time
		#(1374);
		
		// send 2 dummy bytes to receive command
		if1_miso_data_to_send = {8'h00};
		simulate_slave();
		if1_miso_data_to_send = {8'h00};
		simulate_slave();
		
		// send response
		if1_miso_data_to_send = {8'hb2};
		simulate_slave();
		
		// wait random time
		#(1197);
		
		// send 3 frames of data
		if1_miso_data_to_send = {8'h4f};
		simulate_slave();
		if1_miso_data_to_send = {8'h68};
		simulate_slave();
		if1_miso_data_to_send = {8'h69};
		simulate_slave();
	end
	
	// test code
	initial
	begin
		// wait some time
		#100;
		
		// simulate noisy reset button press
		simulate_noisy_btn_press("RST");
	
		// wait for end of first session in forward mode
		wait (comm_session == 1);
		
		// simulate noisy mode select button press
		simulate_noisy_btn_press("MODE");
		
		// wait for next session to end (now should be in MODE_SUB0_BLOCK1)
		wait (comm_session == 2);
		
		// simulate noisy mode select button press
		simulate_noisy_btn_press("MODE");		
		// wait for next session to end (now should be in MODE_SUB1_BLOCK0)
		wait (comm_session == 3);
		
		// simulate noisy mode select button press
		simulate_noisy_btn_press("MODE");		
		// wait for next session to end (now should be in MODE_ROT_13)
		wait (comm_session == 4);
	end

	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("SpiTopLevelModule_test.vcd");
		$dumpvars(0, SpiTopLevelModule_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule