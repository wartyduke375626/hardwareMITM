# This Makefile module includes rules for building the final binary for the Icestick FPGA

ICESTICK_NEXTPNR_FLAGS=--hx1k --package tq144

ICESTICK_ICETIME_FLAGS=-d hx1k -P tq144

# Build icestick binary
$(BIN_DIR)/icestick-spi.bin: $(PNR_DIR)/icestick-spi.asc $(RPT_DIR)/icestick-spi.rpt | $(BIN_DIR)
	icepack $(ICEPACK_FLAGS) $< $@

$(BIN_DIR)/icestick-uart.bin: $(PNR_DIR)/icestick-uart.asc $(RPT_DIR)/icestick-uart.rpt | $(BIN_DIR)
	icepack $(ICEPACK_FLAGS) $< $@


# Generate timing constraints report
$(RPT_DIR)/icestick-spi.rpt: $(PNR_DIR)/icestick-spi.asc $(PCF_DIR)/icestick-spi.pcf | $(RPT_DIR)
	icetime $(COMMON_ICETIME_FLAGS) $(ICESTICK_ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<

$(RPT_DIR)/icestick-uart.rpt: $(PNR_DIR)/icestick-uart.asc $(PCF_DIR)/icestick-uart.pcf | $(RPT_DIR)
	icetime $(COMMON_ICETIME_FLAGS) $(ICESTICK_ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<


# Place and route
$(PNR_DIR)/icestick-spi.asc: $(SYNTH_DIR)/synth-spi.json $(PCF_DIR)/icestick-spi.pcf | $(PNR_DIR)
	nextpnr-ice40 $(COMMON_NEXTPNR_FLAGS) $(ICESTICK_NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@

$(PNR_DIR)/icestick-uart.asc: $(SYNTH_DIR)/synth-uart.json $(PCF_DIR)/icestick-uart.pcf | $(PNR_DIR)
	nextpnr-ice40 $(COMMON_NEXTPNR_FLAGS) $(ICESTICK_NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@


# Generate final PCF file
$(PCF_DIR)/icestick-spi.pcf: $(SRC_DIR)/pcf/icestick-main.pcf $(SRC_DIR)/pcf/icestick-spi.pcf | $(PCF_DIR)
	cat $^ > $@

$(PCF_DIR)/icestick-uart.pcf: $(SRC_DIR)/pcf/icestick-main.pcf $(SRC_DIR)/pcf/icestick-uart.pcf | $(PCF_DIR)
	cat $^ > $@