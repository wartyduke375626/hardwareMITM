/**
 * Simulation of Top level module.
**/

// define timescale
`timescale 1 ns / 10 ps

// set UART bus
`define BUS_UART 1

module UartTopLevelModule_test();

	// local constants
	localparam REF_FREQ_HZ = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / REF_FREQ_HZ;
	localparam SIM_DURATION = 1_000_000;	// 1000 us
	
	localparam DEBOUNCE_COUNT = 16;
	localparam MODE_WIDTH = 4;
	
	localparam NUM_DATA_BITS = 8;
	localparam UART_BAUD_RATE = 300_000;
	
	localparam BIT_DURATION_NS = 1_000_000_000 / UART_BAUD_RATE;
	
	// internal signals
	wire [MODE_WIDTH-1:0] mode_leds;
	wire comm_active_led;
	
	wire if0_tx_out;
	wire if1_tx_out;
	
	// internal registers
	reg ref_clk = 1'b0;
	
	reg rst_btn = 1'b1;
	reg mode_btn = 1'b1;
	
	reg if0_rx_in = 1'b1;
	reg if1_rx_in = 1'b1;
	
	// helper variables
	reg [NUM_DATA_BITS-1:0] if0_rx_data_to_send;
	reg [NUM_DATA_BITS-1:0] if1_rx_data_to_send;
	
	integer comm_session = 0;
	
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
			if (btn == "MODE") begin mode_btn = ~mode_btn; end
			#($urandom % 100);
		end
		
		// actual button pressed
		if (btn == "RST") begin rst_btn = 1'b0; end
		if (btn == "MODE") begin mode_btn = 1'b0; end
		#(DEBOUNCE_COUNT * CLK_PERIOD_NS + $urandom % 200 + 100);
		
		// noisy button press
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			if (btn == "RST") begin rst_btn = ~rst_btn; end
			if (btn == "MODE") begin mode_btn = ~mode_btn; end
			#($urandom % 100);
		end
		
		// button released
		if (btn == "RST") begin rst_btn = 1'b1; end
		if (btn == "MODE") begin mode_btn = 1'b1; end
		#(CLK_PERIOD_NS + $urandom % 500 + 100);
	endtask
	
	// instantiate uut
	TopLevelModule #(
		.REF_FREQ_HZ(REF_FREQ_HZ),
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT),
		.MODE_WIDTH(MODE_WIDTH),
		.NUM_DATA_BITS(NUM_DATA_BITS),
		.UART_BAUD_RATE(UART_BAUD_RATE)
	) UUT (
		.ref_clk(ref_clk),
		
		.rst_btn(rst_btn),
		.mode_btn(mode_btn),
		
		.mode_leds(mode_leds),
		.comm_active_led(comm_active_led),
		
		.if0_rx_in(if0_rx_in),
		.if1_rx_in(if1_rx_in),
		.if0_tx_out(if0_tx_out),
		.if1_tx_out(if1_tx_out)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		ref_clk = ~ref_clk;
	end

	// generate some communication on input bus lines
	initial
	begin
		// wait some time for initialization
		#(5 * DEBOUNCE_COUNT * CLK_PERIOD_NS);
		
		// send a frame on interface 0
		if0_rx_data_to_send = {8'hca};
		simulate_frame(1, 0);
		
		// wait random time
		#(697);
		
		// generate a response on interface 1
		if1_rx_data_to_send = {8'hf1};
		simulate_frame(0, 1);
		
		// signal end of session
		comm_session++;
		
		// wait before next session
		#(12 * BIT_DURATION_NS);
		
		// send 1 frame on interface 0, then 2 frames simultaniously on both interfaces
		if0_rx_data_to_send = {8'h9b};
		simulate_frame(1, 0);
		if0_rx_data_to_send = {8'h38};
		if1_rx_data_to_send = {8'h26};
		simulate_frame(1, 1);
		
		// signal end of session
		comm_session++;
		
		// wait before next session
		#(12 * BIT_DURATION_NS);
		
		// send 2 frames on interface 0, then 1 frame on interface 1
		if0_rx_data_to_send = {8'he5};
		simulate_frame(1, 0);
		if0_rx_data_to_send = {8'h90};
		simulate_frame(1, 0);
		
		// wait random time
		#(121);
		
		if1_rx_data_to_send = {8'hb2};
		simulate_frame(0, 1);
		
		// signal end of session
		comm_session++;
		
		// wait before next session
		#(12 * BIT_DURATION_NS);
		
		// send 3 frames on interface 0 and 1 simultaniously
		if0_rx_data_to_send = {8'h97};
		if1_rx_data_to_send = {8'hd1};
		simulate_frame(1, 1);
		if0_rx_data_to_send = {8'haa};
		if1_rx_data_to_send = {8'h3e};
		simulate_frame(1, 1);
		
		// wait random time
		#(334);
		
		if0_rx_data_to_send = {8'hf4};
		if1_rx_data_to_send = {8'h25};
		simulate_frame(1, 1);
		
		// signal end of session
		comm_session++;
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
		$dumpfile("UartTopLevelModule_test.vcd");
		$dumpvars(0, UartTopLevelModule_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule