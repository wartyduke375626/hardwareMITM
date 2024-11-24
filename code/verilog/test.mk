IV_FLAGS=-DBENCH


# Run simulation rule for each test
$(SIM_DIR)/BusControl_test.vcd: $(TEST_BUILD_DIR)/BusControl_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/ClockGenerator_test.vcd: $(TEST_BUILD_DIR)/ClockGenerator_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/EdgeDetector_test.vcd: $(TEST_BUILD_DIR)/EdgeDetector_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/IoHandler_test.vcd: $(TEST_BUILD_DIR)/IoHandler_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/MitmLogic_test.vcd: $(TEST_BUILD_DIR)/MitmLogic_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/OutputMux_test.vcd: $(TEST_BUILD_DIR)/OutputMux_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/SerialReadBuffer_test.vcd: $(TEST_BUILD_DIR)/SerialReadBuffer_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/SerialWriteBuffer_test.vcd: $(TEST_BUILD_DIR)/SerialWriteBuffer_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/SignalDebouncer_test.vcd: $(TEST_BUILD_DIR)/SignalDebouncer_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/Synchronizer_test.vcd: $(TEST_BUILD_DIR)/Synchronizer_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)

$(SIM_DIR)/TopLevelModule_test.vcd: $(TEST_BUILD_DIR)/TopLevelModule_test | $(SIM_DIR)
	(cd $(SIM_DIR) && exec vvp ../$<)


# Compile rules for each tests
$(TEST_BUILD_DIR)/BusControl_test: $(TEST_DIR)/BusControl_test.v $(SRC_DIR)/BusControl.v \
		$(SRC_DIR)/EdgeDetector.v $(SRC_DIR)/OutputMux.v \
		$(SRC_DIR)/SerialReadBuffer.v $(SRC_DIR)/SerialWriteBuffer.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/ClockGenerator_test: $(TEST_DIR)/ClockGenerator_test.v $(SRC_DIR)/ClockGenerator.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/EdgeDetector_test: $(TEST_DIR)/EdgeDetector_test.v $(SRC_DIR)/EdgeDetector.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/IoHandler_test: $(TEST_DIR)/IoHandler_test.v $(SRC_DIR)/IoHandler.v $(SRC_DIR)/SignalDebouncer.v | $(TEST_BUILD_DIR)
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

$(TEST_BUILD_DIR)/SignalDebouncer_test: $(TEST_DIR)/SignalDebouncer_test.v $(SRC_DIR)/SignalDebouncer.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/Synchronizer_test: $(TEST_DIR)/Synchronizer_test.v $(SRC_DIR)/Synchronizer.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(TEST_BUILD_DIR)/TopLevelModule_test: $(TEST_DIR)/TopLevelModule_test.v $(SRC_DIR)/TopLevelModule.v \
		$(SRC_DIR)/BusControl.v $(SRC_DIR)/EdgeDetector.v $(SRC_DIR)/IoHandler.v $(SRC_DIR)/MitmLogic.v \
		$(SRC_DIR)/OutputMux.v $(SRC_DIR)/SerialReadBuffer.v $(SRC_DIR)/SerialWriteBuffer.v \
		$(SRC_DIR)/SignalDebouncer.v $(SRC_DIR)/Synchronizer.v | $(TEST_BUILD_DIR)
	iverilog $(IV_FLAGS) $^ -o $@