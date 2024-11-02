/**
 * Main MITM control module:
 * - manages operation of modules
 * - sets and forwards control i/o between modules
**/

module MitmControl #(

	// parameters
	parameter	DATA_SIZE = 8,
	parameter	BUS_WIDTH = 4
) (
	
	// system inputs
	input		sys_clk,
	input		rst,
	
	// bus inputs
	input		miso_in,
	input		mosi_in,
	input		sclk_in,
	input		ss_in,
	
	// bus outputs
	output		miso_out,
	output		mosi_out,
	output		sclk_out,
	output		ss_out
);
	
	// internal signals
	wire					sclk_rise_edge_sig;
	wire					sclk_fall_edge_sig;
	
	wire					ss_rise_edge_sig;
	wire					ss_fall_edge_sig;
	
	wire	[DATA_SIZE-1:0]	miso_read_data;
	wire					miso_read_done;
	
	wire	[DATA_SIZE-1:0]	mosi_read_data;
	wire					mosi_read_done;
	
	wire	[DATA_SIZE-1:0]	fake_miso_data;
	wire	[DATA_SIZE-1:0]	fake_mosi_data;
	wire					fake_miso_select;
	wire					fake_mosi_select;
	wire					mitm_logic_done;
	
	wire					miso_write_done;
	wire					fake_miso_out;
	
	wire					mosi_write_done;
	wire					fake_mosi_out;
	
	// internal registers
	reg		miso_read_start = 1'b0;
	reg		mosi_read_start = 1'b0;
	
	reg		mitm_eval = 1'b0;
	
	reg		miso_write_start = 1'b0;
	reg		mosi_write_start = 1'b0;
	
	reg		fake_sclk_out = 1'b0;
	reg		fake_sclk_select = 1'b0;
	reg		fake_ss_out = 1'b0;
	reg		fake_ss_select = 1'b0;
	
	reg	[3:0]	state = STATE_RESET;
	
	// states
	localparam	STATE_IDLE			= 3'd0;
	localparam	STATE_READ_START	= 3'd1;
	localparam	STATE_READ			= 3'd2;
	localparam	STATE_MITM_START	= 3'd3;
	localparam	STATE_MITM			= 3'd4;
	localparam	STATE_WRITE_START	= 3'd5;
	localparam	STATE_WRITE			= 3'd6;
	localparam	STATE_DONE			= 3'd7;
	localparam	STATE_RESET			= 3'd8;
	
	// control logic
	always @ (posedge sys_clk or posedge rst)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for SS rising edge and signal read start
				STATE_IDLE: begin
					if (ss_rise_edge_sig == 1'b1) begin
						miso_read_start <= 1'b1;
						mosi_read_start <= 1'b1;
						state <= STATE_READ_START;
					end
				end
				
				// delay one clock cycle for reading to start
				STATE_READ_START: begin
					state <= STATE_READ;
				end
				
				// data reading state -- wait for data to be read and signal mitm evaluation
				STATE_READ: begin
					miso_read_start <= 1'b0;
					mosi_read_start <= 1'b0;
					if (miso_read_done & mosi_read_done == 1'b1) begin
						mitm_eval <= 1'b1;
						state <= STATE_MITM_START;
					end
				end
				
				// delay one clock cycle for mitm logic to start evaluating
				STATE_MITM_START: begin
					state <= STATE_MITM;
				end
				
				// MITM logic state -- wait for MITM logic to process inputs and signal write start
				STATE_MITM: begin
					mitm_eval <= 1'b0;
					if (mitm_logic_done == 1'b1) begin
						miso_write_start <= 1'b1;
						mosi_write_start <= 1'b1;
						state <= STATE_WRITE_START;
					end
				end
				
				// delay one clock cycle for for writing to start
				STATE_WRITE_START: begin
					state <= STATE_WRITE;
				end
				
				// data writing state -- wait for data to be written and go to done state
				STATE_WRITE: begin
					miso_write_start <= 1'b0;
					mosi_write_start <= 1'b0;
					if (miso_write_done & mosi_write_done == 1'b1) begin
						state <= STATE_DONE;
					end
				end
				
				// prepare for next iteration and wait for SS falling edge
				STATE_DONE: begin
					if (ss_fall_edge_sig == 1'b1) begin
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					miso_read_start <= 1'b0;
					mosi_read_start <= 1'b0;

					mitm_eval <= 1'b0;
	
					miso_write_start <= 1'b0;
					mosi_write_start <= 1'b0;
	
					fake_sclk_out <= 1'b0;
					fake_sclk_select <= 1'b0;
					fake_ss_out <= 1'b0;
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
		.edge_sig(sclk_rise_edge_sig)
	);
	
	// SCLK fall edge detector
	EdgeDetector #(
		.FALL_EDGE(1)
	) sclkFallEdgeDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(sclk_in),
		.edge_sig(sclk_fall_edge_sig)
	);
	
	// SS rise edge detector
	EdgeDetector #(
		.FALL_EDGE(0)
	) ssRiseEdgeDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(ss_in),
		.edge_sig(ss_rise_edge_sig)
	);
	
	// SS fall edge detector
	EdgeDetector #(
		.FALL_EDGE(1)
	) ssFallEdgeDetect (
		.sys_clk(sys_clk),
		.rst(rst),
		.sig(ss_in),
		.edge_sig(ss_fall_edge_sig)
	);
	
	
	// MISO read buffer
	SerialReadBuffer #(
		.BUF_SIZE(DATA_SIZE)
	) misoReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(miso_read_start),
		.read_sig(sclk_rise_edge_sig),
		.data_in(miso_in),
		.data_out(miso_read_data),
		.done_sig(miso_read_done)
	);
	
	// MOSI read buffer
	SerialReadBuffer #(
		.BUF_SIZE(DATA_SIZE)
	) mosiReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(mosi_read_start),
		.read_sig(sclk_rise_edge_sig),
		.data_in(mosi_in),
		.data_out(mosi_read_data),
		.done_sig(mosi_read_done)
	);
	
	
	// MITM logic
	MitmLogic #(
		.DATA_SIZE(DATA_SIZE)
	) mitmLogic (
		.sys_clk(sys_clk),
		.rst(rst),
		.eval(mitm_eval),
		.real_miso_data(miso_read_data),
		.real_mosi_data(mosi_read_data),
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data),
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		.done_sig(mitm_logic_done)
	);
	
	
	// MISO write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(DATA_SIZE)
	) misoWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(miso_write_start),
		.write_sig(sclk_fall_edge_sig),
		.data_in(fake_miso_data),
		.data_out(fake_miso_out),
		.done_sig(miso_write_done)
	);
	
	// MOSI write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(DATA_SIZE)
	) mosiWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(mosi_write_start),
		.write_sig(sclk_fall_edge_sig),
		.data_in(fake_mosi_data),
		.data_out(fake_mosi_out),
		.done_sig(mosi_write_done)
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