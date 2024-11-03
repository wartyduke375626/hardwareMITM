/**
 * Simulation of Serial write buffer.
**/

// define timescale
`timescale 1 ns / 10 ps

module SerialWriteBuffer_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 50_000;	// 50 us
	localparam DATA_OUT_CLK_PERIOD_NS = 8 * CLK_PERIOD_NS;	// data rate has to be slower then sys_clk
	
	localparam BUF_SIZE = 8;
	
	// internal signals
	wire data_out;
	wire done_sig;
	wire  write_sig;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg data_clk = 1'b0; // virtual clock to write data on output line
	reg rst = 1'b0;
	reg start = 1'b0;
	reg [BUF_SIZE-1:0] data_in = 0;
	reg signal_data_out = 1'b0;
	
	// helper variables
	integer i;
	reg [0:7] data_to_send; // send most significat bit first
	
	// instantiate edge detector to generate synchronous write signal
	EdgeDetector #(
		.FALL_EDGE(1)	// we want our buffer to synchronize on falling edge (data needs to be present on next rising edge)
	) dataInDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(data_clk),
		.edge_sig(write_sig)
	);
	
	// instantiate uut
	SerialWriteBuffer #(
		.BUF_SIZE(BUF_SIZE)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(start),
		.write_sig(write_sig),
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
	
	// generate data output line clock
	initial
	begin
		// wait some time before sending data
		#2500
		
		// send 8 bits of data
		signal_data_out = 1'b1;
		#(DATA_OUT_CLK_PERIOD_NS);
		for (i = 0; i < 8; i++)
		begin
			data_clk = 1'b0;
			#(DATA_OUT_CLK_PERIOD_NS / 2);
			data_clk = 1'b1;
			#(DATA_OUT_CLK_PERIOD_NS / 2);
		end
		data_clk = 1'b0;
		#(DATA_OUT_CLK_PERIOD_NS);
		signal_data_out = 1'b0;
		
		// wait random time
		#(DATA_OUT_CLK_PERIOD_NS + 371);
		
		// send 8 bits of data
		signal_data_out = 1'b1;
		#(DATA_OUT_CLK_PERIOD_NS);
		for (i = 0; i < 8; i++)
		begin
			data_clk = 1'b0;
			#(DATA_OUT_CLK_PERIOD_NS / 2);
			data_clk = 1'b1;
			#(DATA_OUT_CLK_PERIOD_NS / 2);
		end
		data_clk = 1'b0;
		#(DATA_OUT_CLK_PERIOD_NS);
		signal_data_out = 1'b0;
		
		// wait random time
		#(DATA_OUT_CLK_PERIOD_NS + 973);
		
		// send 8 bits of data
		signal_data_out = 1'b1;
		#(DATA_OUT_CLK_PERIOD_NS);
		for (i = 0; i < 8; i++)
		begin
			data_clk = 1'b0;
			#(DATA_OUT_CLK_PERIOD_NS / 2);
			data_clk = 1'b1;
			#(DATA_OUT_CLK_PERIOD_NS / 2);
		end
		data_clk = 1'b0;
		#(DATA_OUT_CLK_PERIOD_NS);
		signal_data_out = 1'b0;
	end
	
	// test code
	initial
	begin
		// wait for data sending signal
		wait (signal_data_out == 1'b1);
		
		// set byte to write
		data_in = 8'h9c;
		
		// send signal to start writing byte
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait for buffer to write data
		wait (done_sig == 1'b1);
		
		// wait for data sending signal
		wait (signal_data_out == 1'b0);
		wait (signal_data_out == 1'b1);
		
		// set byte to write
		data_in = 8'he4;
		
		// send signal to start reading byte
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// pulse random reset signal
		#2929
		rst = 1'b1;
		#1;
		rst = 1'b0;
		
		// wait for buffer to reset
		wait (done_sig == 1'b1);
		
		// wait for data sending signal
		wait (signal_data_out == 1'b0);
		wait (signal_data_out == 1'b1);
		
		// set byte to write
		data_in = 8'hb5;
		
		// send signal to start reading byte 2
		start = 1'b1;
		#(CLK_PERIOD_NS);
		start = 1'b0;
		
		// wait for buffer to write data
		wait (done_sig == 1'b1);
		
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("SerialWriteBuffer_test.vcd");
		$dumpvars(0, SerialWriteBuffer_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule