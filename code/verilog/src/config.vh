/**
 * Parameter configuration
**/

// system clock parameters
// set these according to the icepll tool to get the desired frequency
`define SYS_FREQ 48	// system frequency in MHz

// io parameters
`define DEBOUNCE_DURATION_US 50_000	// duration (in microseconds) of stable button input signal to detect change

// MITM parameters
`define MODE_WIDTH 4	// number of MITM modes

// general bus parameters
`define NUM_DATA_BITS 8	// number of data bits per frame

// bus specific parameters

// UART:
`define	UART_BAUD_RATE 115_200
