.PHONY: clean sim bin default \
	icestick-spi icestick-uart \
	ice40hx8k-spi ice40hx8k-uart


# Directory declarations
SRC_DIR=src
TEST_DIR=tests

BUILD_DIR=build
VVP_DIR=$(BUILD_DIR)/vvp
SIM_DIR=$(BUILD_DIR)/simulations
MODULE_DIR=$(BUILD_DIR)/modules
SYNTH_DIR=$(BUILD_DIR)/synthesis
PCF_DIR=$(BUILD_DIR)/pcf
PNR_DIR=$(BUILD_DIR)/nextpnr
RPT_DIR=$(BUILD_DIR)/reports
BIN_DIR=$(BUILD_DIR)/bin


default: sim bin


include icestick.mk
include ice40hx8k.mk
include common.mk
include test.mk


# Build all binaries
bin: \
		$(BIN_DIR)/icestick-spi.bin \
		$(BIN_DIR)/icestick-uart.bin \
		$(BIN_DIR)/ice40hx8k-spi.bin \
		$(BIN_DIR)/ice40hx8k-uart.bin;

# Build specific binaries
icestick-spi: $(BIN_DIR)/icestick-spi.bin
icestick-uart: $(BIN_DIR)/icestick-uart.bin
ice40hx8k-spi: $(BIN_DIR)/ice40hx8k-spi.bin
ice40hx8k-uart: $(BIN_DIR)/ice40hx8k-uart.bin

# Run all simulations
sim: \
		$(SIM_DIR)/primitives/Counter_test.vcd \
		$(SIM_DIR)/primitives/EdgeDetector_test.vcd \
		$(SIM_DIR)/primitives/OutputMux_test.vcd \
		$(SIM_DIR)/primitives/PulseGenerator_test.vcd \
		$(SIM_DIR)/primitives/SerialReadBuffer_test.vcd \
		$(SIM_DIR)/primitives/SerialWriteBuffer_test.vcd \
		$(SIM_DIR)/io/IoHandler_test.vcd \
		$(SIM_DIR)/io/SignalDebouncer_test.vcd \
		$(SIM_DIR)/io/Synchronizer_test.vcd \
		$(SIM_DIR)/buses/spi/SpiController_test.vcd \
		$(SIM_DIR)/buses/spi/SpiMasterDriver_test.vcd \
		$(SIM_DIR)/buses/spi/SpiSlaveDriver_test.vcd \
		$(SIM_DIR)/buses/uart/UartController_test.vcd \
		$(SIM_DIR)/buses/uart/UartDriver_test.vcd \
		$(SIM_DIR)/SpiTopLevelModule_test.vcd \
		$(SIM_DIR)/TpmGetRandomTopLevelModule_test.vcd \
		$(SIM_DIR)/UartTopLevelModule_test.vcd;


# Create directories
$(BUILD_DIR):
	mkdir -p $@

$(VVP_DIR):
	mkdir -p $@

$(SIM_DIR):
	mkdir -p $@

$(MODULE_DIR):
	mkdir -p $@

$(SYNTH_DIR):
	mkdir -p $@

$(PCF_DIR):
	mkdir -p $@

$(PNR_DIR):
	mkdir -p $@

$(RPT_DIR):
	mkdir -p $@

$(BIN_DIR):
	mkdir -p $@


# Clean rule
clean:
	rm -rf $(BUILD_DIR)