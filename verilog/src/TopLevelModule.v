/**
 * Top level module for HW MITM mitm attacks:
 * - manages PLL generation of system clock
 * - manages synchronisation of physical i/o
 * - sets and forwards synchronized physical i/o to MITM control module
**/

module TopLevelModule (

	// system inputs
	input wire ref_clk,
	input wire rst_btn,
	
	// bus inputs
	input wire miso_in,
	input wire mosi_in,
	input wire sclk_in,
	input wire ss_in,
	
	// bus outputs
	output wire miso_out,
	output wire mosi_out,
	output wire sclk_out,
	output wire ss_out
);

	// local constants
	localparam RST_DEBOUNCE_COUNT = 65536;
	localparam DATA_SIZE = 8;
	localparam BUS_WIDTH = 4;

	// internal signals
	wire sys_clk;
	wire rst;
	
	wire sync_miso_in;
	wire sync_mosi_in;
	wire sync_sclk_in;
	wire sync_ss_in;
	
	/******************** MODULE INSTANTIATION ********************/
	
	// PLL (120 MHz)
	// specific module to iCE40 FPGAs
	SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),	// don't use fine delay adjustment
		.PLLOUT_SELECT("GENCLK"),	// no phase shift on output
		.DIVR(4'b0000),				// reference clock divider
		.DIVF(7'b1001111),			// feedback clock divider
		.DIVQ(3'b011),				// VCO clock divider
		.FILTER_RANGE(3'b001)		// filter range
	) pll (
		.REFERENCECLK(ref_clk),		// input clock
		.PLLOUTCORE(sys_clk),		// output clock
		.LOCK(),					// locked signal (don't connect)
		.RESETB(1'b1),				// active low reset
		.BYPASS(1'b0)				// no bypass, use PLL signal as output
	);
	
	// Reset button debouncer
	ResetDebouncer #(
		.DEBOUNCE_COUNT(RST_DEBOUNCE_COUNT),
		.ACTIVE_LOW(1)	// reset button is active low
	) rstDebouncer (
		.sys_clk(sys_clk),
		.in_sig(rst_btn),
		.rst_sig(rst)
	);
	
	// Input synchronizer
	Synchronizer #(
		.WIDTH(BUS_WIDTH)
	) synchronizer (
		.sys_clk(sys_clk),
		.in_line({miso_in, mosi_in. sclk_in, ss_in}),
		.out_line({sync_miso_in, sync_mosi_in, sync_sclk_in, sync_ss_in})
	);
	
	// MITM control module
	MitmControl #(
		.DATA_SIZE(DATA_SIZE),
		.BUS_WIDTH(BUS_WIDTH)
	) mitmControl (
		.sys_clk(sys_clk),
		.rst(rst),
		.miso_in(sync_miso_in),
		.mosi_in(sync_mosi_in),
		.sclk_in(sync_sclk_in),
		.ss_in(sync_ss_in),
		.miso_out(miso_out),
		.mosi_out(mosi_out),
		.sclk_out(sclk_out),
		.ss_out(ss_out)
	);
	
	/******************** ******************** ********************/
	
endmodule