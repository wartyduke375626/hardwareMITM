/**
 * Simulation of MITM Logic module.
**/

// define timescale
`timescale 1 ns / 10 ps

module MitmLogic_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 30_000;	// 30 us
	
	localparam BUF_SIZE = 9;
	localparam CHUNK_SIZE_WIDTH = $clog2(BUF_SIZE+1);
	
	localparam NUM_MITM_MODES = 2;
	localparam MITM_MODE_FORWARD = 2'b01;
	localparam MITM_MODE_SUB_ALL = 2'b10;
	
	// internal signals
	wire cmd_next_chunk;
	wire cmd_finish;
	wire [CHUNK_SIZE_WIDTH-1:0] next_chunk_size;
	
	wire fake_miso_select;
	wire fake_mosi_select;
	
	wire [BUF_SIZE-1:0] fake_miso_data;
	wire [BUF_SIZE-1:0] fake_mosi_data;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	reg [NUM_MITM_MODES-1:0] mode_select = MITM_MODE_FORWARD;

	reg comm_active = 1'b0;
	reg bus_ready = 1'b1;
	
	reg [BUF_SIZE-1:0] real_miso_data;
	reg [BUF_SIZE-1:0] real_mosi_data;

	// instantiate uut
	MitmLogic #( 
		.BUF_SIZE(BUF_SIZE),
		
		.NUM_MITM_MODES(NUM_MITM_MODES),
		.MITM_MODE_FORWARD(MITM_MODE_FORWARD),
		.MITM_MODE_SUB_ALL(MITM_MODE_SUB_ALL)
	) UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.mode_select(mode_select),
		
		.comm_active(comm_active),
		.bus_ready(bus_ready),
		
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data),
		
		.cmd_next_chunk(cmd_next_chunk),
		.cmd_finish(cmd_finish),
		
		.next_chunk_size(next_chunk_size),
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		sys_clk = ~sys_clk;
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
	
		// wait some time for initialization
		#(2*CLK_PERIOD_NS);
		
		// set mode to 'forward'
		mode_select = MITM_MODE_FORWARD;
		
		// simulate receival of read communication through Bus control interface
		
		// signal communication active
		comm_active = 1'b1;
		
		// wait for next chunk command
		wait (cmd_next_chunk == 1'b1);
		
		bus_ready = 1'b0;
		
		// simulate read instruction return
		real_miso_data = 9'b0;
		real_mosi_data = {6'b0, 3'b110};
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// wait for next chunk command
		wait (cmd_next_chunk == 1'b1);
		
		bus_ready = 1'b0;
		
		// simulate address return
		real_miso_data = 9'b0;
		real_mosi_data = 9'h14a;
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// wait for finish command
		wait (cmd_finish == 1'b1);
		
		bus_ready = 1'b0;
		
		// simulate data return
		real_miso_data = 8'b0;
		real_mosi_data = 8'haa;
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// signal communication done
		comm_active = 1'b0;
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		
		// set mode to 'sub_all'
		mode_select = MITM_MODE_SUB_ALL;
		
		// simulate receival of read communication through Bus control interface
		
		// signal communication active
		comm_active = 1'b1;
		
		// wait for next chunk command
		wait (cmd_next_chunk == 1'b1);
		
		bus_ready = 1'b0;
		
		// simulate read instruction return
		real_miso_data = 9'b0;
		real_mosi_data = {6'b0, 3'b110};
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// wait for next chunk command
		wait (cmd_next_chunk == 1'b1);
		
		bus_ready = 1'b0;
		
		// simulate address return
		real_miso_data = 9'b0;
		real_mosi_data = 9'h14a;
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// wait for next chunk command
		wait (cmd_next_chunk == 1'b1);
		
		bus_ready = 1'b0;
		
		// simulate data return
		real_miso_data = 8'b0;
		real_mosi_data = 8'haa;
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// wait for finish command
		wait (cmd_finish == 1'b1);
		
		bus_ready = 1'b0;
		
		// wait some time
		#(2*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// signal communication done
		comm_active = 1'b0;
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		
		// simulate receival of write communication through Bus control interface
		
		// signal communication active
		comm_active = 1'b1;
		
		// wait for next chunk command
		wait (cmd_next_chunk == 1'b1);
		
		bus_ready = 1'b0;
		
		// simulate write instruction return
		real_miso_data = 9'b0;
		real_mosi_data = {6'b0, 3'b101};
		
		// wait some time
		#(4*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// wait for finish command
		wait (cmd_finish == 1'b1);
		
		bus_ready = 1'b0;
		
		// wait some time
		#(6*CLK_PERIOD_NS);
		
		// signal ready
		bus_ready = 1'b1;
		
		// signal communication done
		comm_active = 1'b0;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("MitmLogic_test.vcd");
		$dumpvars(0, MitmLogic_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule