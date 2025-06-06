# This Makefile module includes all testing rules for verilog modules


IV_FLAGS=-DBENCH -g2012


# Run simulation rules:

# Primitives:
$(SIM_DIR)/primitives/Counter_test.vcd: $(VVP_DIR)/Counter_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/primitives/EdgeDetector_test.vcd: $(VVP_DIR)/EdgeDetector_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/primitives/OutputMux_test.vcd: $(VVP_DIR)/OutputMux_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/primitives/PulseGenerator_test.vcd: $(VVP_DIR)/PulseGenerator_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/primitives/SerialReadBuffer_test.vcd: $(VVP_DIR)/SerialReadBuffer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/primitives/SerialWriteBuffer_test.vcd: $(VVP_DIR)/SerialWriteBuffer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@


# IO:
$(SIM_DIR)/io/IoHandler_test.vcd: $(VVP_DIR)/IoHandler_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/io/SignalDebouncer_test.vcd: $(VVP_DIR)/SignalDebouncer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/io/Synchronizer_test.vcd: $(VVP_DIR)/Synchronizer_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@


# Buses:
$(SIM_DIR)/buses/spi/SpiController_test.vcd: $(VVP_DIR)/SpiController_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/buses/spi/SpiMasterDriver_test.vcd: $(VVP_DIR)/SpiMasterDriver_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/buses/spi/SpiSlaveDriver_test.vcd: $(VVP_DIR)/SpiSlaveDriver_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/buses/uart/UartController_test.vcd: $(VVP_DIR)/UartController_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/buses/uart/UartDriver_test.vcd: $(VVP_DIR)/UartDriver_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@


# Top level module tests:
$(SIM_DIR)/SpiTopLevelModule_test.vcd: $(VVP_DIR)/SpiTopLevelModule_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/TpmGetRandomTopLevelModule_test.vcd: $(VVP_DIR)/TpmGetRandomTopLevelModule_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@

$(SIM_DIR)/UartTopLevelModule_test.vcd: $(VVP_DIR)/UartTopLevelModule_test.vvp | $(SIM_DIR)
	vvp $<
	mkdir -p $$(dirname $@) && mv $$(basename $@) $@



# IVerilog build rules

# Primitives:
$(VVP_DIR)/Counter_test.vvp: $(TEST_DIR)/primitives/Counter_test.v $(SRC_DIR)/primitives/Counter.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/EdgeDetector_test.vvp: $(TEST_DIR)/primitives/EdgeDetector_test.v $(SRC_DIR)/primitives/EdgeDetector.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/OutputMux_test.vvp: $(TEST_DIR)/primitives/OutputMux_test.v $(SRC_DIR)/primitives/OutputMux.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/PulseGenerator_test.vvp: $(TEST_DIR)/primitives/PulseGenerator_test.v $(SRC_DIR)/primitives/PulseGenerator.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SerialReadBuffer_test.vvp: $(TEST_DIR)/primitives/SerialReadBuffer_test.v $(SRC_DIR)/primitives/SerialReadBuffer.v \
		$(SRC_DIR)/primitives/EdgeDetector.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SerialWriteBuffer_test.vvp: $(TEST_DIR)/primitives/SerialWriteBuffer_test.v $(SRC_DIR)/primitives/SerialWriteBuffer.v \
		$(SRC_DIR)/primitives/EdgeDetector.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@


# IO:
$(VVP_DIR)/IoHandler_test.vvp: $(TEST_DIR)/io/IoHandler_test.v $(SRC_DIR)/io/IoHandler.v \
		$(SRC_DIR)/io/SignalDebouncer.v $(SRC_DIR)/io/Synchronizer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SignalDebouncer_test.vvp: $(TEST_DIR)/io/SignalDebouncer_test.v $(SRC_DIR)/io/SignalDebouncer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/Synchronizer_test.vvp: $(TEST_DIR)/io/Synchronizer_test.v $(SRC_DIR)/io/Synchronizer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@


# Buses:
$(VVP_DIR)/SpiController_test.vvp: $(TEST_DIR)/buses/spi/SpiController_test.v $(SRC_DIR)/buses/spi/SpiController.v \
		$(SRC_DIR)/buses/spi/SpiMasterDriver.v $(SRC_DIR)/buses/spi/SpiSlaveDriver.v $(SRC_DIR)/primitives/Counter.v \
		$(SRC_DIR)/primitives/EdgeDetector.v $(SRC_DIR)/primitives/OutputMux.v $(SRC_DIR)/primitives/PulseGenerator.v \
		$(SRC_DIR)/primitives/SerialReadBuffer.v $(SRC_DIR)/primitives/SerialWriteBuffer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SpiMasterDriver_test.vvp: $(TEST_DIR)/buses/spi/SpiMasterDriver_test.v $(SRC_DIR)/buses/spi/SpiMasterDriver.v \
		$(SRC_DIR)/primitives/Counter.v $(SRC_DIR)/primitives/EdgeDetector.v $(SRC_DIR)/primitives/PulseGenerator.v \
		$(SRC_DIR)/primitives/SerialReadBuffer.v $(SRC_DIR)/primitives/SerialWriteBuffer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/SpiSlaveDriver_test.vvp: $(TEST_DIR)/buses/spi/SpiSlaveDriver_test.v $(SRC_DIR)/buses/spi/SpiSlaveDriver.v \
		$(SRC_DIR)/primitives/EdgeDetector.v $(SRC_DIR)/primitives/SerialReadBuffer.v $(SRC_DIR)/primitives/SerialWriteBuffer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/UartController_test.vvp: $(TEST_DIR)/buses/uart/UartController_test.v $(SRC_DIR)/buses/uart/UartController.v \
		$(SRC_DIR)/buses/uart/UartDriver.v $(SRC_DIR)/primitives/EdgeDetector.v $(SRC_DIR)/primitives/OutputMux.v \
		$(SRC_DIR)/primitives/PulseGenerator.v $(SRC_DIR)/primitives/SerialReadBuffer.v $(SRC_DIR)/primitives/SerialWriteBuffer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/UartDriver_test.vvp: $(TEST_DIR)/buses/uart/UartDriver_test.v $(SRC_DIR)/buses/uart/UartDriver.v \
		$(SRC_DIR)/primitives/EdgeDetector.v $(SRC_DIR)/primitives/PulseGenerator.v \
		$(SRC_DIR)/primitives/SerialReadBuffer.v $(SRC_DIR)/primitives/SerialWriteBuffer.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@


# Top level module tests:
$(VVP_DIR)/SpiTopLevelModule_test.vvp: $(TEST_DIR)/SpiTopLevelModule_test.v $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/MitmLogic.v \
		$(SRC_DIR)/buses/BusInterface.v $(SRC_DIR)/buses/spi/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/TpmGetRandomTopLevelModule_test.vvp: $(TEST_DIR)/TpmGetRandomTopLevelModule_test.v $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/MitmLogic.v \
		$(SRC_DIR)/buses/BusInterface.v $(SRC_DIR)/buses/spi/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@

$(VVP_DIR)/UartTopLevelModule_test.vvp: $(TEST_DIR)/UartTopLevelModule_test.v $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/MitmLogic.v \
		$(SRC_DIR)/buses/BusInterface.v $(SRC_DIR)/buses/uart/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v | $(VVP_DIR)
	iverilog $(IV_FLAGS) $^ -o $@