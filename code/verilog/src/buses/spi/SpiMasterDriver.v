/**
 * SPI master driver module:
 * - implements the SPI physical layer protocol on the master side
 * - provides an interface to send and receive data as SPI master
 * - SPI mode 0 (CPOL = 0, CPHA = 0)is hardcoded
 * - SS setup and hold times are hardcoded to 1/4 of an SCLK period
 * - the CLOCK_DIV parameter defines the colock speed (the system clock is devided by this value) and must be 0 mod 4 (otherwise it is rounded down)
 * - the SS_ACTIVE_LOW parameter defines whether the SS line is active low
 * - the LSB_FIRST parameter defines bit order of data
 * - the NUM_DATA_BITS parameter defines the number of bits to buffer (one transaction may contain multiple MISO/MOSI send/recv buffering sessions)
**/

module SpiMasterDriver #(

	// parameters
	parameter CLOCK_DIV = 8,
	parameter SS_ACTIVE_LOW = 1,
	parameter LSB_FIRST = 0,
	parameter NUM_DATA_BITS = 8
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// control inputs
	input wire mosi_start,
	input wire keep_alive,

	// status outputs
	output reg mosi_ready = 1'b0,
	output reg mosi_done = 1'b0,
	output reg miso_new_data = 1'b0,
	
	// data
	output wire [NUM_DATA_BITS-1:0] miso_data,
	input wire [NUM_DATA_BITS-1:0] mosi_data,
	
	// bus lines
	output reg ss_out = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1,
	output wire sclk_out,
	input wire miso_in,
	output wire mosi_out
);

	// local constants
	localparam REAL_COLCK_DIV = CLOCK_DIV & (~3);	// clock div must be 0 mod 4
	localparam BUF_SIZE = NUM_DATA_BITS;
	localparam BIT_COUNT_WIDTH = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits
	localparam CTR_WIDTH = $clog2(REAL_COLCK_DIV+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal signals
	
	// edge signals
	wire sclk_rise_edge;
	wire sclk_fall_edge;
	
	// status signals
	wire sclk_done;
	wire miso_buf_done;
	wire mosi_buf_done;
	wire finish_delay_done;
	
	// internal registers
	
	// control
	reg sclk_start = 1'b0;
	reg miso_buf_start = 1'b0;
	reg mosi_buf_start = 1'b0;
	reg finish_delay_start = 1'b0;
	reg buf_and_clk_rst = 1'b0;
	
	// states
	localparam STATE_IDLE = 4'd0;
	localparam STATE_COMM_START = 4'd1;
	localparam STATE_COMM_WAIT_MISO = 4'd2;
	localparam STATE_COMM_WAIT_MOSI = 4'd3;
	localparam STATE_COMM_KEEP_ALIVE = 4'd4;
	localparam STATE_COMM_WAIT_SCLK = 4'd5;
	localparam STATE_FINISH_DELAY_START = 4'd6;
	localparam STATE_FINISH_DELAY_WAIT = 4'd7;
	localparam STATE_RESET = 4'd8;
	
	reg	[3:0] state = STATE_RESET;
	
	// SPI transaction control logic
	always @ (posedge sys_clk)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			mosi_ready <= 1'b0;
			state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (state)
				
				// in idle state wait for sommunication start signal, set SS active and start clocking and buffering
				STATE_IDLE: begin
					if (mosi_start == 1'b1) begin
						mosi_ready <= 1'b0;
						ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
						sclk_start <= 1'b1;
						miso_buf_start <= 1'b1;
						mosi_buf_start <= 1'b1;
						state <= STATE_COMM_START;
					end
				end
				
				// delay one clock cycle for buffers and clock to process inputs
				STATE_COMM_START: begin
					sclk_start <= 1'b0;
					miso_buf_start <= 1'b0;
					mosi_buf_start <= 1'b0;
					state <= STATE_COMM_WAIT_MISO;
				end
				
				// wait for MISO buffer to finish (read buffer ends first as it reads on rising edge)
				STATE_COMM_WAIT_MISO: begin
					if (miso_buf_done == 1'b1) begin
						miso_new_data <= 1'b1;
						state <= STATE_COMM_WAIT_MOSI;
					end
				end
				
				// wait for MOSI buffer to finish (write buffer ends second as it writes on falling edge)
				// wait for buffering to finish (sclk always finishes 1/4 of a SCLK period later)
				STATE_COMM_WAIT_MOSI: begin
					miso_new_data <= 1'b0;
					
					if (mosi_buf_done == 1'b1) begin
						mosi_done <= 1'b1;
						
						// if keep-alive is set we can start processing the MISO input already
						if (keep_alive == 1'b1) begin
							mosi_ready <= 1'b1;
							sclk_start <= 1'b1;
							miso_buf_start <= 1'b1;
							state <= STATE_COMM_KEEP_ALIVE;
						end
						
						// else we go to wait for SCLK to be done before ending communication
						else begin
							state <= STATE_COMM_WAIT_SCLK;
						end
					end
				end
				
				// in keep-alive state wait for MOSI start signal -- we have time until the first rising edge on SCLK
				STATE_COMM_KEEP_ALIVE: begin
					miso_new_data <= 1'b0;
					miso_buf_start <= 1'b0;
					mosi_done <= 1'b0;
					
					// if keep-alive drops, abort communication and reset buffers/clock
					if (keep_alive == 1'b0) begin
						mosi_ready <= 1'b0;
						sclk_start <= 1'b0;
						ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
						buf_and_clk_rst <= 1'b1;
						finish_delay_start <= 1'b1;
						state <= STATE_FINISH_DELAY_START;
					end
					
					// if first rising edge on SCLK occured it is too late for MOSI to start sending -- go to buffer waiting state
					else if (sclk_rise_edge == 1'b1) begin
						mosi_ready <= 1'b0;
						state <= STATE_COMM_START;
					end
					
					// else if we detect MOSI start signal we can start sending data
					else if (mosi_start == 1'b1) begin
						mosi_ready <= 1'b0;
						mosi_buf_start <= 1'b1;
						state <= STATE_COMM_START;
					end
				end
				
				// wait for SCLK to finish before bringing SS to passive mode
				STATE_COMM_WAIT_SCLK: begin
					miso_new_data <= 1'b0;
					mosi_done <= 1'b0;
					
					if (sclk_done == 1'b1) begin
						ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
						finish_delay_start <= 1'b1;
						state <= STATE_FINISH_DELAY_START;
					end
				end
				
				// delay one clock cycle for delay counter to process inputs
				STATE_FINISH_DELAY_START: begin
					buf_and_clk_rst <= 1'b0;
					finish_delay_start <= 1'b0;
					state <= STATE_FINISH_DELAY_WAIT;
				end
				
				// wait for delay counter to finish, then go to idle state
				STATE_FINISH_DELAY_WAIT: begin
					if (finish_delay_done == 1'b1) begin
						mosi_ready <= 1'b1;
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					sclk_start <= 1'b0;
					miso_buf_start <= 1'b0;
					mosi_buf_start <= 1'b0;
					finish_delay_start <= 1'b0;
					buf_and_clk_rst <= 1'b0;
					ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
					miso_new_data <= 1'b0;
					mosi_done <= 1'b0;
					mosi_ready <= 1'b1;
					state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					mosi_ready <= 1'b0;
					state <= STATE_RESET;
				end
				
			endcase
		end
	end
	
	
	/******************** MODULE INSTANTIATION ********************/
	
	// SCLK clock generator
	PulseGenerator #(
		.CYCLE_COUNT(BUF_SIZE),
		.CYCLE_LEN(REAL_COLCK_DIV),
		.PULSE_LEN(REAL_COLCK_DIV / 2),
		.DELAY(REAL_COLCK_DIV / 4),
		.ACTIVE_LOW(0)
	) sclkClockGen (
		.sys_clk(sys_clk),
		.rst(rst | buf_and_clk_rst),
		.start(sclk_start),
		.out_sig(sclk_out),
		.done_sig(sclk_done)
	);
	
	// SCLK rise edge detector
	EdgeDetector #(
		.FALL_EDGE(0)
	) sclkRiseEdgeDetect (
		.sys_clk(sys_clk),
		.sig(sclk_out),
		.edge_sig(sclk_rise_edge)
	);
	
	// SCLK fall edge detector
	EdgeDetector #(
		.FALL_EDGE(1)
	) sclkFallEdgeDetect (
		.sys_clk(sys_clk),
		.sig(sclk_out),
		.edge_sig(sclk_fall_edge)
	);
	
	// MISO read buffer
	SerialReadBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(LSB_FIRST)
	) misoReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst | buf_and_clk_rst),
		.start(miso_buf_start),
		.read_sig(sclk_rise_edge),
		.in_line(miso_in),
		.read_count(BUF_SIZE[BIT_COUNT_WIDTH-1:0]),
		.data_out(miso_data),
		.done_sig(miso_buf_done)
	);
	
	// MOSI write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(LSB_FIRST),
		.ACTIVE_LOW(0)
	) mosiWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst | buf_and_clk_rst),
		.start(mosi_buf_start),
		.write_sig(sclk_fall_edge),
		.data_in(mosi_data),
		.write_count(BUF_SIZE[BIT_COUNT_WIDTH-1:0]),
		.out_line(mosi_out),
		.done_sig(mosi_buf_done)
	);
	
	// Finish delay counter
	Counter #(
		.MAX_N(REAL_COLCK_DIV)
	) finishDelayCounter (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(finish_delay_start),
		.n_val(REAL_COLCK_DIV[CTR_WIDTH-1:0]),
		.ctr_val(),	// no connect -- we are using the counter only as delay
		.done_sig(finish_delay_done)
	);
	
	/******************** ******************** ********************/
	
endmodule