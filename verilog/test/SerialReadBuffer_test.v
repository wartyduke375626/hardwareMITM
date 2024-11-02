/**
 * Simulation of Serial read buffer.
**/

// define timescale
`timescale 1 ns / 10 ps

module SerialReadBuffer_test();

	// local constants
	localparam	SYS_CLK	= 12_000_000;	// 12 MHz
	localparam	CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam	SIM_DURATION = 50_000;	// 50 us
	localparam	DATA_IN_CLK_PERIOD_NS = 8 * CLK_PERIOD_NS; // data rate has to be slower then sys_clk
	
	localparam	BUF_SIZE = 8;
	
	// internal signals
	wire	[BUF_SIZE-1:0]	data_out;
	wire					done_sig;
	wire 					read_sig;
	
	// internal registers
	reg		sys_clk = 1'b0;
	reg		data_clk = 1'b0; // virtual clock to send data on input line
	reg		rst = 1'b0;
	reg		start = 1'b0;
	reg		data_in = 1'b0;
	reg		signal_data_in = 1'b0;
	
	// helper variables
	integer					i;
	reg		[BUF_SIZE-1:0]	data_to_send;
	
	// instantiate edge detector to generate synchronous read signal
	EdgeDetector #(
		.FALL_EDGE(0)
	) dataInDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(data_clk),
		.edge_sig(read_sig)
	);
	
	// instantiate uut
	SerialReadBuffer #(
		.BUF_SIZE(BUF_SIZE)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(start),
		.read_sig(read_sig),
		.data_in(data_in),
		.data_out(data_out),
		.done_sig(done_sig)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// pulse reset line high at the begining
	initial
	begin
		#10;
		rst = 1'b1;
		#1;
		rst = 1'b0;
	end
	
	// generate some data on input line, clocked by data_clk
	initial
	begin
		// wait some time before sending data
		#2500
		
		// send 8 bits of data
		data_to_send = 8'h3a; // byte to send is indexed as msb
		signal_data_in = 1'b1;
		#(DATA_IN_CLK_PERIOD_NS);
		for (i = BUF_SIZE-1; i >= 0; i--) // send most significat bit first
		begin
			data_clk = 1'b0;
			data_in = data_to_send[i];
			#(DATA_IN_CLK_PERIOD_NS / 2);
			data_clk = 1'b1;
			#(DATA_IN_CLK_PERIOD_NS / 2);
		end
		data_clk = 1'b0;
		data_in = 1'b0;
		#(DATA_IN_CLK_PERIOD_NS);
		signal_data_in = 1'b0;
		
		// wait random time
		#(DATA_IN_CLK_PERIOD_NS + 517);
		
		// send 8 bits of data
		data_to_send = 8'h71; // byte to send is indexed as msb
		signal_data_in = 1'b1;
		#(DATA_IN_CLK_PERIOD_NS);
		for (i = BUF_SIZE-1; i >= 0; i--) // send most significat bit first
		begin
			data_clk = 1'b0;
			data_in = data_to_send[i];
			#(DATA_IN_CLK_PERIOD_NS / 2);
			data_clk = 1'b1;
			#(DATA_IN_CLK_PERIOD_NS / 2);
		end
		data_clk = 1'b0;
		data_in = 1'b0;
		#(DATA_IN_CLK_PERIOD_NS);
		signal_data_in = 1'b0;
		
		// wait random time
		#(DATA_IN_CLK_PERIOD_NS + 1119);
		
		// send 8 bits of data
		data_to_send = 8'hf0; // byte to send is indexed as msb
		signal_data_in = 1'b1;
		#(DATA_IN_CLK_PERIOD_NS);
		for (i = BUF_SIZE-1; i >= 0; i--) // send most significat bit first
		begin
			data_clk = 1'b0;
			data_in = data_to_send[i];
			#(DATA_IN_CLK_PERIOD_NS / 2);
			data_clk = 1'b1;
			#(DATA_IN_CLK_PERIOD_NS / 2);
		end
		data_clk = 1'b0;
		data_in = 1'b0;
		#(DATA_IN_CLK_PERIOD_NS);
		signal_data_in = 1'b0;
	end
	
	// test code
	initial
	begin
		// wait for data sending signal
		wait (signal_data_in == 1'b1);
		
		// send signal to start reading byte
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait for buffer to read data
		wait (done_sig == 1'b1);
		
		// wait for data sending signal
		wait (signal_data_in == 1'b0);
		wait (signal_data_in == 1'b1);
		
		// send signal to start reading byte
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// pulse random reset signal
		#3333
		rst = 1'b1;
		#1;
		rst = 1'b0;
		
		// wait for buffer to reset
		wait (done_sig == 1'b1);
		
		// wait for data sending signal
		wait (signal_data_in == 1'b0);
		wait (signal_data_in == 1'b1);
		
		// send signal to start reading byte 2
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait for buffer to read data
		wait (done_sig == 1'b1);
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("SerialReadBuffer_test.vcd");
		$dumpvars(0, SerialReadBuffer_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule