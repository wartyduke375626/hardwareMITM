/**
 * Parameter configuration
**/

// system clock parameters
// set these according to the icepll tool to get the desired frequency
`define SYS_FREQ 72	// system frequency in MHz (suppoted range 16 -- 275)

// io parameters
`define DEBOUNCE_LEN_US 50_000	// duration (in microseconds) of stable button input signal to detect change

// MITM parameters
`define NUM_MITM_MODES 4	// maximum supported number is 4

// general bus parameters
`define NUM_DATA_BITS 8	// number of data bits per frame

// bus specific parameters

// UART:
`define	UART_BAUD_RATE 115_200

// SPI
`define SPI_FREQ_HZ 1_000_000
`define SPI_SS_ACTIVE_LOW 1
`define SPI_LSB_FIRST 0
