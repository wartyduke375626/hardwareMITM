/**
 * Top level module for HW MITM mitm attacks:
 * - manages PLL generation of system clock
 * - manages synchronisation of physical bus I/O
 * - combines MITM logic and Bus control modules
**/

module TopLevelModule #(

	// parameters
	parameter DEBOUNCE_COUNT = 1_048_576
) (

	// system inputs
	input wire ref_clk,
	
	// user inputs
	input wire rst_btn,
	input wire mode_btn,
	
	// bus inputs
	input wire miso_in,
	input wire mosi_in,
	input wire sclk_in,
	input wire ss_in,
	
	// user outputs
	output wire [MODE_WIDTH-1:0] mode_leds,
	output wire comm_active_led,
	output wire [1:0] unused_leds,
	
	
	// bus outputs
	output wire miso_out,
	output wire mosi_out,
	output wire sclk_out,
	output wire ss_out
);

	// local constants
	localparam BUF_SIZE = 9;
	localparam CHUNK_SIZE_WIDTH = $clog2(BUF_SIZE+1);	// storing A requires exactly ceil(lg(A+1)) bits
	
	// MITM modes
	localparam MODE_WIDTH = 2;
	localparam MITM_MODE_FORWARD = 2'b01;
	localparam MITM_MODE_SUB_ALL = 2'b10;

	// internal signals
	
	// system signals
	wire sys_clk;
	wire rst;
	
	// synchronized bus lines
	wire sync_miso_in;
	wire sync_mosi_in;
	wire sync_sclk_in;
	wire sync_ss_in;
	
	// I/O connection to MITM logic
	wire [MODE_WIDTH-1:0] mode_select;
	
	// MITM logic connection to Bus control
	wire cmd_next_chunk;
	wire cmd_finish;
	
	wire [CHUNK_SIZE_WIDTH-1:0] next_chunk_size;
	
	wire fake_miso_select;
	wire fake_mosi_select;
	
	wire [BUF_SIZE-1:0] fake_miso_data;
	wire [BUF_SIZE-1:0] fake_mosi_data;
	
	wire comm_active;
	wire bus_ready;
	
	wire [BUF_SIZE-1:0] real_miso_data;
	wire [BUF_SIZE-1:0] real_mosi_data;
	
	assign unused_leds = 0;
	
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
		.WIDTH(4)
	) busSynchronizer (
		.sys_clk(sys_clk),
		.in_line({miso_in, mosi_in, sclk_in, ss_in}),
		.out_line({sync_miso_in, sync_mosi_in, sync_sclk_in, sync_ss_in})
	);
	
	// Bus control module
	BusControl #(
		.BUF_SIZE(BUF_SIZE)
	) busControl (
		.sys_clk(sys_clk),
		.rst(rst),
		
		.miso_in(sync_miso_in),
		.mosi_in(sync_mosi_in),
		.sclk_in(sync_sclk_in),
		.ss_in(sync_ss_in),
		
		.cmd_next_chunk(cmd_next_chunk),
		.cmd_finish(cmd_finish),
		
		.next_chunk_size(next_chunk_size),
		
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data),
		
		.miso_out(miso_out),
		.mosi_out(mosi_out),
		.sclk_out(sclk_out),
		.ss_out(ss_out),
		
		.comm_active(comm_active),
		.bus_ready(bus_ready),
		
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data)
	);
	
	MitmLogic #(
		.BUF_SIZE(BUF_SIZE),
		.MODE_WIDTH(MODE_WIDTH),
		
		.MITM_MODE_FORWARD(MITM_MODE_FORWARD),
		.MITM_MODE_SUB_ALL(MITM_MODE_SUB_ALL)
	) mitmLogic (
		.sys_clk(sys_clk),
		.rst(rst),
		.mode_select(mode_select),
		
		.comm_active(comm_active),
		.bus_ready(bus_ready),
		
		.real_miso_data(real_miso_data),
		.real_mosi_data(real_mosi_data),
		
		.cmd_next_chunk(cmd_next_chunk),
		.cmd_finish(cmd_finish),
		
		.next_chunk_size(next_chunk_size),
		
		.fake_miso_select(fake_miso_select),
		.fake_mosi_select(fake_mosi_select),
		
		.fake_miso_data(fake_miso_data),
		.fake_mosi_data(fake_mosi_data)
	);
	
	/******************** ******************** ********************/
	
endmodule