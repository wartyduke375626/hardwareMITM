/**
 * Top level module for HW MITM mitm attacks:
 * - manages PLL generation of system clock
 * - manages synchronisation of physical bus I/O
 * - combines MITM logic and Bus control modules
**/

`ifndef BENCH
	`include "config.vh"
`endif

module TopLevelModule #(

	// parameters applicable for test benches
	`ifdef BENCH
		parameter REF_FREQ_HZ = 12_000_000,
		
		parameter DEBOUNCE_COUNT = 1_048_576,
		parameter MODE_WIDTH = 4,
		
		parameter NUM_DATA_BITS = 8,
		`ifdef BUS_UART
			parameter UART_BAUD_RATE = 115_200
		`endif
	`endif
) (

	// system inputs
	input wire ref_clk,
	
	// user inputs
	input wire rst_btn,
	input wire mode_btn,
	
	// user outputs
	output wire [MODE_WIDTH-1:0] mode_leds,
	output wire comm_active_led,
	
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

	// local constants
	`ifdef BENCH
		localparam SYS_FREQ_HZ = REF_FREQ_HZ;	// for test benches sys_clk = ref_clk
	`else
		localparam SYS_FREQ_HZ = 1_000_000 * SYS_FREQ;
		localparam DEBOUNCE_COUNT = 1_048_576;
	`endif
	
	// internal signals
	
	// system signals
	wire sys_clk;
	wire rst;
	
	// synchronized bus input lines
	`ifdef BUS_UART
		wire sync_if0_rx_in;
		wire sync_if1_rx_in;
	`elsif BUS_SPI
		wire sync_if1_miso_in;
		wire sync_if0_mosi_in;
		wire sync_if0_sclk_in;
		wire sync_if0_ss_in;
	`endif
	
	// I/O connection to MITM logic
	wire [MODE_WIDTH-1:0] mode_select;
	
	// MITM logic connection to Bus interface
	
	wire fake_if0_send_select;
	wire fake_if1_send_select;
	wire fake_if0_send_start;
	wire fake_if1_send_start;
	
	wire if0_recv_new_data_ready;
	wire if1_recv_new_data_ready;
	wire if0_send_ready;
	wire if1_send_ready;
	
	wire [NUM_DATA_BITS-1:0] fake_if0_send_data;
	wire [NUM_DATA_BITS-1:0] fake_if1_send_data;
	wire [NUM_DATA_BITS-1:0] real_if0_recv_data;
	wire [NUM_DATA_BITS-1:0] real_if1_recv_data;
	
	// communication active indicator signal
	wire comm_active;
	`ifdef BUS_UART
		assign comm_active = ~sync_if0_rx_in | ~sync_if1_rx_in | ~if0_tx_out | ~if1_tx_out;
	`elsif BUS_SPI
		assign comm_active = sync_if0_ss_in | if1_ss_out;
		initial begin
			$display("SPI not implemented yet.");
		end
	`else
		initial begin
			$display("Error: No supported bus was defined.");
		end
	`endif
	
	/******************** MODULE INSTANTIATION ********************/
	
	// don't use PLL for test benches
	`ifdef BENCH
		assign sys_clk = ref_clk;
	`else
		// PLL (48 MHz)
		// specific module to iCE40 FPGAs
		SB_PLL40_CORE #(
			.FEEDBACK_PATH("SIMPLE"),	// don't use fine delay adjustment
			.PLLOUT_SELECT("GENCLK"),	// no phase shift on output
			.DIVR(4'b0000),				// reference clock divider
			.DIVF(7'b0111111),			// feedback clock divider
			.DIVQ(3'b100),				// VCO clock divider
			.FILTER_RANGE(3'b001)		// filter range
		) pll (
			.REFERENCECLK(ref_clk),		// input clock
			.PLLOUTCORE(sys_clk),		// output clock
			.LOCK(),					// locked signal (don't connect)
			.RESETB(1'b1),				// active low reset
			.BYPASS(1'b0)				// no bypass, use PLL signal as output
		);
	`endif
	
	// Reset button debouncer
	SignalDebouncer #(
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT),
		.IN_ACTIVE_LOW(1),	// reset button is active low
		.OUT_ACTIVE_LOW(0)	// reset for internal logic is active high
	) rstDebouncer (
		.sys_clk(sys_clk),
		.in_sig(rst_btn),
		.out_sig(rst)
	);
	
	// User I/O handler module
	IoHandler #(
		.MODE_WIDTH(MODE_WIDTH),
		.BUTTON_ACTIVE_LOW(1),	// mode select button is active low
		.DEBOUNCE_COUNT(DEBOUNCE_COUNT)
	) ioHandler (
		.sys_clk(sys_clk),
		.mode_select_btn(mode_btn),
		.comm_active(comm_active),
		.mode_select(mode_select),
		.mode_leds(mode_leds),
		.comm_active_led(comm_active_led)
	);
	
	// Bus input synchronizer
	Synchronizer #(
		`ifdef BUS_UART
			.WIDTH(2)
		`elsif BUS_SPI
			.WIDTH(4)
		`endif
	) busSynchronizer (
		.sys_clk(sys_clk),
		`ifdef BUS_UART
			.in_line({if0_rx_in, if1_rx_in}),
			.out_line({sync_if0_rx_in, sync_if1_rx_in})
		`elsif BUS_SPI
			.in_line({if1_miso_in, if0_mosi_in, if0_sclk_in, if0_ss_in}),
			.out_line({sync_if1_miso_in, sync_if0_mosi_in, sync_if0_sclk_in, sync_if0_ss_in})
		`endif
	);
	
	// Bus interface module
	BusInterface #(
		.SYS_FREQ_HZ(SYS_FREQ_HZ),
		.NUM_DATA_BITS(NUM_DATA_BITS),
		`ifdef BUS_UART
			.UART_BAUD_RATE(UART_BAUD_RATE)
		`endif
	) busInterface (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.fake_if0_send_select(fake_if0_send_select),
		.fake_if1_send_select(fake_if1_send_select),
		.fake_if0_send_start(fake_if0_send_start),
		.fake_if1_send_start(fake_if1_send_start),
		
		.if0_recv_new_data_ready(if0_recv_new_data_ready),
		.if1_recv_new_data_ready(if1_recv_new_data_ready),
		.if0_send_ready(if0_send_ready),
		.if1_send_ready(if1_send_ready),
		
		.fake_if0_send_data(fake_if0_send_data),
		.fake_if1_send_data(fake_if1_send_data),
		.real_if0_recv_data(real_if0_recv_data),
		.real_if1_recv_data(real_if1_recv_data),
		
		`ifdef BUS_UART
			.if0_rx_in(sync_if0_rx_in),
			.if1_rx_in(sync_if1_rx_in),
			.if0_tx_out(if0_tx_out),
			.if1_tx_out(if1_tx_out)
		`elsif BUS_SPI
			.if1_miso_in(sync_if1_miso_in),
			.if0_mosi_in(sync_if0_mosi_in),
			.if0_sclk_in(sync_if0_sclk_in),
			.if0_ss_in(sync_if0_ss_in),
			.if0_miso_out(if0_miso_out),
			.if1_mosi_out(if1_mosi_out),
			.if1_sclk_out(if1_sclk_out),
			.if1_ss_out(if1_ss_out)
		`endif
	);
	
	// MITM logic module
	MitmLogic #(
		.NUM_DATA_BITS(NUM_DATA_BITS)
	) mitmLogic (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.mode_select(mode_select),
		
		.fake_if0_send_select(fake_if0_send_select),
		.fake_if1_send_select(fake_if1_send_select),
		.fake_if0_send_start(fake_if0_send_start),
		.fake_if1_send_start(fake_if1_send_start),
		
		.if0_recv_new_data_ready(if0_recv_new_data_ready),
		.if1_recv_new_data_ready(if1_recv_new_data_ready),
		.if0_send_ready(if0_send_ready),
		.if1_send_ready(if1_send_ready),
		
		.fake_if0_send_data(fake_if0_send_data),
		.fake_if1_send_data(fake_if1_send_data),
		.real_if0_recv_data(real_if0_recv_data),
		.real_if1_recv_data(real_if1_recv_data)
	);
	
	/******************** ******************** ********************/
	
endmodule