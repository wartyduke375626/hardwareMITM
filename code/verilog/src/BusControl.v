/**
 * SPI Bus control module:
 * - manages operation of smaller modules
 * - provides command interface for MITM logic module
 * - manages the bus communication based on commands and data inputs from MITM logic
**/

module BusControl #(

	// parameters
	parameter BUF_SIZE = 9,
	parameter CHUNK_SIZE_WIDTH = $clog2(BUF_SIZE+1)	// storing A requires exactly ceil(lg(A+1)) bits
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// bus line inputs
	input wire miso_in,
	input wire mosi_in,
	input wire sclk_in,
	input wire ss_in,
	
	// bus command inputs
	input wire cmd_next_chunk,
	input wire cmd_finish,
	
	input wire [CHUNK_SIZE_WIDTH-1:0] next_chunk_size,
	
	// data control inputs
	input wire fake_miso_select,
	input wire fake_mosi_select,
	
	// data inputs
	input wire [BUF_SIZE-1:0] fake_miso_data,
	input wire [BUF_SIZE-1:0] fake_mosi_data,
	
	// bus line outputs
	output wire miso_out,
	output wire mosi_out,
	output wire sclk_out,
	output wire ss_out,
	
	// bus status outputs
	output reg comm_active = 1'b0,
	output reg bus_ready = 1'b0,
	
	// data outputs
	output wire [BUF_SIZE-1:0] real_miso_data,
	output wire [BUF_SIZE-1:0] real_mosi_data
);
	
	// internal signals
	
	// edge signals
	wire sclk_rise_edge;
	wire sclk_fall_edge;
	
	wire ss_rise_edge;
	wire ss_fall_edge;
	
	// fake bus lines
	wire fake_miso_out;
	wire fake_mosi_out;
	
	// buffer control
	wire miso_read_done;
	wire mosi_read_done;
	wire miso_write_done;
	wire mosi_write_done;
	
	wire buf_done;
	assign buf_done = miso_read_done & mosi_read_done & miso_write_done & mosi_write_done;
	
	// internal registers
	
	// fake bus lines
	reg fake_sclk_out = 1'b0;
	reg fake_ss_out = 1'b0;
	
	// data control
	reg fake_sclk_select = 1'b0;
	reg fake_ss_select = 1'b0;
	
	// buffer control
	reg buf_start = 1'b0;
	
	reg	[2:0] state = STATE_RESET;
	
	// states
	localparam STATE_IDLE = 3'd0;
	localparam STATE_COMM = 3'd1;
	localparam STATE_BUF_START = 3'd2;
	localparam STATE_BUF_WAIT = 3'd3;
	localparam STATE_FINISH_COMM = 3'd4;
	localparam STATE_RESET = 3'd5;
	
	// control logic
	always @ (posedge sys_clk)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			bus_ready = 1'b0;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for SS rising edge and signal communication start
				STATE_IDLE: begin
					if (ss_rise_edge == 1'b1) begin
						comm_active <= 1'b1;
						state <= STATE_COMM;
					end
				end
				
				// communication state wait for control signal signal
				STATE_COMM: begin
				
					// process next chunk of communication
					if (cmd_next_chunk == 1'b1) begin
						buf_start <= 1'b1;
						bus_ready <= 1'b0;
						state <= STATE_BUF_START;
					end
					
					// go to communication finish state
					else if (cmd_finish == 1'b1) begin
						bus_ready <= 1'b0;
						state <= STATE_FINISH_COMM;
					end
				end
				
				// delay one clock cycle for buffers to process inputs
				STATE_BUF_START: begin
					buf_start <= 1'b0;
					state <= STATE_BUF_WAIT;
				end
				
				// wait for buffers to process communication chunk and go back to communication state
				STATE_BUF_WAIT: begin
					if (buf_done == 1'b1) begin
						bus_ready <= 1'b1;
						state <= STATE_COMM;
					end
				end
				
				// finish communication -- wait for SS falling edge
				STATE_FINISH_COMM: begin
					if (ss_fall_edge == 1'b1) begin
						comm_active <= 1'b0;
						bus_ready <= 1'b1;
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					buf_start <= 1'b0;
	
					fake_sclk_out <= 1'b0;
					fake_ss_out <= 1'b0;
					
					fake_sclk_select <= 1'b0;
					fake_ss_select <= 1'b0;
					
					comm_active <= 1'b0;
					bus_ready <= 1'b1;
					
					state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					bus_ready = 1'b0;
					state <= STATE_RESET;
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
		.BUF_SIZE(BUF_SIZE)
	) misoReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(buf_start),
		.read_sig(sclk_rise_edge),
		.data_in(miso_in),
		.read_count(next_chunk_size),
		.data_out(real_miso_data),
		.done_sig(miso_read_done)
	);
	
	// MOSI read buffer
	SerialReadBuffer #(
		.BUF_SIZE(BUF_SIZE)
	) mosiReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(buf_start),
		.read_sig(sclk_rise_edge),
		.data_in(mosi_in),
		.read_count(next_chunk_size),
		.data_out(real_mosi_data),
		.done_sig(mosi_read_done)
	);
	
	// MISO write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(BUF_SIZE)
	) misoWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(buf_start),
		.write_sig(sclk_fall_edge),
		.data_in(fake_miso_data),
		.write_count(next_chunk_size),
		.data_out(fake_miso_out),
		.done_sig(miso_write_done)
	);
	
	// MOSI write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(BUF_SIZE)
	) mosiWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(buf_start),
		.write_sig(sclk_fall_edge),
		.data_in(fake_mosi_data),
		.write_count(next_chunk_size),
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