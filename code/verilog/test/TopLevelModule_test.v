/**
 * Simulation of Top level module.
**/

// define timescale
`timescale 1 ns / 10 ps

module TopLevelModule_test();

	// local constants
	localparam REF_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / REF_CLK;
	localparam SIM_DURATION = 1_000_000;	// 1000 us
	localparam DATA_CLK_PERIOD_NS = 20 * CLK_PERIOD_NS;	// data rate has to be slower then sys_clk
	localparam DEBOUNCE_COUNT = 16;
	
	localparam DATA_FRAME_SIZE = 20;
	localparam MODE_WIDTH = 2;
	
	// internal signals
	wire [MODE_WIDTH-1:0] mode_leds;
	wire comm_active_led;
	
	wire miso_out;
	wire mosi_out;
	wire sclk_out;
	wire ss_out;
	
	// internal registers
	reg ref_clk = 1'b0;
	
	reg rst_btn = 1'b1;
	reg mode_btn = 1'b1;
	
	reg miso_in = 1'b0;
	reg mosi_in = 1'b0;
	reg sclk_in = 1'b0;
	reg ss_in = 1'b0;
	
	// helper variables
	integer i;
	integer n;
	reg [DATA_FRAME_SIZE-1:0] miso_data_to_send;
	reg [DATA_FRAME_SIZE-1:0] mosi_data_to_send;
	
	// instantiate uut
	TopLevelModule #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT)
	) UUT (
		.ref_clk(ref_clk),
		
		.rst_btn(rst_btn),
		.mode_btn(mode_btn),
		
		.miso_in(miso_in),
		.mosi_in(mosi_in),
		.sclk_in(sclk_in),
		.ss_in(ss_in),
		
		.mode_leds(mode_leds),
		.comm_active_led(comm_active_led),
		
		.miso_out(miso_out),
		.mosi_out(mosi_out),
		.sclk_out(sclk_out),
		.ss_out(ss_out)
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
		
		// send 'read' communication frame
		miso_data_to_send = {3'b0, 9'h0, 8'ha3};
		mosi_data_to_send = {3'b110, 9'h09a, 8'h0};
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = DATA_FRAME_SIZE-1; i >= 0; i--) // send most significat bit first
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
		#(DEBOUNCE_COUNT * DATA_CLK_PERIOD_NS / 2 + 2017);
		
		
		// send 'read' communication frame
		miso_data_to_send = {3'b0, 9'h0, 8'hb5};
		mosi_data_to_send = {3'b110, 9'h120, 8'h0};
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = DATA_FRAME_SIZE-1; i >= 0; i--) // send most significat bit first
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
		#(DEBOUNCE_COUNT * DATA_CLK_PERIOD_NS / 3 + 3239);
		
		
		// send 'write' communication frame
		miso_data_to_send = {3'b0, 9'h0, 8'h0};
		mosi_data_to_send = {3'b101, 9'h037, 8'h6d};
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = DATA_FRAME_SIZE-1; i >= 0; i--) // send most significat bit first
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
	
	// test code
	initial
	begin
		// wait some time
		#100;
		
		
		// simulate noisy reset button press
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			rst_btn = ~rst_btn;
			#($urandom % 100);
		end
		
		// actual button pressed
		rst_btn = 1'b0;
		#(DEBOUNCE_COUNT * CLK_PERIOD_NS + 211);
		
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			rst_btn = ~rst_btn;
			#($urandom % 100);
		end
		#(CLK_PERIOD_NS);
		
		// button released
		rst_btn = 1'b1;
		#(CLK_PERIOD_NS + 671);
	
	
		// wait for next data frame in forward mode
		wait (ss_in == 1'b1);
		wait (ss_in == 1'b0);
		
		
		// simulate noisy mode select button press
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			mode_btn = ~mode_btn;
			#($urandom % 100);
		end
		
		// actual button pressed
		mode_btn = 1'b0;
		#(DEBOUNCE_COUNT * CLK_PERIOD_NS + 93);
		
		n = $urandom % 50;
		for (i = 0; i < n; i++)
		begin
			mode_btn = ~mode_btn;
			#($urandom % 100);
		end
		#(CLK_PERIOD_NS);
		
		// button released
		mode_btn = 1'b1;
		#(CLK_PERIOD_NS + 671);
		
		
		// wait for next data frame (now should be in sub_all mode)
		wait (ss_in == 1'b1);
		wait (ss_in == 1'b0);
		
		
		// wait for next data frame (same mode as above)
		wait (ss_in == 1'b1);
		wait (ss_in == 1'b0);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("TopLevelModule_test.vcd");
		$dumpvars(0, TopLevelModule_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule