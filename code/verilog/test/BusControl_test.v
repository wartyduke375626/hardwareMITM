/**
 * Simulation of Bus control module.
**/

// define timescale
`timescale 1 ns / 10 ps

module BusControl_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 1_000_000;	// 1000 us
	localparam DATA_CLK_PERIOD_NS = 20 * CLK_PERIOD_NS;	// data rate has to be slower then sys_clk
	
	localparam BUF_SIZE = 12;
	localparam CHUNK_SIZE_WIDTH = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal signals
	wire miso_out;
	wire mosi_out;
	wire sclk_out;
	wire ss_out;
	
	wire comm_active;
	wire bus_ready;
	
	wire [BUF_SIZE-1:0] real_miso_data;
	wire [BUF_SIZE-1:0] real_mosi_data;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	
	reg miso_in = 1'b0;
	reg mosi_in = 1'b0;
	reg sclk_in = 1'b0;
	reg ss_in = 1'b0;
	
	reg cmd_next_chunk = 1'b0;
	reg cmd_finish = 1'b0;
	
	reg [CHUNK_SIZE_WIDTH-1:0] next_chunk_size = 0;
	
	reg fake_miso_select;
	reg fake_mosi_select;
	
	reg [BUF_SIZE-1:0] fake_miso_data = 0;
	reg [BUF_SIZE-1:0] fake_mosi_data = 0;
	
	// helper variables
	integer i;
	reg [BUF_SIZE-1:0] miso_data_to_send;
	reg [BUF_SIZE-1:0] mosi_data_to_send;
	
	// instantiate uut
	BusControl #(
		.BUF_SIZE(BUF_SIZE)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.miso_in(miso_in),
		.mosi_in(mosi_in),
		.sclk_in(sclk_in),
		.ss_in(ss_in),
		
		.cmd_next_chunk(cmd_next_chunk),
		.cmd_finish(cmd_finish),
		
		.next_chunk_size(next_chunk_size),
		
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data),
		
		.miso_out(miso_out),
		.mosi_out(mosi_out),
		.sclk_out(sclk_out),
		.ss_out(ss_out),
		
		.comm_active(comm_active),
		.bus_ready(bus_ready),
		
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data)
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
		
		// generate communication
		miso_data_to_send = {12'ha32};
		mosi_data_to_send = {12'hf51};
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = BUF_SIZE-1; i >= 0; i--) // send most significat bit first
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
		#(DATA_CLK_PERIOD_NS + 697);
		
		// generate communication
		miso_data_to_send = {12'h5f7};
		mosi_data_to_send = {12'h799};
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = BUF_SIZE-1; i >= 0; i--) // send most significat bit first
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
		#(DATA_CLK_PERIOD_NS + 1223);
		
		// generate communication
		miso_data_to_send = {12'h0b0};
		mosi_data_to_send = {12'hccf};
		
		// rise edge on SS
		ss_in = 1'b1;
		#(DATA_CLK_PERIOD_NS);
		
		// send data clocked by SCLK
		for (i = BUF_SIZE-1; i >= 0; i--) // send most significat bit first
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
		
		// send reset signal at the beginning
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
	
		// wait for bus control to be ready
		wait (bus_ready == 1'b1);
		
		// wait for communication active signal
		wait (comm_active == 1'b1);
		
		// next chunk command
		next_chunk_size = 4;
		fake_miso_select = 0;
		fake_mosi_select = 1;
		fake_miso_data = 4'h9 << (BUF_SIZE - 4);	// write buffers operate from most significant bit
		fake_mosi_data = 4'h8 << (BUF_SIZE - 4);	// write buffers operate from most significant bit
		
		cmd_next_chunk = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_next_chunk = 1'b0;
		
		// wait for bus to process command
		wait (bus_ready == 1'b1);
		
		// finish communication command
		fake_miso_select = 0;
		fake_mosi_select = 0;
		
		cmd_finish = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_finish = 1'b0;
		
		// wait for bus control to be ready
		wait (bus_ready == 1'b1);
		
		// wait for communication active signal
		wait (comm_active == 1'b1);
		
		// next chunk command
		next_chunk_size = 6;
		fake_miso_select = 1;
		fake_mosi_select = 1;
		fake_miso_data = 6'h37 << (BUF_SIZE - 6);	// write buffers operate from most significant bit
		fake_mosi_data = 6'h37 << (BUF_SIZE - 6);	// write buffers operate from most significant bit
		
		cmd_next_chunk = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_next_chunk = 1'b0;
		
		// wait for bus to process command
		wait (bus_ready == 1'b1);
		
		// next chunk command
		next_chunk_size = 4;
		fake_miso_select = 1;
		fake_mosi_select = 0;
		fake_miso_data = 4'ha << (BUF_SIZE - 4);	// write buffers operate from most significant bit;
		fake_mosi_data = 4'h1 << (BUF_SIZE - 4);	// write buffers operate from most significant bit;
		
		cmd_next_chunk = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_next_chunk = 1'b0;
		
		// send random reset signal
		#(2 * DATA_CLK_PERIOD_NS + 1123);
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
		
		// wait for bus to be ready
		wait (bus_ready == 1'b1);
		
		// wait for communication active signal
		wait (comm_active == 1'b1);
		
		// next chunk command
		next_chunk_size = 8;
		fake_miso_select = 1;
		fake_mosi_select = 1;
		fake_miso_data = 8'hf2 << (BUF_SIZE - 8);	// write buffers operate from most significant bit
		fake_mosi_data = 8'he5 << (BUF_SIZE - 8);	// write buffers operate from most significant bit
		
		cmd_next_chunk = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_next_chunk = 1'b0;
		
		// wait for bus to be ready
		wait (bus_ready == 1'b1);
		
		// finish communication command
		fake_miso_select = 0;
		fake_mosi_select = 0;
		
		cmd_finish = 1'b1;
		#(CLK_PERIOD_NS);
		cmd_finish = 1'b0;
		
		// wait for bus control to be ready
		wait (bus_ready == 1'b1);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("BusControl_test.vcd");
		$dumpvars(0, BusControl_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule