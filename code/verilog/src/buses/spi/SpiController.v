/**
 * SPI bus controller module:
 * - manages operation of the SPI bus
 * - provides bus commands for the bus interface module
 * - on if0 we are slave device (connected to real master)
 * - on if1 we are master device (connected to real slave)
**/

module SpiController #(

	// parameters
	parameter SYS_FREQ_HZ = 12_000_000,
	parameter SPI_FREQ_HZ = 1_000_000,
	parameter SS_ACTIVE_LOW = 1,
	parameter LSB_FIRST = 0,
	parameter NUM_DATA_BITS = 8
) (
	
	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// control inputs
	input wire fake_if0_miso_select,
	input wire fake_if1_mosi_select,
	input wire fake_if0_miso_start,
	input wire fake_if1_mosi_start,
	input wire fake_if1_keep_alive,
	
	// status outputs
	output wire if0_mosi_new_data_ready,
	output wire if1_miso_new_data_ready,
	output wire if0_miso_send_ready,
	output wire if1_mosi_send_ready,
	output wire if0_miso_send_done,
	output wire if1_mosi_send_done,
	
	// data
	input wire [NUM_DATA_BITS-1:0] fake_if0_miso_data,
	input wire [NUM_DATA_BITS-1:0] fake_if1_mosi_data,
	output wire [NUM_DATA_BITS-1:0] real_if0_mosi_data,
	output wire [NUM_DATA_BITS-1:0] real_if1_miso_data,
	
	// bus lines
	input wire if0_ss_in,
	input wire if0_sclk_in,
	input wire if1_miso_in,
	input wire if0_mosi_in,
	output wire if1_ss_out,
	output wire if1_sclk_out,
	output wire if0_miso_out,
	output wire if1_mosi_out
);

	// local constants
	localparam MASTER_CLOCK_DIV = SYS_FREQ_HZ / SPI_FREQ_HZ;
	
	// internal signals
	
	// fake bus lines
	wire fake_if1_ss_out;
	wire fake_if1_sclk_out;
	wire fake_if0_miso_out;
	wire fake_if1_mosi_out;
	
	// driver control
	wire if0_miso_start;
	wire if1_mosi_start;
	
	
	assign if0_miso_start = if0_miso_send_ready & fake_if0_miso_start;
	assign if1_mosi_start = if1_mosi_send_ready & fake_if1_mosi_start;
	
	/******************** MODULE INSTANTIATION ********************/
	
	// SPI Slave interface
	SpiSlaveDriver #(
		.SS_ACTIVE_LOW(SS_ACTIVE_LOW),
		.LSB_FIRST(LSB_FIRST),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) spiSlaveInterface (
		.sys_clk(sys_clk),
		.rst(rst),
		.miso_start(if0_miso_start),
		.miso_ready(if0_miso_send_ready),
		.miso_done(if0_miso_send_done),
		.mosi_new_data(if0_mosi_new_data_ready),
		.miso_data(fake_if0_miso_data),
		.mosi_data(real_if0_mosi_data),
		.ss_in(if0_ss_in),
		.sclk_in(if0_sclk_in),
		.miso_out(fake_if0_miso_out),
		.mosi_in(if0_mosi_in)
	);
	
	// SPI Master interface
	SpiMasterDriver #(
		.CLOCK_DIV(MASTER_CLOCK_DIV),
		.SS_ACTIVE_LOW(SS_ACTIVE_LOW),
		.LSB_FIRST(LSB_FIRST),
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) spiMasterInterface (
		.sys_clk(sys_clk),
		.rst(rst),
		.mosi_start(if1_mosi_start),
		.keep_alive(fake_if1_keep_alive),
		.mosi_ready(if1_mosi_send_ready),
		.mosi_done(if1_mosi_send_done),
		.miso_new_data(if1_miso_new_data_ready),
		.miso_data(real_if1_miso_data),
		.mosi_data(fake_if1_mosi_data),
		.ss_out(fake_if1_ss_out),
		.sclk_out(fake_if1_sclk_out),
		.miso_in(if1_miso_in),
		.mosi_out(fake_if1_mosi_out)
	);
	
	// Output multiplexer
	OutputMux #(
		.WIDTH(4)
	) outputMux (
		.in_line0({if0_ss_in, if0_sclk_in, if1_miso_in, if0_mosi_in}),
		.in_line1({fake_if1_ss_out, fake_if1_sclk_out, fake_if0_miso_out, fake_if1_mosi_out}),
		.select_line({fake_if1_mosi_select, fake_if1_mosi_select, fake_if0_miso_select, fake_if1_mosi_select}),
		.out_line({if1_ss_out, if1_sclk_out, if0_miso_out, if1_mosi_out})
	);
	
	/******************** ******************** ********************/
	
endmodule