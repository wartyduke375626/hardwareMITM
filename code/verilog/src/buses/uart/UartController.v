/**
 * UART bus controller module:
 * - manages operation of the UART bus
 * - provides bus commands for the bus interface module
**/

module UartController #(

	// parameters
	parameter SYS_FREQ_HZ = 12_000_000,
	parameter BAUD_RATE = 115_200,
	parameter NUM_DATA_BITS = 8
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// control inputs
	input wire fake_if0_tx_select,
	input wire fake_if1_tx_select,
	input wire fake_if0_tx_start,
	input wire fake_if1_tx_start,
	
	// status outputs
	output wire if0_rx_new_data_ready,
	output wire if1_rx_new_data_ready,
	output wire if0_tx_write_ready,
	output wire if1_tx_write_ready,
	output wire if0_tx_write_done,
	output wire if1_tx_write_done,
	
	// data
	input wire [NUM_DATA_BITS-1:0] fake_if0_transmit_data,
	input wire [NUM_DATA_BITS-1:0] fake_if1_transmit_data,
	output wire [NUM_DATA_BITS-1:0] real_if0_receive_data,
	output wire [NUM_DATA_BITS-1:0] real_if1_receive_data,
	
	// bus lines
	input wire if0_rx_in,
	input wire if1_rx_in,
	output wire if0_tx_out,
	output wire if1_tx_out
);

	// local constants
	localparam BIT_DURATION = SYS_FREQ_HZ / BAUD_RATE;
	
	// internal signals
	
	// fake bus lines
	wire fake_if0_tx_out;
	wire fake_if1_tx_out;
	
	// driver control
	wire if0_tx_start;
	wire if1_tx_start;
	
	assign if0_tx_start = if0_tx_write_ready & fake_if0_tx_start;
	assign if1_tx_start = if1_tx_write_ready & fake_if1_tx_start;
	
	assign if0_tx_write_done = if0_tx_write_ready;
	assign if1_tx_write_done = if1_tx_write_ready;
	
	/******************** MODULE INSTANTIATION ********************/
	
	// First UART interface
	UartDriver #(
		.BIT_DURATION(BIT_DURATION),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) uartInterface0 (
		.sys_clk(sys_clk),
		.rst(rst),
		.tx_start(if0_tx_start),
		.rx_new_data(if0_rx_new_data_ready),
		.tx_ready(if0_tx_write_ready),
		.rx_data(real_if0_receive_data),
		.tx_data(fake_if0_transmit_data),
		.rx_in(if0_rx_in),
		.tx_out(fake_if0_tx_out)
	);
	
	// Second UART interface
	UartDriver #(
		.BIT_DURATION(BIT_DURATION),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) uartInterface1 (
		.sys_clk(sys_clk),
		.rst(rst),
		.tx_start(if1_tx_start),
		.rx_new_data(if1_rx_new_data_ready),
		.tx_ready(if1_tx_write_ready),
		.rx_data(real_if1_receive_data),
		.tx_data(fake_if1_transmit_data),
		.rx_in(if1_rx_in),
		.tx_out(fake_if1_tx_out)
	);
	
	// Output multiplexer
	OutputMux #(
		.WIDTH(2)
	) outputMux (
		.in_line0({if1_rx_in, if0_rx_in}),
		.in_line1({fake_if0_tx_out, fake_if1_tx_out}),
		.select_line({fake_if0_tx_select, fake_if1_tx_select}),
		.out_line({if0_tx_out, if1_tx_out})
	);
	
	/******************** ******************** ********************/
	
endmodule