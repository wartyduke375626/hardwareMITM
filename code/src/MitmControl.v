/**
 * Main MITM control module:
 * - manages operation of modules
 * - sets and forwards control i/o between modules
**/

module MitmControl (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// bus inputs
	input wire miso_in,
	input wire mosi_in,
	input wire sclk_in,
	input wire ss_in,
	
	// bus outputs
	output wire miso_out,
	output wire mosi_out,
	output wire sclk_out,
	output wire ss_out
);

	// local constants
	localparam BUS_WIDTH = 4;
	localparam MAX_DATA_SIZE = 9;
	localparam DATA_SIZE_WIDTH = $clog2(MAX_DATA_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal signals
	
	// edge signals
	wire sclk_rise_edge;
	wire sclk_fall_edge;
	
	wire ss_rise_edge;
	wire ss_fall_edge;
	
	// data lines
	wire [MAX_DATA_SIZE-1:0] real_miso_data;
	wire [MAX_DATA_SIZE-1:0] real_mosi_data;
	
	wire [MAX_DATA_SIZE-1:0] fake_miso_data;
	wire [MAX_DATA_SIZE-1:0] fake_mosi_data;
	
	wire fake_miso_out;
	wire fake_mosi_out;
	
	// data control
	wire [DATA_SIZE_WIDTH-1:0] data_size;
	
	wire fake_miso_select;
	wire fake_mosi_select;
	
	// module control
	wire miso_read_done;
	wire mosi_read_done;
	wire miso_write_done;
	wire mosi_write_done;
	
	wire comm_done;
	assign comm_done = miso_read_done & mosi_read_done & miso_write_done & mosi_write_done;
	
	wire mitm_logic_done;
	wire mitm_logic_eval_done;
	
	// internal registers
	
	// data lines
	reg fake_sclk_out = 1'b0;
	reg fake_ss_out = 1'b0;
	
	// data control
	reg fake_sclk_select = 1'b0;
	reg fake_ss_select = 1'b0;
	
	// control
	reg comm_start = 1'b0;
	reg mitm_eval = 1'b0;
	reg mitm_start = 1'b0;
	
	reg	[3:0] state = STATE_RESET;
	
	// states
	localparam STATE_IDLE = 4'd0;
	localparam STATE_MITM_START = 4'd1;
	localparam STATE_MITM_CYCLE = 4'd2;
	localparam STATE_MITM_EVAL_START = 4'd3;
	localparam STATE_MITM_EVAL = 4'd4;
	localparam STATE_COMM_START = 4'd5;
	localparam STATE_COMM = 4'd6;
	localparam STATE_DONE = 4'd7;
	localparam STATE_RESET = 4'd8;
	
	// control logic
	always @ (posedge sys_clk)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for SS rising edge and signal MITM logic to start
				STATE_IDLE: begin
					if (ss_rise_edge == 1'b1) begin
						mitm_start <= 1'b1;
						state <= STATE_MITM_START;
					end
				end
				
				// delay one clock cycle for MITM logic to start
				STATE_MITM_START: begin
					mitm_start <= 1'b0;
					state <= STATE_MITM_CYCLE;
				end
				
				// start of MITM communication segment -- signal MITM to evaluate data and go to next state
				STATE_MITM_CYCLE: begin
					mitm_eval <= 1'b1;
					state <= STATE_MITM_EVAL_START;
				end
				
				// delay one clock cycle for MITM logic to start evaluating
				STATE_MITM_EVAL_START: begin
					mitm_eval <= 1'b0;
					state <= STATE_MITM_EVAL;
				end
				
				// MITM logic evaluation state -- wait for MITM logic to process data
				STATE_MITM_EVAL: begin
					if (mitm_logic_eval_done == 1'b1) begin
					
						// if MITM logic signals done, go to done state
						if (mitm_logic_done == 1'b1) begin
							state <= STATE_DONE;
						end
						
						// else signal communication buffering start
						else begin
							comm_start <= 1'b1;
							state <= STATE_COMM_START;
						end
					end
				end
				
				// delay one clock cycle for communication buffering to start
				STATE_COMM_START: begin
					comm_start <= 1'b0;
					state <= STATE_COMM;
				end
				
				// communication buffering state -- wait for data to be transfered and go to next MITM cycle
				STATE_COMM: begin
					if (comm_done == 1'b1) begin
						state <= STATE_MITM_CYCLE;
					end
				end
				
				// prepare for next communication -- wait for SS falling edge
				STATE_DONE: begin
					if (ss_fall_edge == 1'b1) begin
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					comm_start <= 1'b0;
					mitm_eval <= 1'b0;
					mitm_start <= 1'b0;
	
					fake_sclk_out <= 1'b0;
					fake_ss_out <= 1'b0;
					
					fake_sclk_select <= 1'b0;
					fake_ss_select <= 1'b0;
					
					state <= STATE_IDLE;
				end
				
			endcase
		end
	end
	
	
	/******************** MODULE INSTANTIATION ********************/
	
	// SCLK rise edge detector
	EdgeDetector #(
		.FALL_EDGE(0)
	) sclkRiseEdgeDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(sclk_in),
		.edge_sig(sclk_rise_edge)
	);
	
	// SCLK fall edge detector
	EdgeDetector #(
		.FALL_EDGE(1)
	) sclkFallEdgeDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(sclk_in),
		.edge_sig(sclk_fall_edge)
	);
	
	// SS rise edge detector
	EdgeDetector #(
		.FALL_EDGE(0)
	) ssRiseEdgeDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(ss_in),
		.edge_sig(ss_rise_edge)
	);
	
	// SS fall edge detector
	EdgeDetector #(
		.FALL_EDGE(1)
	) ssFallEdgeDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(ss_in),
		.edge_sig(ss_fall_edge)
	);
	
	
	// MISO read buffer
	SerialReadBuffer #(
		.BUF_SIZE(MAX_DATA_SIZE)
	) misoReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(comm_start),
		.read_sig(sclk_rise_edge),
		.data_in(miso_in),
		.read_count(data_size),
		.data_out(real_miso_data),
		.done_sig(miso_read_done)
	);
	
	// MOSI read buffer
	SerialReadBuffer #(
		.BUF_SIZE(MAX_DATA_SIZE)
	) mosiReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(comm_start),
		.read_sig(sclk_rise_edge),
		.data_in(mosi_in),
		.read_count(data_size),
		.data_out(real_mosi_data),
		.done_sig(mosi_read_done)
	);
	
	// MISO write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(MAX_DATA_SIZE)
	) misoWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(comm_start),
		.write_sig(sclk_fall_edge),
		.data_in(fake_miso_data),
		.write_count(data_size),
		.data_out(fake_miso_out),
		.done_sig(miso_write_done)
	);
	
	// MOSI write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(MAX_DATA_SIZE)
	) mosiWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(comm_start),
		.write_sig(sclk_fall_edge),
		.data_in(fake_mosi_data),
		.write_count(data_size),
		.data_out(fake_mosi_out),
		.done_sig(mosi_write_done)
	);
	
	
	// MITM logic
	MitmLogic mitmLogic (
		.sys_clk(sys_clk),
		.rst(rst),
		.eval(mitm_eval),
		.mitm_start(mitm_start),
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data),
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data),
		.data_size(data_size),
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		.eval_done(mitm_logic_eval_done),
		.mitm_done(mitm_logic_done)
	);
	
	
	// Output multiplexer
	OutputMux #(
		.WIDTH(4)
	) outputMux (
		.in_line0({miso_in, mosi_in, sclk_in, ss_in}),
		.in_line1({fake_miso_out, fake_mosi_out, fake_sclk_out, fake_ss_out}),
		.select_line({fake_miso_select, fake_mosi_select, fake_sclk_select, fake_ss_select}),
		.out_line({miso_out, mosi_out, sclk_out, ss_out})
	);
	
	/******************** ******************** ********************/
	
endmodule