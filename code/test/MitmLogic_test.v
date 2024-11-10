/**
 * Simulation of MITM Logic module.
**/

// define timescale
`timescale 1 ns / 10 ps

module MitmLogic_test();

	// local constants
	localparam SYS_CLK = 12_000_000;	// 12 MHz
	localparam CLK_PERIOD_NS = 1_000_000_000 / SYS_CLK;
	localparam SIM_DURATION = 10_000;	// 10 us
	
	localparam MAX_DATA_SIZE = 9;
	localparam DATA_SIZE_WIDTH = $clog2(MAX_DATA_SIZE+1);
	
	// internal signals
	wire [MAX_DATA_SIZE-1:0] fake_miso_data;
	wire [MAX_DATA_SIZE-1:0] fake_mosi_data;
	wire [DATA_SIZE_WIDTH-1:0] data_size;
	wire fake_miso_select;
	wire fake_mosi_select;
	wire eval_done;
	wire mitm_done;
	
	// internal registers
	reg sys_clk = 1'b0;
	reg rst = 1'b0;
	reg eval = 1'b0;
	reg mitm_start = 1'b0;
	
	reg [MAX_DATA_SIZE-1:0] real_miso_data;
	reg [MAX_DATA_SIZE-1:0] real_mosi_data;
	

	// instantiate uut
	MitmLogic UUT (
		.sys_clk(sys_clk),
		.rst(rst),
		.eval(eval),
		.mitm_start(mitm_start),
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data),
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data),
		.data_size(data_size),
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		.eval_done(eval_done),
		.mitm_done(mitm_done)
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
		
		// wait for evaluation
		wait (eval_done == 1'b1);
		
		// start MITM logic
		mitm_start <= 1'b1;
		#(CLK_PERIOD_NS);
		mitm_start <= 1'b0;
		
		// wait for evaluation
		wait (eval_done == 1'b1);
		
		// evaluate initial condition
		eval = 1'b1;
		#(CLK_PERIOD_NS);
		eval = 1'b0;
		#(CLK_PERIOD_NS);
		
		// wait for evaluation
		wait (eval_done == 1'b1);
		
		// emulate communication data
		real_miso_data = 9'd0;
		real_mosi_data = {6'd0, 3'b110};	// read instruction
		
		// evaluate
		eval = 1'b1;
		#(CLK_PERIOD_NS);
		eval = 1'b0;
		#(CLK_PERIOD_NS);
		
		// wait for evaluation
		wait (eval_done == 1'b1);
		
		// emulate communication data
		real_miso_data = 9'd0;
		real_mosi_data = {1'b0, 8'ha2};	// address operand
		
		// evaluate
		eval = 1'b1;
		#(CLK_PERIOD_NS);
		eval = 1'b0;
		#(CLK_PERIOD_NS);
		
		// wait for evaluation
		wait (eval_done == 1'b1);
		
		// emulate communication data
		real_miso_data = {1'b0, 8'hd9};	// data read
		real_mosi_data = 9'd0;
		
		// evaluate
		eval = 1'b1;
		#(CLK_PERIOD_NS);
		eval = 1'b0;
		#(CLK_PERIOD_NS);
		
		// wait for evaluation
		wait (eval_done == 1'b1);
		
		// wait for MITM logic to end
		wait (mitm_done == 1'b1);
		
		#100;
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