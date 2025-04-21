/**
 * Parameter configuration:
 * - edit this file to change MITM FPGA configuration
**/

// system clock parameters
// if the desired frequency is too high (depending logic design complexity), nextpnr migth fail to suffice timing constraints (build might fail)
`define SYS_FREQ 60	// system frequency in MHz (suppoted range 16 -- 275)

// io parameters
`define DEBOUNCE_LEN_US 50_000	// duration (in microseconds) of stable button input signal to detect change

// MITM parameters
`define NUM_MITM_MODES 4	// maximum supported number is 4

// general bus parameters
`define NUM_DATA_BITS 8	// number of data bits per frame

// bus specific parameters

// UART
`define	UART_BAUD_RATE 115_200

// SPI
`define SPI_FREQ_HZ 1_000_000
`define SPI_SS_ACTIVE_LOW 1
`define SPI_LSB_FIRST 0
