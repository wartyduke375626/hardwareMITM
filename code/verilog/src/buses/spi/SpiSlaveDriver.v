/**
 * SPI slave driver module:
 * - implements the SPI physical layer protocol on the slave side
 * - provides an interface to send and receive data as SPI slave
 * - SPI mode 0 (CPOL = 0, CPHA = 0)is hardcoded
 * - the SS_ACTIVE_LOW parameter defines whether the SS line is active low
 * - the LSB_FIRST parameter defines bit order of data
 * - the NUM_DATA_BITS parameter defines the number of bits per transaction (both MOSI and MISO)
**/

module SpiSlaveDriver #(

	// parameters
	parameter SS_ACTIVE_LOW = 1,
	parameter LSB_FIRST = 0,
	parameter NUM_DATA_BITS = 8
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// control inputs
	input wire miso_send_enable,

	// status outputs
	output reg bus_ready = 1'b0,
	output reg mosi_new_data = 1'b0,
	
	// data
	input wire [NUM_DATA_BITS-1:0] miso_data,
	output wire [NUM_DATA_BITS-1:0] mosi_data,
	
	// bus lines
	input wire ss_in,
	input wire sclk_in,
	output wire miso_out,
	input wire mosi_in
);

	// local constants
	localparam BUF_SIZE = NUM_DATA_BITS;
	localparam BIT_COUNT_WIDTH = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal signals
	
	// edge signals
	wire sclk_rise_edge;
	wire sclk_fall_edge;
	
	// buffer control signals
	wire miso_buf_start;
	assign miso_buf_start = buf_start & miso_send_enable;
	
	// status signals
	wire miso_buf_done;
	wire mosi_buf_done;
	
	wire buf_done;
	assign buf_done = miso_buf_done & mosi_buf_done;
	
	// internal registers
	
	// control
	reg buf_start = 1'b0;
	reg buf_rst = 1'b0;
	
	// states
	localparam STATE_IDLE = 3'd0;
	localparam STATE_COMM_START = 3'd1;
	localparam STATE_COMM_WAIT = 3'd2;
	localparam STATE_COMM_FINISH = 3'd3;
	localparam STATE_RESET = 3'd4;
	
	reg	[2:0] state = STATE_RESET;
	
	// SPI transaction control logic
	always @ (posedge sys_clk)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			bus_ready <= 1'b0;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for SS line to go active and start buffering
				STATE_IDLE: begin
					if (ss_in == ((SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0)) begin
						bus_ready <= 1'b0;
						buf_start <= 1'b1;
						state <= STATE_COMM_START;
					end
				end
				
				// delay one clock cycle for buffers to process inputs
				STATE_COMM_START: begin
					buf_start <= 1'b0;
					state <= STATE_COMM_WAIT;
				end
				
				// wait for buffering to finish
				STATE_COMM_WAIT: begin
				
					// if SS goes inactive unexpectedly, reset buffers and go to reset state
					if (ss_in == ((SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1)) begin
						buf_rst <= 1'b1;
						state <= STATE_RESET;
					end
					
					// else wait for buffering to finish
					else if (buf_done == 1'b1) begin
						mosi_new_data <= 1'b1;
						state <= STATE_COMM_FINISH;
					end
				end
				
				// wait for SS to go inactive, signal ready and go to idle state
				STATE_COMM_FINISH: begin
					mosi_new_data <= 1'b0;
					
					if (ss_in == ((SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1)) begin
						bus_ready <= 1'b1;
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					buf_start <= 1'b0;
					buf_rst <= 1'b0;
					mosi_new_data <= 1'b0;
					bus_ready <= 1'b1;	
					state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					bus_ready <= 1'b0;
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
		.sig(sclk_in),
		.edge_sig(sclk_rise_edge)
	);
	
	// SCLK fall edge detector
	EdgeDetector #(
		.FALL_EDGE(1)
	) sclkFallEdgeDetect (
		.sys_clk(sys_clk),
		.sig(sclk_in),
		.edge_sig(sclk_fall_edge)
	);
	
	// MOSI read buffer
	SerialReadBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(LSB_FIRST)
	) mosiReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst | buf_rst),
		.start(buf_start),
		.read_sig(sclk_rise_edge),
		.in_line(mosi_in),
		.read_count(BUF_SIZE[BIT_COUNT_WIDTH-1:0]),
		.data_out(mosi_data),
		.done_sig(mosi_buf_done)
	);
	
	// MISO write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(LSB_FIRST),
		.ACTIVE_LOW(0)
	) misoWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst | buf_rst),
		.start(miso_buf_start),
		.write_sig(sclk_fall_edge),
		.data_in(miso_data),
		.write_count(BUF_SIZE[BIT_COUNT_WIDTH-1:0]),
		.out_line(miso_out),
		.done_sig(miso_buf_done)
	);
	
	/******************** ******************** ********************/
	
endmodule