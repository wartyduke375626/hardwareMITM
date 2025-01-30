# This Makefile module includes all testing rules for verilog modules


IV_FLAGS=-DBENCH


# Run simulation rules:

# Primitives:
$(SIM_DIR)/$(PRIM)/EdgeDetector_test.vcd: $(VVP_DIR)/EdgeDetector_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/$(PRIM)/OutputMux_test.vcd: $(VVP_DIR)/OutputMux_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/$(PRIM)/PulseGenerator_test.vcd: $(VVP_DIR)/PulseGenerator_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/$(PRIM)/SerialReadBuffer_test.vcd: $(VVP_DIR)/SerialReadBuffer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/$(PRIM)/SerialWriteBuffer_test.vcd: $(VVP_DIR)/SerialWriteBuffer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@


# IO:
$(SIM_DIR)/$(IO)/IoHandler_test.vcd: $(VVP_DIR)/IoHandler_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/$(IO)/SignalDebouncer_test.vcd: $(VVP_DIR)/SignalDebouncer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/$(IO)/Synchronizer_test.vcd: $(VVP_DIR)/Synchronizer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@


# Buses:
$(SIM_DIR)/$(BUS)/uart/UartDriver_test.vcd: $(VVP_DIR)/UartDriver_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@


# Other:
$(SIM_DIR)/BusControl_test.vcd: $(VVP_DIR)/BusControl_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/MitmLogic_test.vcd: $(VVP_DIR)/MitmLogic_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/TopLevelModule_test.vcd: $(VVP_DIR)/TopLevelModule_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@


# IVerilog build rules

# Primitives:
$(VVP_DIR)/EdgeDetector_test.vvp: $(TEST_DIR)/$(PRIM)/EdgeDetector_test.v $(SRC_DIR)/$(PRIM)/EdgeDetector.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/OutputMux_test.vvp: $(TEST_DIR)/$(PRIM)/OutputMux_test.v $(SRC_DIR)/$(PRIM)/OutputMux.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/PulseGenerator_test.vvp: $(TEST_DIR)/$(PRIM)/PulseGenerator_test.v $(SRC_DIR)/$(PRIM)/PulseGenerator.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SerialReadBuffer_test.vvp: $(TEST_DIR)/$(PRIM)/SerialReadBuffer_test.v $(SRC_DIR)/$(PRIM)/SerialReadBuffer.v \
		$(SRC_DIR)/$(PRIM)/EdgeDetector.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SerialWriteBuffer_test.vvp: $(TEST_DIR)/$(PRIM)/SerialWriteBuffer_test.v $(SRC_DIR)/$(PRIM)/SerialWriteBuffer.v \
		$(SRC_DIR)/$(PRIM)/EdgeDetector.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@


# IO:
$(VVP_DIR)/IoHandler_test.vvp: $(TEST_DIR)/$(IO)/IoHandler_test.v $(SRC_DIR)/$(IO)/IoHandler.v \
		$(SRC_DIR)/$(IO)/SignalDebouncer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SignalDebouncer_test.vvp: $(TEST_DIR)/$(IO)/SignalDebouncer_test.v $(SRC_DIR)/$(IO)/SignalDebouncer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/Synchronizer_test.vvp: $(TEST_DIR)/$(IO)/Synchronizer_test.v $(SRC_DIR)/$(IO)/Synchronizer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@


# Buses:
$(VVP_DIR)/UartDriver_test.vvp: $(TEST_DIR)/$(BUS)/uart/UartDriver_test.v $(SRC_DIR)/$(BUS)/uart/UartDriver.v \
		$(SRC_DIR)/$(PRIM)/EdgeDetector.v $(SRC_DIR)/$(PRIM)/PulseGenerator.v \
		$(SRC_DIR)/$(PRIM)/SerialReadBuffer.v $(SRC_DIR)/$(PRIM)/SerialWriteBuffer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@


# Other:
$(VVP_DIR)/BusControl_test.vvp: $(TEST_DIR)/BusControl_test.v $(SRC_DIR)/BusControl.v \
		$(SRC_DIR)/$(PRIM)/EdgeDetector.v $(SRC_DIR)/$(PRIM)/OutputMux.v \
		$(SRC_DIR)/$(PRIM)/SerialReadBuffer.v $(SRC_DIR)/$(PRIM)/SerialWriteBuffer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/MitmLogic_test.vvp: $(TEST_DIR)/MitmLogic_test.v $(SRC_DIR)/MitmLogic.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/TopLevelModule_test.vvp: $(TEST_DIR)/TopLevelModule_test.v $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/BusControl.v \
		$(SRC_DIR)/MitmLogic.v $(SRC_DIR)/$(PRIM)/*.v $(SRC_DIR)/$(IO)/*.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@