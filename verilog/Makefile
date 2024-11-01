.phony: clean sim-all default


SRC_DIR=src
TEST_DIR=test


BUILD_DIR=build
TEST_BUILD_DIR=$(BUILD_DIR)/test
SIM_DIR=sim


IV_FLAGS=-DBENCH



default: sim-all
	
	
# Simulate all tests
sim-all: $(SIM_DIR)/ClockGenerator_test.vcd $(SIM_DIR)/EdgeDetector_test.vcd $(SIM_DIR)/MitmControl_test.vcd $(SIM_DIR)/MitmLogic_test.vcd $(SIM_DIR)/OutputMux_test.vcd $(SIM_DIR)/SerialReadBuffer_test.vcd $(SIM_DIR)/SerialWriteBuffer_test.vcd
	
	
# Simulation rule for each test
$(SIM_DIR)/ClockGenerator_test.vcd: $(TEST_BUILD_DIR)/ClockGenerator_test $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)
	
$(SIM_DIR)/EdgeDetector_test.vcd: $(TEST_BUILD_DIR)/EdgeDetector_test $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)
	
$(SIM_DIR)/MitmControl_test.vcd: $(TEST_BUILD_DIR)/MitmControl_test $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)
	
$(SIM_DIR)/MitmLogic_test.vcd: $(TEST_BUILD_DIR)/MitmLogic_test $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/OutputMux_test.vcd: $(TEST_BUILD_DIR)/OutputMux_test $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/SerialReadBuffer_test.vcd: $(TEST_BUILD_DIR)/SerialReadBuffer_test $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/SerialWriteBuffer_test.vcd: $(TEST_BUILD_DIR)/SerialWriteBuffer_test $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)
	
	
# Compile rules for each tests
$(TEST_BUILD_DIR)/ClockGenerator_test: $(TEST_DIR)/ClockGenerator_test.v $(SRC_DIR)/*.v $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $(SRC_DIR)/*.v $< -o $@

$(TEST_BUILD_DIR)/EdgeDetector_test: $(TEST_DIR)/EdgeDetector_test.v $(SRC_DIR)/*.v $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $(SRC_DIR)/*.v $< -o $@
	
$(TEST_BUILD_DIR)/MitmControl_test: $(TEST_DIR)/MitmControl_test.v $(SRC_DIR)/*.v $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $(SRC_DIR)/*.v $< -o $@
	
$(TEST_BUILD_DIR)/MitmLogic_test: $(TEST_DIR)/MitmLogic_test.v $(SRC_DIR)/*.v $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $(SRC_DIR)/*.v $< -o $@

$(TEST_BUILD_DIR)/OutputMux_test: $(TEST_DIR)/OutputMux_test.v $(SRC_DIR)/*.v $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $(SRC_DIR)/*.v $< -o $@

$(TEST_BUILD_DIR)/SerialReadBuffer_test: $(TEST_DIR)/SerialReadBuffer_test.v $(SRC_DIR)/*.v $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $(SRC_DIR)/*.v $< -o $@

$(TEST_BUILD_DIR)/SerialWriteBuffer_test: $(TEST_DIR)/SerialWriteBuffer_test.v $(SRC_DIR)/*.v $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $(SRC_DIR)/*.v $< -o $@


# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	
$(TEST_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $(TEST_BUILD_DIR)
	
$(SIM_DIR):
	mkdir -p $(SIM_DIR)


# Clean rule
clean:
	rm -r $(BUILD_DIR) $(SIM_DIR)