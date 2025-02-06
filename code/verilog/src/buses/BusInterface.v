/**
 * General bus interface module:
 * - standardizes the commands of different bus controller modules into a single bus interface
 * - the interface is intended to be used by the MITM logic module
 * - the control and status i/o lines of the bus interface are devided into to groups, named if0 and if1
 * - if0 (interface 0) controls one interface and if1 controls the other one
 * - on asymmetric master-slave architecture busses if0 referes to the interface connected to the master device and if1 to the slave device
 * - the bus lines are grouped into 4 groups: input lines of if0/if1, output lines of if0/if1
 * - the order of lines specific to a bus protocol is described below in the supported bus list
 * - to use a specific bus you need to set the BUS_TYPE parameter
 * - some parameters are general and apply to all busses: NUM_DATA_BITS
 * - some buses may require to set additional bus specific parameters
 * - below is a list of supported bus types:
 *
 *		UART:
 *		- bus specific parameters: UART_BAUD_RATE, UART_SYS_FREQ_HZ
 *		- order of input lines: { RX } (if0 and if1 are symmetrical)
 *		- order of output lines: { TX } (if0 and if1 are symmetrical)
 *
 *		SPI:
 *		- bus specific parameters: NOT_IMPLEMENTED_YET
 *		- order of input lines: if0 -- { MOSI, SCLK, SS }, if1 -- { MISO }
 *		- order of output lines: if0 -- { MISO }, if1 -- { MOSI, SCLK, SS }
 *
**/

module BusInterface #(
	
	// system parameters
	parameter SYS_FREQ_HZ = 12_000_000,
	
	// general bus parameters
	parameter NUM_DATA_BITS = 8,
	
	// bus specific parameters
	`ifdef BUS_UART
		parameter UART_BAUD_RATE = 115_200
	`endif
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// control inputs
	input wire fake_if0_send_select,
	input wire fake_if1_send_select,
	input wire fake_if0_send_start,
	input wire fake_if1_send_start,
	
	// status outputs
	output wire if0_recv_new_data_ready,
	output wire if1_recv_new_data_ready,
	output wire if0_send_ready,
	output wire if1_send_ready,
	
	// data
	input wire [NUM_DATA_BITS-1:0] fake_if0_send_data,
	input wire [NUM_DATA_BITS-1:0] fake_if1_send_data,
	output wire [NUM_DATA_BITS-1:0] real_if0_recv_data,
	output wire [NUM_DATA_BITS-1:0] real_if1_recv_data,
	
	// bus lines
	`ifdef BUS_UART
		input wire if0_rx_in,
		input wire if1_rx_in,
		output wire if0_tx_out,
		output wire if1_tx_out
	`elsif BUS_SPI
		input wire if1_miso_in,
		input wire if0_mosi_in,
		input wire if0_sclk_in,
		input wire if0_ss_in,
		output wire if0_miso_out,
		output wire if1_mosi_out,
		output wire if1_sclk_out,
		output wire if1_ss_out
	`endif
);

	// instantiate the correct bus controller module
	`ifdef BUS_UART
		UartController #(
			.SYS_FREQ_HZ(SYS_FREQ_HZ),
			.BAUD_RATE(UART_BAUD_RATE),
			.NUM_DATA_BITS(NUM_DATA_BITS)
		) uartController (
			.sys_clk(sys_clk),
			.rst(rst),
			.fake_if0_tx_select(fake_if0_send_select),
			.fake_if1_tx_select(fake_if1_send_select),
			.fake_if0_tx_start(fake_if0_send_start),
			.fake_if1_tx_start(fake_if1_send_start),
			.if0_rx_new_data_ready(if0_recv_new_data_ready),
			.if1_rx_new_data_ready(if1_recv_new_data_ready),
			.if0_tx_write_ready(if0_send_ready),
			.if1_tx_write_ready(if1_send_ready),
			.fake_if0_transmit_data(fake_if0_send_data),
			.fake_if1_transmit_data(fake_if1_send_data),
			.real_if0_receive_data(real_if0_recv_data),
			.real_if1_receive_data(real_if1_recv_data),
			.if0_rx_in(if0_rx_in),
			.if1_rx_in(if1_rx_in),
			.if0_tx_out(if0_tx_out),
			.if1_tx_out(if1_tx_out)
		);
	`elsif BUS_SPI
		initial begin
			$display("SPI not implemented yet.");
		end
	`else
		initial begin
			$display("Cannot instantiate bus controller module. No supported bus was defined.");
		end
	`endif
	
endmodule