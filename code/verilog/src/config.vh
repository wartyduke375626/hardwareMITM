/**
 * Parameter configuration
**/

// system parameters
parameter SYS_FREQ = 48;	// frequency in MHz

// MITM parameters
parameter MODE_WIDTH = 4;

// general bus parameters
parameter NUM_DATA_BITS = 8;

// bus specific parameters

// UART:
`ifdef BUS_UART
	parameter UART_BAUD_RATE = 115_200;
`endif
