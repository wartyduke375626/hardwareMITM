/**
 * Simulation of Top level module.
**/

// define timescale
`timescale 1 ns / 10 ps

// general configuration
`define TEST_FREQ_HZ 32_000_000
`define DEBOUNCE_LEN_US 1
`define NUM_MITM_MODES 4
`define NUM_DATA_BITS 8

// bus specific configuration
`define SPI_FREQ_HZ 1_000_000
`define SPI_SS_ACTIVE_LOW 1
`define SPI_LSB_FIRST 0

// set SPI bus
`define BUS_SPI 1

module TpmGetRandomTopLevelModule_test();

	// local constants
	localparam CLK_PERIOD_NS = 1_000_000_000 / `TEST_FREQ_HZ;
	localparam SIM_DURATION = 5_000_000;	// 5000 us
	
	localparam DEBOUNCE_LEN_US = `DEBOUNCE_LEN_US;
	localparam NUM_MITM_MODES = `NUM_MITM_MODES;
	
	localparam NUM_DATA_BITS = `NUM_DATA_BITS;
	localparam SPI_CLK_PERIOD_NS = 1_000_000_000 / `SPI_FREQ_HZ;
	localparam SS_ACTIVE_LOW = `SPI_SS_ACTIVE_LOW;
	
	// internal signals
	wire [NUM_MITM_MODES-1:0] mode_leds;
	wire comm_active_led;
	
	wire if1_ss_out;
	wire if1_sclk_out;
	wire if0_miso_out;
	wire if1_mosi_out;
	
	// internal registers
	reg ref_clk = 1'b0;
	
	reg rst_btn = 1'b1;
	reg mode_select_btn = 1'b1;
	
	reg if0_ss_in = (`SPI_SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
	reg if0_sclk_in = 1'b0;
	reg if1_miso_in = 1'b0;
	reg if0_mosi_in = 1'b0;
	
	// helper variables
	integer ready, done = 0;
	
	// helper task to simulate SPI communication
	task spi_transfer(input [7:0] miso_data, input [7:0] mosi_data);
		integer i;
		// simulate data clocked by SCLK
		for (i = NUM_DATA_BITS-1; i >= 0; i--) // most significat bit first
		begin
			if1_miso_in = miso_data[i];
			if0_mosi_in = mosi_data[i];
			
			#(SPI_CLK_PERIOD_NS / 2);
			if0_sclk_in = 1'b1;
			#(SPI_CLK_PERIOD_NS / 2);
			if0_sclk_in = 1'b0;
		end
		if1_miso_in = 1'b0;
		if0_mosi_in = 1'b0;
	endtask
	
	// helper task to simulate TPM read register sequence
	task tpm_read_reg(input [23:0] addr, integer r_size, integer num_waits, input [32*8:0] r_data);
		integer i;
		reg [31:0] tpm_cmd;
		reg [7:0] temp;
		
		temp[7] = 1'b1;
		temp[6:0] = (r_size & 7'h7f) - 1;
		tpm_cmd = {
			temp,  // Command: read 'r_size' bytes
			addr   // register address
		};
		
		// send command
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		for (i = 3; i >= 0; i--) // most significat byte first
		begin
			temp = (tpm_cmd >> (8 * i)) & 8'hff;
			// if no waits states shall be sent,
			// slave asserts ready by sending 0x01 on MISO line during last address byte
			if (i == 0 && num_waits == 0) begin
				spi_transfer(8'h01, temp);
			end
			else begin
				spi_transfer(8'h00, temp);
			end
			#(SPI_CLK_PERIOD_NS);
		end

		// wait states
		for (i = 0; i < num_waits; i++)
		begin
			if (i == num_waits - 1) begin
				spi_transfer(8'h01, 8'h00);
			end
			else begin
				spi_transfer(8'h00, 8'h00);
			end
			#(SPI_CLK_PERIOD_NS);
		end
		
		// read data bytes
		for (i = r_size - 1; i >= 0; i--) // most significat byte first
		begin
			temp = (r_data >> (8 * i)) & 8'hff;
			spi_transfer(temp, 8'h00);
			#(SPI_CLK_PERIOD_NS);
		end
		
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		#(SPI_CLK_PERIOD_NS);
	endtask
	
	// helper task to simulate TPM write register sequence
	task tpm_write_reg(input [23:0] addr, integer w_size, integer num_waits, input [32*8:0] w_data);
		integer i;
		reg [31:0] tpm_cmd;
		reg [7:0] temp;
		
		temp[7] = 1'b0;
		temp[6:0] = (w_size & 7'h7f) - 1;
		tpm_cmd = {
			temp,  // Command: write 'w_size' bytes
			addr   // register address
		};
		
		// send command
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b1 : 1'b0;
		#(SPI_CLK_PERIOD_NS);
		for (i = 3; i >= 0; i--) // most significat byte first
		begin
			temp = (tpm_cmd >> (8 * i)) & 8'hff;
			// if no waits states shall be sent,
			// slave asserts ready by sending 0x01 on MISO line during last address byte
			if (i == 0 && num_waits == 0) begin
				spi_transfer(8'h01, temp);
			end
			else begin
				spi_transfer(8'h00, temp);
			end
			#(SPI_CLK_PERIOD_NS);
		end
		
		// wait states
		for (i = 0; i < num_waits; i++)
		begin
			if (i == num_waits - 1) begin
				spi_transfer(8'h01, 8'h00);
			end
			else begin
				spi_transfer(8'h00, 8'h00);
			end
			#(SPI_CLK_PERIOD_NS);
		end
		
		// write data bytes
		for (i = w_size - 1; i >= 0; i--) // most significat byte first
		begin
			temp = (w_data >> (8 * i)) & 8'hff;
			spi_transfer(8'h00, temp);
			#(SPI_CLK_PERIOD_NS);
		end
		
		if0_ss_in = (SS_ACTIVE_LOW == 0) ? 1'b0 : 1'b1;
		#(SPI_CLK_PERIOD_NS);
	endtask
	
	// helper task to simulate TPM GetRandom command issuing
	task tpm_get_random_cmd(integer w_size);
		integer i, n;
		reg [32*8:0] temp_data;
		reg [23:0] reg_addr;
		reg [12*8:0] tpm_cmd;
		
		reg_addr = 24'hd40024;	// FIFO register address
	
		// TPM GetRandom command
		tpm_cmd = {
			8'h80, 8'h01,               // Tag: TPM2_ST_NO_SESSIONS
			8'h00, 8'h00, 8'h00, 8'h0c,	// Command len: 12 bytes
			8'h00, 8'h00, 8'h01, 8'h7b, // Command code: TPM2_CC_GetRandom
			8'h00, 8'h08                // Bytes requested
		};
		
		for (i = 12 / w_size - 1; i >= 0; i--) // most significat byte first
		begin
			n = $urandom % 3;
			temp_data = (tpm_cmd >> (8 * (i * w_size)));
			tpm_write_reg(reg_addr, w_size, n, temp_data);
		end
	endtask
	
	// helper task to simulate TPM GetRandom response querying
	task tpm_get_random_resp(integer r_size);
		integer i, n;
		reg [32*8:0] temp_data;
		reg [23:0] reg_addr;
		reg [20*8:0] tpm_resp;
		
		reg_addr = 24'hd40024;	// FIFO register address
	
		// TPM GetRandom response
		tpm_resp = {
			8'h80, 8'h01,               // Tag: TPM2_ST_NO_SESSIONS
			8'h00, 8'h00, 8'h00, 8'h14,	// Response len: 20 bytes (10 byte header + 10 byte TPM2B_DIGEST)
			8'h00, 8'h00, 8'h00, 8'h00, // Response code: TPM_RC_SUCCESS
			8'h00, 8'h08,               // TPM2B_DIGEST size: 8 random bytes
			8'h4a, 8'h3b, 8'h1c, 8'h21, // Radnom bytes
			8'h01, 8'ha7, 8'hcc, 8'h09  // Random bytes
		};
		
		for (i = 20 / r_size - 1; i >= 0; i--) // most significat byte first
		begin
			n = $urandom % 3;
			temp_data = (tpm_resp >> (8 * (i * r_size)));
			tpm_read_reg(reg_addr, r_size, n, temp_data);
		end
	endtask
	
	// instantiate uut
	TopLevelModule UUT (
		.ref_clk(ref_clk),
		
		.rst_btn(rst_btn),
		.mode_select_btn(mode_select_btn),
		
		.mode_leds(mode_leds),
		.comm_active_led(comm_active_led),
		
		.if0_ss_in(if0_ss_in),
		.if0_sclk_in(if0_sclk_in),
		.if1_miso_in(if1_miso_in),
		.if0_mosi_in(if0_mosi_in),
		.if1_ss_out(if1_ss_out),
		.if1_sclk_out(if1_sclk_out),
		.if0_miso_out(if0_miso_out),
		.if1_mosi_out(if1_mosi_out)
	);
	
	// generate sys_clock signal
	always
	begin
		#(CLK_PERIOD_NS / 2);
		ref_clk = ~ref_clk;
	end

	// generate some TPM GetRandom communication
	initial
	begin
		// wait for initialization
		wait (ready == 1);
		
		tpm_get_random_cmd(1);
		#(SPI_CLK_PERIOD_NS);
		tpm_get_random_resp(1);
		
		#(12 * SPI_CLK_PERIOD_NS);
		
		tpm_get_random_cmd(2);
		#(SPI_CLK_PERIOD_NS);
		tpm_get_random_resp(2);
		
		#(12 * SPI_CLK_PERIOD_NS);
		
		tpm_get_random_cmd(4);
		#(SPI_CLK_PERIOD_NS);
		tpm_get_random_resp(4);
		
		#(12 * SPI_CLK_PERIOD_NS);
		
		tpm_get_random_cmd(5);
		#(SPI_CLK_PERIOD_NS);
		tpm_get_random_resp(5);
		
		done = 1;
	end
	
	// test code
	initial
	begin
		// wait some time
		#100;
		
		// initial reset signal
		rst_btn = 1'b0;
		#(1_000 * DEBOUNCE_LEN_US + 3 * CLK_PERIOD_NS + $urandom % 200);
		rst_btn = 1'b1;
		
		// set mode to attack
		mode_select_btn = 1'b0;
		#(1_000 * DEBOUNCE_LEN_US + 3 * CLK_PERIOD_NS + $urandom % 200);
		mode_select_btn = 1'b1;
		
		// wait some time before asserting ready
		#(5 * CLK_PERIOD_NS);
		ready = 1;
	
		// wait for communication to complete
		wait (done == 1);
	end

	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("TpmGetRandomTopLevelModule_test.vcd");
		$dumpvars(0, TpmGetRandomTopLevelModule_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule