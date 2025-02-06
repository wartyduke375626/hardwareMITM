# This Makefile module includes rules for building the final binary


YOSYS_FLAGS=-q -p
YOSYS_CMD=synth_ice40 -relut

NEXTPNR_FLAGS=--hx1k --package tq144 --freq 48 --opt-timing

ICEPACK_FLAGS=-s

ICETIME_FLAGS=-d hx1k -P tq144 -c 48 -t


# Generate timing constraints report
$(RPT_DIR)/icestick.rpt: $(BUILD_DIR)/icestick.asc $(SRC_DIR)/proprietary_eeprom/icestick.pcf | $(RPT_DIR)
	icetime $(ICETIME_FLAGS) -p $(SRC_DIR)/proprietary_eeprom/icestick.pcf -r $@ $<


# Build icestick binary
$(BUILD_DIR)/icestick.bin: $(BUILD_DIR)/icestick.asc
	icepack $(ICEPACK_FLAGS) $< $@

$(BUILD_DIR)/icestick.asc: $(BUILD_DIR)/icestick.json $(SRC_DIR)/proprietary_eeprom/icestick.pcf | $(BUILD_DIR)
	nextpnr-ice40 $(NEXTPNR_FLAGS) --json $< --pcf $(SRC_DIR)/proprietary_eeprom/icestick.pcf --asc $@

$(BUILD_DIR)/icestick.json: $(SRC_DIR)/proprietary_eeprom/TopLevelModule.v $(SRC_DIR)/proprietary_eeprom/BusControl.v \
		$(SRC_DIR)/proprietary_eeprom/MitmLogic.v $(SRC_DIR)/$(IO)/*.v $(SRC_DIR)/$(PRIM)/*.v | $(BUILD_DIR)
	yosys $(YOSYS_FLAGS) "$(YOSYS_CMD) -top TopLevelModule -json $@" $^