.PHONY: clean sim bin rpt default


# Directoriy declarations
SRC_DIR=src
TEST_DIR=tests

PRIM=primitives
IO=io

BUILD_DIR=build
VVP_DIR=$(BUILD_DIR)/vvp
SIM_DIR=$(BUILD_DIR)/simulations
RPT_DIR=$(BUILD_DIR)/reports


default: sim bin rpt


include icestick.mk
include test.mk


# Generate timing constraints report
rpt: $(RPT_DIR)/icestick.rpt

# Build icestick binary
bin: $(BUILD_DIR)/icestick.bin

# Run all simulations
sim: \
		$(SIM_DIR)/$(PRIM)/ClockGenerator_test.vcd \
		$(SIM_DIR)/$(PRIM)/EdgeDetector_test.vcd \
		$(SIM_DIR)/$(PRIM)/OutputMux_test.vcd \
		$(SIM_DIR)/$(PRIM)/SerialReadBuffer_test.vcd \
		$(SIM_DIR)/$(PRIM)/SerialWriteBuffer_test.vcd \
		$(SIM_DIR)/$(IO)/IoHandler_test.vcd \
		$(SIM_DIR)/$(IO)/SignalDebouncer_test.vcd \
		$(SIM_DIR)/$(IO)/Synchronizer_test.vcd \
		$(SIM_DIR)/MitmLogic_test.vcd \
		$(SIM_DIR)/BusControl_test.vcd \
		$(SIM_DIR)/TopLevelModule_test.vcd;


# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	
$(VVP_DIR):
	mkdir -p $(VVP_DIR)
	
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(RPT_DIR):
	mkdir -p $(RPT_DIR)


# Clean rule
clean:
	rm -rf $(BUILD_DIR)