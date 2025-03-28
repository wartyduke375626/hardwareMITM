/**
 * Top level module for HW MITM mitm attacks:
 * - manages PLL generation of system clock
 * - manages synchronisation of physical bus I/O
 * - combines MITM logic and Bus control modules
**/

`ifndef BENCH
	`include "config.vh"
`endif

module TopLevelModule (

	// system inputs
	input wire ref_clk,
	
	// user inputs
	input wire rst_btn,
	input wire mode_select_btn,
	
	// user outputs
	output wire [NUM_MITM_MODES-1:0] mode_leds,
	output wire comm_active_led,
	
	// bus lines
	`ifdef BUS_UART
		input wire if0_rx_in,
		input wire if1_rx_in,
		output wire if0_tx_out,
		output wire if1_tx_out
	`elsif BUS_SPI
		input wire if0_ss_in,
		input wire if0_sclk_in,
		input wire if1_miso_in,
		input wire if0_mosi_in,
		output wire if1_ss_out,
		output wire if1_sclk_out,
		output wire if0_miso_out,
		output wire if1_mosi_out
	`endif
);

	// set local parameters according to configuration
	
	// system clock frequency
	`ifdef BENCH
		localparam SYS_FREQ_HZ = `TEST_FREQ_HZ;	// for test benches we have a simulated clock (no PLL)
	`else
		localparam SYS_FREQ_HZ = 1_000_000 * `SYS_FREQ;
		localparam PLL_DIVR = `PLL_DIVR;
		localparam PLL_DIVF = `PLL_DIVF;
		localparam PLL_DIVQ = `PLL_DIVQ;
		localparam PLL_FILTER_RANGE = `PLL_FILTER_RANGE;
	`endif
	
	// general parameters
	localparam DEBOUNCE_LEN_US = `DEBOUNCE_LEN_US;
	localparam NUM_MITM_MODES = `NUM_MITM_MODES;
	localparam NUM_DATA_BITS =`NUM_DATA_BITS;
	
	// bus specific parameters
	`ifdef BUS_UART
		localparam UART_BAUD_RATE = `UART_BAUD_RATE;
	`elsif BUS_SPI
		localparam SPI_FREQ_HZ = `SPI_FREQ_HZ;
		localparam SPI_SS_ACTIVE_LOW = `SPI_SS_ACTIVE_LOW;
		localparam SPI_LSB_FIRST = `SPI_LSB_FIRST;
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
		wire sync_if0_ss_in;
		wire sync_if0_sclk_in;
		wire sync_if1_miso_in;
		wire sync_if0_mosi_in;
	`endif
	
	// I/O connection to MITM logic
	wire [NUM_MITM_MODES-1:0] mode_select;
	
	// MITM logic connection to Bus interface
	
	wire fake_if0_select;
	wire fake_if1_select;
	wire fake_if0_send_start;
	wire fake_if1_send_start;
	wire fake_if0_keep_alive;
	wire fake_if1_keep_alive;
	
	wire if0_recv_new_data;
	wire if1_recv_new_data;
	wire fake_if0_send_ready;
	wire fake_if1_send_ready;
	wire fake_if0_send_done;
	wire fake_if1_send_done;
	
	wire [NUM_DATA_BITS-1:0] fake_if0_send_data;
	wire [NUM_DATA_BITS-1:0] fake_if1_send_data;
	wire [NUM_DATA_BITS-1:0] real_if0_recv_data;
	wire [NUM_DATA_BITS-1:0] real_if1_recv_data;
	
	// communication active indicator signal
	wire comm_active;
	`ifdef BUS_UART
		assign comm_active = ~sync_if0_rx_in | ~sync_if1_rx_in | ~if0_tx_out | ~if1_tx_out;
	`elsif BUS_SPI
		assign comm_active = (SPI_SS_ACTIVE_LOW == 0) ? (sync_if0_ss_in | if1_ss_out) : (~sync_if0_ss_in | ~if1_ss_out);
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
		// specific module to iCE40 FPGAs
		SB_PLL40_CORE #(
			.FEEDBACK_PATH("SIMPLE"),		// don't use fine delay adjustment
			.PLLOUT_SELECT("GENCLK"),		// no phase shift on output
			.DIVR(PLL_DIVR),				// reference clock divider
			.DIVF(PLL_DIVF),				// feedback clock divider
			.DIVQ(PLL_DIVQ),				// VCO clock divider
			.FILTER_RANGE(PLL_FILTER_RANGE)	// filter range
		) pll (
			.REFERENCECLK(ref_clk),			// input clock
			.PLLOUTCORE(sys_clk),			// output clock
			.LOCK(),						// locked signal (don't connect)
			.RESETB(1'b1),					// active low reset
			.BYPASS(1'b0)					// no bypass, use PLL signal as output
		);
	`endif
	
	// User I/O handler module
	IoHandler #(
		.NUM_MITM_MODES(NUM_MITM_MODES),
		.BUTTONS_ACTIVE_LOW(1),	// buttons are active high
		.DEBOUNCED_RST_ACTIVE_LOW(0),	// reset signal for internal logic is active high
		.SYS_FREQ_HZ(SYS_FREQ_HZ),
		.DEBOUNCE_LEN_US(DEBOUNCE_LEN_US)
	) ioHandler (
		.sys_clk(sys_clk),
		.rst_btn(rst_btn),
		.mode_select_btn(mode_select_btn),
		.comm_active(comm_active),
		.debounced_rst(rst),
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
			.in_line({if0_ss_in, if0_sclk_in, if1_miso_in, if0_mosi_in}),
			.out_line({sync_if0_ss_in, sync_if0_sclk_in, sync_if1_miso_in, sync_if0_mosi_in})
		`endif
	);
	
	// Bus interface module
	BusInterface #(
		.SYS_FREQ_HZ(SYS_FREQ_HZ),
		.NUM_DATA_BITS(NUM_DATA_BITS),
		`ifdef BUS_UART
			.UART_BAUD_RATE(`UART_BAUD_RATE)
		`elsif BUS_SPI
			.SPI_FREQ_HZ(`SPI_FREQ_HZ),
			.SPI_SS_ACTIVE_LOW(`SPI_SS_ACTIVE_LOW),
			.SPI_LSB_FIRST(`SPI_LSB_FIRST)
		`endif
	) busInterface (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.fake_if0_select(fake_if0_select),
		.fake_if1_select(fake_if1_select),
		.fake_if0_send_start(fake_if0_send_start),
		.fake_if1_send_start(fake_if1_send_start),
		.fake_if0_keep_alive(fake_if0_keep_alive),
		.fake_if1_keep_alive(fake_if1_keep_alive),
		
		.if0_recv_new_data(if0_recv_new_data),
		.if1_recv_new_data(if1_recv_new_data),
		.fake_if0_send_ready(fake_if0_send_ready),
		.fake_if1_send_ready(fake_if1_send_ready),
		.fake_if0_send_done(fake_if0_send_done),
		.fake_if1_send_done(fake_if1_send_done),
		
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
			.if0_ss_in(sync_if0_ss_in),
			.if0_sclk_in(sync_if0_sclk_in),
			.if1_miso_in(sync_if1_miso_in),
			.if0_mosi_in(sync_if0_mosi_in),
			.if1_ss_out(if1_ss_out),
			.if1_sclk_out(if1_sclk_out),
			.if0_miso_out(if0_miso_out),
			.if1_mosi_out(if1_mosi_out)
		`endif
	);
	
	// MITM logic module
	MitmLogic #(
		.NUM_DATA_BITS(NUM_DATA_BITS),
		.NUM_MITM_MODES(NUM_MITM_MODES)
	) mitmLogic (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.mode_select(mode_select),
		
		.fake_if0_select(fake_if0_select),
		.fake_if1_select(fake_if1_select),
		.fake_if0_send_start(fake_if0_send_start),
		.fake_if1_send_start(fake_if1_send_start),
		.fake_if0_keep_alive(fake_if0_keep_alive),
		.fake_if1_keep_alive(fake_if1_keep_alive),
		
		.if0_recv_new_data(if0_recv_new_data),
		.if1_recv_new_data(if1_recv_new_data),
		.fake_if0_send_ready(fake_if0_send_ready),
		.fake_if1_send_ready(fake_if1_send_ready),
		.fake_if0_send_done(fake_if0_send_done),
		.fake_if1_send_done(fake_if1_send_done),
		
		.fake_if0_send_data(fake_if0_send_data),
		.fake_if1_send_data(fake_if1_send_data),
		.real_if0_recv_data(real_if0_recv_data),
		.real_if1_recv_data(real_if1_recv_data)
	);
	
	/******************** ******************** ********************/
	
endmodule