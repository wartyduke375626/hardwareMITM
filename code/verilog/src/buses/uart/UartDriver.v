/**
 * UART driver module:
 * - implements the UART physical layer protocol
 * - provides an interface to send and receive data with the UART protocol
 * - 1 start bit, 1 stop bit and 0 parity bits are hardcoded
 * - the BIT_DURATION parameter defines the duration of one bit in system clock cycles (calculated as system_frequency/baud_rate)
 * - the NUM_DATA_BITS parameter defines the number of bits per frame
**/

module UartDriver #(

	// parameters
	parameter BIT_DURATION = 104,
	parameter NUM_DATA_BITS = 8
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// control inputs
	input wire tx_start,

	// status outputs
	output reg rx_new_data = 1'b0,
	output reg rx_ready = 1'b0,
	output reg tx_ready = 1'b0,
	
	// data
	output wire [NUM_DATA_BITS-1:0] rx_data,
	input wire [NUM_DATA_BITS-1:0] tx_data,
	
	// bus lines
	input wire rx_in,
	output wire tx_out
);

	// local constants
	localparam RX_DELAY = BIT_DURATION / 2;
	localparam TX_DELAY = BIT_DURATION - 1;
	localparam BUF_SIZE = NUM_DATA_BITS + 2;	// add 1 start bit and 1 stop bit
	localparam BIT_COUNT_WIDTH = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// internal signals
	
	// edge signals
	wire rx_start_bit_edge;
	
	// buffer signals
	wire rx_read_sig;
	wire tx_write_sig;
	
	// buffer control
	wire rx_buf_done;
	wire tx_buf_done;
	wire rx_clk_done;
	wire tx_clk_done;
	wire [BIT_COUNT_WIDTH-1:0] bit_count;
	assign bit_count = BUF_SIZE[BIT_COUNT_WIDTH-1:0];	// truncate BUF_SIZE to the correct width
	
	// buffer data
	wire [BUF_SIZE-1:0] rx_buf_data;
	assign rx_data = rx_buf_data[BUF_SIZE-2:1]; // remove start/stop bit from data read
	wire [BUF_SIZE-1:0] tx_buf_data;
	assign tx_buf_data = {1'b1, tx_data, 1'b0};	// append start/stop bit to transmitted data (LSB first)
	
	// internal registers
	
	// buffer control
	reg rx_buf_start = 1'b0;
	reg tx_buf_start = 1'b0;
	reg rx_clk_start = 1'b0;
	reg tx_clk_start = 1'b0;
	
	// states
	localparam STATE_IDLE = 2'd0;
	localparam STATE_BUF_START = 2'd1;
	localparam STATE_BUF_WAIT = 2'd2;
	localparam STATE_RESET = 2'd3;
	
	reg	[1:0] rx_state = STATE_RESET;
	reg	[1:0] tx_state = STATE_RESET;
	
	// RX control logic
	always @ (posedge sys_clk)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			rx_ready <= 1'b0;
			rx_state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (rx_state)
				
				// in idle state wait for start bit and signal RX buffer and clock generator start
				STATE_IDLE: begin
					rx_new_data <= 1'b0;
				
					if (rx_start_bit_edge == 1'b1) begin
						rx_ready <= 1'b0;
						rx_buf_start <= 1'b1;
						rx_clk_start <= 1'b1;
						rx_state <= STATE_BUF_START;
					end
				end
				
				// delay one clock cycle for RX buffer and clock generator to process inputs
				STATE_BUF_START: begin
					rx_buf_start <= 1'b0;
					rx_clk_start <= 1'b0;
					rx_state <= STATE_BUF_WAIT;
				end
				
				// wait for RX buffer to process communication and clock generator to finish
				STATE_BUF_WAIT: begin
					if (rx_buf_done & rx_clk_done == 1'b1) begin
						rx_ready <= 1'b1;
						rx_new_data <= 1'b1;
						rx_state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					rx_buf_start <= 1'b0;
					rx_clk_start <= 1'b0;
			
					rx_new_data <= 1'b0;
					rx_ready <= 1'b1;
					
					rx_state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					rx_ready <= 1'b0;
					rx_state <= STATE_RESET;
				end
				
			endcase
		end
	end
	
	// TX control logic
	always @ (posedge sys_clk)
	begin
		// on reset go to reset state
		if (rst == 1'b1) begin
			tx_ready <= 1'b0;
			tx_state <= STATE_RESET;
		end
		
		else begin
			// state transition logic
			case (tx_state)
				
				// in idle state wait for transmit start command and signal TX buffer and clock generator start
				STATE_IDLE: begin
					if (tx_start == 1'b1) begin
						tx_ready <= 1'b0;
						tx_buf_start <= 1'b1;
						tx_clk_start <= 1'b1;
						tx_state <= STATE_BUF_START;
					end
				end
				
				// delay one clock cycle for TX buffer and clock generator to process inputs
				STATE_BUF_START: begin
					tx_buf_start <= 1'b0;
					tx_clk_start <= 1'b0;
					tx_state <= STATE_BUF_WAIT;
				end
				
				// wait for TX buffer to process communication and clock generator to finish
				STATE_BUF_WAIT: begin
					if (tx_buf_done & tx_clk_done == 1'b1) begin
						tx_ready <= 1'b1;
						tx_state <= STATE_IDLE;
					end
				end
				
				// reset internal state
				STATE_RESET: begin
					tx_buf_start <= 1'b0;
					tx_clk_start <= 1'b0;
			
					tx_ready <= 1'b1;
					
					tx_state <= STATE_IDLE;
				end
				
				// this should never occur
				default: begin
					tx_ready <= 1'b0;
					tx_state <= STATE_RESET;
				end
				
			endcase
		end
	end
	
	
	/******************** MODULE INSTANTIATION ********************/
	
	// RX start bit edge detector
	EdgeDetector #(
		.FALL_EDGE(1)
	) strtBitEdgeDetect (
		.sys_clk(sys_clk),
		.sig(rx_in),
		.edge_sig(rx_start_bit_edge)
	);
	
	// RX read sig generator
	PulseGenerator #(
		.CYCLE_COUNT(BUF_SIZE),
		.CYCLE_LEN(BIT_DURATION),
		.PULSE_LEN(1),
		.DELAY(RX_DELAY),
		.ACTIVE_LOW(0)
	) rxReadSigGen (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(rx_clk_start),
		.out_sig(rx_read_sig),
		.done_sig(rx_clk_done)
	);
	
	// TX write sig generator
	PulseGenerator #(
		.CYCLE_COUNT(BUF_SIZE),
		.CYCLE_LEN(BIT_DURATION),
		.PULSE_LEN(1),
		.DELAY(TX_DELAY),
		.ACTIVE_LOW(0)
	) txWriteSigGen (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(tx_clk_start),
		.out_sig(tx_write_sig),
		.done_sig(tx_clk_done)
	);
	
	// RX read buffer
	SerialReadBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(1)
	) rxReadBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(rx_buf_start),
		.read_sig(rx_read_sig),
		.in_line(rx_in),
		.read_count(bit_count),
		.data_out(rx_buf_data),
		.done_sig(rx_buf_done)
	);
	
	// TX write buffer
	SerialWriteBuffer #(
		.BUF_SIZE(BUF_SIZE),
		.LSB_FIRST(1),
		.ACTIVE_LOW(1)
	) txWriteBuffer (
		.sys_clk(sys_clk),
		.rst(rst),
		.start(tx_buf_start),
		.write_sig(tx_write_sig),
		.data_in(tx_buf_data),
		.write_count(bit_count),
		.out_line(tx_out),
		.done_sig(tx_buf_done)
	);
	
	/******************** ******************** ********************/
	
endmodule