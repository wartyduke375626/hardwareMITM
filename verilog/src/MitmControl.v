/**
 * Main MITM control module:
 * - manages operation of modules
 * - sets and forwards control i/o between modules
**/

module MitmControl #(

	// parameters
	parameter DATA_SIZE = 8,
	parameter BUS_WIDTH = 4
) (
	
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
	
	// internal signals
	
	// edge signals
	wire sclk_rise_edge;
	wire sclk_fall_edge;
	
	wire ss_rise_edge;
	wire ss_fall_edge;
	
	// data lines
	wire [DATA_SIZE-1:0] real_miso_data;
	wire [DATA_SIZE-1:0] real_mosi_data;
	
	wire [DATA_SIZE-1:0] fake_miso_data;
	wire [DATA_SIZE-1:0] fake_mosi_data;
	
	wire fake_miso_out;
	wire fake_mosi_out;
	
	// data control
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
	
	reg	[2:0] state = STATE_RESET;
	
	// states
	localparam STATE_IDLE = 3'd0;
	localparam STATE_COMM_START = 3'd1;
	localparam STATE_COMM = 3'd2;
	localparam STATE_MITM_START = 3'd3;
	localparam STATE_MITM = 3'd4;
	localparam STATE_DONE = 3'd5;
	localparam STATE_RESET = 3'd6;
	
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
				
				// in idle state wait for SS rising edge and signal communication buffering start
				STATE_IDLE: begin
					if (ss_rise_edge == 1'b1) begin
						comm_start <= 1'b1;
						state <= STATE_COMM_START;
					end
				end
				
				// delay one clock cycle for communication buffering to start
				STATE_COMM_START: begin
					state <= STATE_COMM;
				end
				
				// communication buffering state -- wait for data to be transfered and signal mitm evaluation
				STATE_COMM: begin
					comm_start <= 1'b0;
					if (comm_done == 1'b1) begin
						mitm_eval <= 1'b1;
						state <= STATE_MITM_START;
					end
				end
				
				// delay one clock cycle for mitm logic to start evaluating
				STATE_MITM_START: begin
					state <= STATE_MITM;
				end
				
				// MITM logic state -- wait for MITM logic to process inputs and go to done state
				STATE_MITM: begin
					mitm_eval <= 1'b0;
					if (mitm_logic_done == 1'b1) begin
						state <= STATE_DONE;
					end
				end
				
				// prepare for next iteration -- wait for SS falling edge
				STATE_DONE: begin
					if (ss_fall_edge == 1'b1) begin
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					comm_start <= 1'b0;
					mitm_eval <= 1'b0;
	
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
		.BUF_SIZE(DATA_SIZE)
	) misoReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(comm_start),
		.read_sig(sclk_rise_edge),
		.data_in(miso_in),
		.data_out(real_miso_data),
		.done_sig(miso_read_done)
	);
	
	// MOSI read buffer
	SerialReadBuffer #(
		.BUF_SIZE(DATA_SIZE)
	) mosiReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(comm_start),
		.read_sig(sclk_rise_edge),
		.data_in(mosi_in),
		.data_out(real_mosi_data),
		.done_sig(mosi_read_done)
	);
	
	// MISO write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(DATA_SIZE)
	) misoWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(comm_start),
		.write_sig(sclk_fall_edge),
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
		.start(comm_start),
		.write_sig(sclk_fall_edge),
		.data_in(fake_mosi_data),
		.data_out(fake_mosi_out),
		.done_sig(mosi_write_done)
	);
	
	
	// MITM logic
	MitmLogic #(
		.DATA_SIZE(DATA_SIZE)
	) mitmLogic (
		.sys_clk(sys_clk),
		.rst(rst),
		.eval(mitm_eval),
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data),
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data),
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		.done_sig(mitm_logic_done)
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