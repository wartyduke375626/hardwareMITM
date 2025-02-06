/**
 * Simulation of Serial read buffer.
**/

// define timescale
`timescale 1 ns / 10 ps

module SerialReadBuffer_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 50_000;	// 50 us
	localparam IN_LINE_CLK_PERIOD_NS = 8 * CLK_PERIOD_NS;	// data rate has to be slower then sys_clk
	
	localparam BUF_SIZE = 8;
	localparam LSB_FIRST = 0;
	localparam READ_COUNT_SIZE = $clog2(BUF_SIZE+1);
	
	// test signals
	wire [BUF_SIZE-1:0] data_out;
	wire done_sig;
	wire read_sig;
	
	// test registers
	reg sys_clk = 1'b0;
	reg data_clk = 1'b0;	// virtual clock to send data on input line
	reg rst = 1'b0;
	reg start = 1'b0;
	reg in_line = 1'b0;
	reg signal_in_line = 1'b0;
	reg [READ_COUNT_SIZE-1:0] read_count = 0;
	
	// helper variables
	reg [BUF_SIZE-1:0] data_to_send;
	
	// helper task to simulate data being sent
	task send_data(input integer data_len);
		integer i;
		
		signal_in_line = 1'b1;
		#(IN_LINE_CLK_PERIOD_NS);
		for (i = data_len-1; i >= 0; i--)	// send most significat bit first
		begin
			data_clk = 1'b0;
			in_line = data_to_send[i];
			#(IN_LINE_CLK_PERIOD_NS / 2);
			data_clk = 1'b1;
			#(IN_LINE_CLK_PERIOD_NS / 2);
		end
		data_clk = 1'b0;
		in_line = 1'b0;
		#(IN_LINE_CLK_PERIOD_NS);
		signal_in_line = 1'b0;
	endtask
	
	// instantiate edge detector to generate synchronous read signal
	EdgeDetector #(
		.FALL_EDGE(0)
	) dataInDetect (
		.sys_clk(sys_clk),
		.sig(data_clk),
		.edge_sig(read_sig)
	);
	
	// instantiate uut
	SerialReadBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(LSB_FIRST)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(start),
		.read_sig(read_sig),
		.in_line(in_line),
		.read_count(read_count),
		.data_out(data_out),
		.done_sig(done_sig)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
	end
	
	// generate some data on input line, clocked by data_clk
	initial
	begin
		// wait some time
		#100;
		
		// send reset signal at the beginning
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
	
		// wait some time for initialization
		#(2*CLK_PERIOD_NS);
		
		// send 8 bits of data
		data_to_send = 8'h3a;
		send_data(8);
		
		// wait random time
		#(IN_LINE_CLK_PERIOD_NS + 517);
		
		// send 6 bits of data
		data_to_send = 6'o52;
		send_data(6);
		
		// wait random time
		#(IN_LINE_CLK_PERIOD_NS + 1119);
		
		// send 4 bits of data
		data_to_send = 4'hf;
		send_data(4);
	end
	
	// test code
	initial
	begin
		// wait for data sending signal
		wait (signal_in_line == 1'b1);
		
		// send signal to start reading byte
		read_count = 8;
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait for buffer to read data
		wait (done_sig == 1'b1);
		
		// wait for data sending signal
		wait (signal_in_line == 1'b0);
		wait (signal_in_line == 1'b1);
		
		// send signal to start reading byte
		read_count = 6;
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// generate random reset signal
		#3333
		rst = 1'b1;
		#(CLK_PERIOD_NS);
		rst = 1'b0;
		
		// wait for buffer to reset
		wait (done_sig == 1'b1);
		
		// wait for data sending signal
		wait (signal_in_line == 1'b0);
		wait (signal_in_line == 1'b1);
		
		// send signal to start reading byte
		read_count = 4;
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