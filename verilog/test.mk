IV_FLAGS=-DBENCH


# run all simulations
sim-all: \
		$(SIM_DIR)/ClockGenerator_test.vcd \
		$(SIM_DIR)/EdgeDetector_test.vcd \
		$(SIM_DIR)/MitmControl_test.vcd \
		$(SIM_DIR)/MitmLogic_test.vcd \
		$(SIM_DIR)/OutputMux_test.vcd \
		$(SIM_DIR)/SerialReadBuffer_test.vcd \
		$(SIM_DIR)/SerialWriteBuffer_test.vcd;


# Run simulation rule for each test
$(SIM_DIR)/ClockGenerator_test.vcd: $(TEST_BUILD_DIR)/ClockGenerator_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/EdgeDetector_test.vcd: $(TEST_BUILD_DIR)/EdgeDetector_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/MitmControl_test.vcd: $(TEST_BUILD_DIR)/MitmControl_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/MitmLogic_test.vcd: $(TEST_BUILD_DIR)/MitmLogic_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/OutputMux_test.vcd: $(TEST_BUILD_DIR)/OutputMux_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/SerialReadBuffer_test.vcd: $(TEST_BUILD_DIR)/SerialReadBuffer_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/SerialWriteBuffer_test.vcd: $(TEST_BUILD_DIR)/SerialWriteBuffer_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)


# Compile rules for each tests
$(TEST_BUILD_DIR)/ClockGenerator_test: $(TEST_DIR)/ClockGenerator_test.v $(SRC_DIR)/ClockGenerator.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/EdgeDetector_test: $(TEST_DIR)/EdgeDetector_test.v $(SRC_DIR)/EdgeDetector.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/MitmControl_test: $(TEST_DIR)/MitmControl_test.v $(SRC_DIR)/MitmControl.v \
		$(SRC_DIR)/EdgeDetector.v $(SRC_DIR)/MitmLogic.v $(SRC_DIR)/OutputMux.v \
		$(SRC_DIR)/SerialReadBuffer.v $(SRC_DIR)/SerialWriteBuffer.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/MitmLogic_test: $(TEST_DIR)/MitmLogic_test.v $(SRC_DIR)/MitmLogic.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/OutputMux_test: $(TEST_DIR)/OutputMux_test.v $(SRC_DIR)/OutputMux.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/SerialReadBuffer_test: $(TEST_DIR)/SerialReadBuffer_test.v $(SRC_DIR)/SerialReadBuffer.v \
		$(SRC_DIR)/EdgeDetector.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/SerialWriteBuffer_test: $(TEST_DIR)/SerialWriteBuffer_test.v $(SRC_DIR)/SerialWriteBuffer.v \
		$(SRC_DIR)/EdgeDetector.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@