/**
 * SPI master driver module:
 * - implements the SPI physical layer protocol on the master side
 * - provides an interface to send and receive data as SPI master
 * - SPI mode 0 (CPOL = 0, CPHA = 0)is hardcoded
 * - the CLOCK_DIV parameter defines the colock speed (the system clock is devided by this value) and must be even (in case it is odd, CLOCK_DIV - 1 is used)
 * - the SS_ACTIVE_LOW parameter defines whether the SS line is active low
 * - the LSB_FIRST parameter defines bit order of data
 * - the NUM_DATA_BITS parameter defines the number of bits per transaction (both MOSI and MISO)
**/

module SpiMasterDriver #(

	// parameters
	parameter CLOCK_DIV = 6,
	parameter SS_ACTIVE_LOW = 1,
	parameter LSB_FIRST = 0,
	parameter NUM_DATA_BITS = 8
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// control inputs
	input wire comm_start,

	// status outputs
	output reg bus_ready = 1'b0,
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
	localparam REAL_COLCK_DIV = CLOCK_DIV & (~1);	// clock div must be even
	localparam DELAY_COUNT_1 = REAL_COLCK_DIV / 2;
	localparam DELAY_COUNT_2 = REAL_COLCK_DIV;
	localparam DELAY_CTR_SIZE = $clog2(DELAY_COUNT_2+1);	// storing A requires exactly ceil(lg(A+1)) bits
	localparam BUF_SIZE = NUM_DATA_BITS;
	localparam BIT_COUNT_WIDTH = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal signals
	
	// buffer control signals
	wire miso_read_sig;
	wire mosi_write_sig;
	
	// status signals
	wire sclk_clk_done;
	wire miso_buf_done;
	wire mosi_buf_done;
	wire miso_sig_gen_done;
	wire mosi_sig_gen_done;
	wire delay_ctr_done;
	
	wire clk_and_buf_done;
	assign clk_and_buf_done = sclk_clk_done & miso_buf_done & mosi_buf_done & miso_sig_gen_done & mosi_sig_gen_done;
	
	// internal registers
	
	// control
	reg clk_and_buf_start = 1'b0;
	reg delay_ctr_start = 1'b0;
	reg [DELAY_CTR_SIZE-1:0] delay_ctr_n_val;
	
	// states
	localparam STATE_IDLE = 3'd0;
	localparam STATE_COMM_START = 3'd1;
	localparam STATE_COMM_WAIT = 3'd2;
	localparam STATE_DELAY_START_1 = 3'd3;
	localparam STATE_DELAY_WAIT_1 = 3'd4;
	localparam STATE_DELAY_START_2 = 3'd5;
	localparam STATE_DELAY_WAIT_2 = 3'd6;
	localparam STATE_RESET = 3'd7;
	
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
				
				// in idle state wait for sommunication start signal and set SS to active mode and start clocking and buffering
				STATE_IDLE: begin
					ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
					
					if (comm_start == 1'b1) begin
						bus_ready <= 1'b0;
						ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
						clk_and_buf_start <= 1'b1;
						state <= STATE_COMM_START;
					end
				end
				
				// delay one clock cycle for buffers, clock and pulse generators to process inputs
				STATE_COMM_START: begin
					clk_and_buf_start <= 1'b0;
					state <= STATE_COMM_WAIT;
				end
				
				// wait for clocking and buffering to finish, then we delay half SCLK cycle before SS goes inactive
				STATE_COMM_WAIT: begin
					if (clk_and_buf_done == 1'b1) begin
						miso_new_data <= 1'b1;
						delay_ctr_n_val <= DELAY_COUNT_1[DELAY_CTR_SIZE-1:0];
						delay_ctr_start <= 1'b1;
						state <= STATE_DELAY_START_1;
					end
				end
				
				// delay one clock cycle for counter to process inputs
				STATE_DELAY_START_1: begin
					miso_new_data <= 1'b0;
					delay_ctr_start <= 1'b0;
					state <= STATE_DELAY_WAIT_1;
				end
				
				// wait for counter to finish, then we delay at least one SCLK cycle before being ready for next communication
				STATE_DELAY_WAIT_1: begin
					if (delay_ctr_done == 1'b1) begin
						ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
						delay_ctr_n_val <= DELAY_COUNT_2[DELAY_CTR_SIZE-1:0];
						delay_ctr_start <= 1'b1;
						state <= STATE_DELAY_START_2;
					end
				end
				
				// delay one clock cycle for counter to process inputs
				STATE_DELAY_START_2: begin
					delay_ctr_start <= 1'b0;
					state <= STATE_DELAY_WAIT_2;
				end
				
				// wait for counter to finish, then we are finally ready
				STATE_DELAY_WAIT_2: begin
					if (delay_ctr_done == 1'b1) begin
						bus_ready <= 1'b1;
						state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					clk_and_buf_start <= 1'b0;
					delay_ctr_start <= 1'b0;
					delay_ctr_n_val <= 0;
					ss_out <= (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
					miso_new_data <= 1'b0;
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
	
	// Delay counter
	Counter #(
		.MAX_N(DELAY_COUNT_2)
	) delayCounter (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(delay_ctr_start),
		.n_val(delay_ctr_n_val),
		.ctr_val(),	// no connect -- we are using the counter only as delay
		.done_sig(delay_ctr_done)
	);
	
	// SCLK clock generator
	PulseGenerator #(
		.CYCLE_COUNT(BUF_SIZE),
		.CYCLE_LEN(REAL_COLCK_DIV),
		.PULSE_LEN(REAL_COLCK_DIV / 2),
		.DELAY(REAL_COLCK_DIV / 2),
		.ACTIVE_LOW(0)
	) sclkClockGen (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(clk_and_buf_start),
		.out_sig(sclk_out),
		.done_sig(sclk_clk_done)
	);
	
	// MISO read sig generator
	PulseGenerator #(
		.CYCLE_COUNT(BUF_SIZE),
		.CYCLE_LEN(REAL_COLCK_DIV),
		.PULSE_LEN(1),
		.DELAY(REAL_COLCK_DIV / 2),
		.ACTIVE_LOW(0)
	) misoReadSigGen (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(clk_and_buf_start),
		.out_sig(miso_read_sig),
		.done_sig(miso_sig_gen_done)
	);
	
	// MISO read buffer
	SerialReadBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(LSB_FIRST)
	) misoReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(clk_and_buf_start),
		.read_sig(miso_read_sig),
		.in_line(miso_in),
		.read_count(BUF_SIZE[BIT_COUNT_WIDTH-1:0]),
		.data_out(miso_data),
		.done_sig(miso_buf_done)
	);
	
	// MOSI write sig generator
	PulseGenerator #(
		.CYCLE_COUNT(BUF_SIZE),
		.CYCLE_LEN(REAL_COLCK_DIV),
		.PULSE_LEN(1),
		.DELAY(REAL_COLCK_DIV - 1),
		.ACTIVE_LOW(0)
	) mosiWriteSigGen (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(clk_and_buf_start),
		.out_sig(mosi_write_sig),
		.done_sig(mosi_sig_gen_done)
	);
	
	// MOSI write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(LSB_FIRST),
		.ACTIVE_LOW(0)
	) mosiWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(clk_and_buf_start),
		.write_sig(mosi_write_sig),
		.data_in(mosi_data),
		.write_count(BUF_SIZE[BIT_COUNT_WIDTH-1:0]),
		.out_line(mosi_out),
		.done_sig(mosi_buf_done)
	);
	
	/******************** ******************** ********************/
	
endmodule