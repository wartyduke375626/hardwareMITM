YOSYS_FLAGS=-q -p
YOSYS_CMD=synth_ice40 -relut

NEXTPNR_FLAGS=--hx1k --package tq144 --freq 48 --opt-timing

ICEPACK_FLAGS=-s

ICETIME_FLAGS=-d hx1k -P tq144 -c 48 -t


# Generate timing constraints report
$(REPORT_DIR)/icestick.rpt: $(BUILD_DIR)/icestick.asc $(SRC_DIR)/icestick.pcf | $(REPORT_DIR)
	icetime $(ICETIME_FLAGS) -p $(SRC_DIR)/icestick.pcf -r $@ $<


# Build icestick binary
$(BUILD_DIR)/icestick.bin: $(BUILD_DIR)/icestick.asc
	icepack $(ICEPACK_FLAGS) $< $@

$(BUILD_DIR)/icestick.asc: $(BUILD_DIR)/icestick.json $(SRC_DIR)/icestick.pcf | $(BUILD_DIR)
	nextpnr-ice40 $(NEXTPNR_FLAGS) --json $< --pcf $(SRC_DIR)/icestick.pcf --asc $@

$(BUILD_DIR)/icestick.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/MitmControl.v \
		$(SRC_DIR)/EdgeDetector.v $(SRC_DIR)/MitmLogic.v $(SRC_DIR)/OutputMux.v \
		$(SRC_DIR)/ResetDebouncer.v $(SRC_DIR)/SerialReadBuffer.v $(SRC_DIR)/SerialWriteBuffer.v \
		$(SRC_DIR)/Synchronizer.v | $(BUILD_DIR)
	yosys $(YOSYS_FLAGS) "$(YOSYS_CMD) -top TopLevelModule -json $@" $^