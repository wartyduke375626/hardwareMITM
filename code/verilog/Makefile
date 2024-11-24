.PHONY: clean simulate bin rpt default


# Directoriy declarations
SRC_DIR=src
TEST_DIR=test

BUILD_DIR=build
TEST_BUILD_DIR=$(BUILD_DIR)/test
SIM_DIR=sim
REPORT_DIR=report


default: simulate bin rpt


include icestick.mk
include test.mk


# Generate timing constraints report
rpt: $(REPORT_DIR)/icestick.rpt

# Build icestick binary
bin: $(BUILD_DIR)/icestick.bin

# Run all simulations
simulate: \
		$(SIM_DIR)/BusControl_test.vcd \
		$(SIM_DIR)/ClockGenerator_test.vcd \
		$(SIM_DIR)/EdgeDetector_test.vcd \
		$(SIM_DIR)/IoHandler_test.vcd \
		$(SIM_DIR)/MitmLogic_test.vcd \
		$(SIM_DIR)/OutputMux_test.vcd \
		$(SIM_DIR)/SerialReadBuffer_test.vcd \
		$(SIM_DIR)/SerialWriteBuffer_test.vcd \
		$(SIM_DIR)/SignalDebouncer_test.vcd \
		$(SIM_DIR)/Synchronizer_test.vcd \
		$(SIM_DIR)/TopLevelModule_test.vcd;


# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	
$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)
	
$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(REPORT_DIR):
	mkdir -p $(REPORT_DIR)


# Clean rule
clean:
	rm -rf $(BUILD_DIR) $(SIM_DIR) $(REPORT_DIR)