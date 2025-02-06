.PHONY: clean sim bin default


# Directory declarations
SRC_DIR=src
TEST_DIR=tests

BUILD_DIR=build
VVP_DIR=$(BUILD_DIR)/vvp
SIM_DIR=$(BUILD_DIR)/simulations
SYNTH_DIR=$(BUILD_DIR)/synthesis
PCF_DIR=$(BUILD_DIR)/pcf
PNR_DIR=$(BUILD_DIR)/nextpnr
RPT_DIR=$(BUILD_DIR)/reports
BIN_DIR=$(BUILD_DIR)/bin


default: sim bin


include icestick.mk
include test.mk


# Build all binaries
bin: $(BIN_DIR)/icestick-uart.bin


# Run all simulations
sim: \
		$(SIM_DIR)/primitives/EdgeDetector_test.vcd \
		$(SIM_DIR)/primitives/OutputMux_test.vcd \
		$(SIM_DIR)/primitives/PulseGenerator_test.vcd \
		$(SIM_DIR)/primitives/SerialReadBuffer_test.vcd \
		$(SIM_DIR)/primitives/SerialWriteBuffer_test.vcd \
		$(SIM_DIR)/io/IoHandler_test.vcd \
		$(SIM_DIR)/io/SignalDebouncer_test.vcd \
		$(SIM_DIR)/io/Synchronizer_test.vcd \
		$(SIM_DIR)/buses/uart/UartController_test.vcd \
		$(SIM_DIR)/buses/uart/UartDriver_test.vcd \
		$(SIM_DIR)/UartTopLevelModule_test.vcd \
		$(SIM_DIR)/proprietary_eeprom/MitmLogic_test.vcd \
		$(SIM_DIR)/proprietary_eeprom/BusControl_test.vcd \
		$(SIM_DIR)/proprietary_eeprom/TopLevelModule_test.vcd;


# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(VVP_DIR):
	mkdir -p $(VVP_DIR)

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(SYNTH_DIR):
	mkdir -p $(SYNTH_DIR)

$(PCF_DIR):
	mkdir -p $(PCF_DIR)

$(PNR_DIR):
	mkdir -p $(PNR_DIR)

$(RPT_DIR):
	mkdir -p $(RPT_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)


# Clean rule
clean:
	rm -rf $(BUILD_DIR)