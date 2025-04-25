# This Makefile module includes rules for building the final binary for the iCE40-HX8K breakout board FPGA

ICE40HX8K_NEXTPNR_FLAGS=--hx8k --package ct256

ICE40HX8K_ICETIME_FLAGS=-d hx8k -P ct256

# Build icestick binary
$(BIN_DIR)/ice40hx8k-spi.bin: $(PNR_DIR)/ice40hx8k-spi.asc $(RPT_DIR)/ice40hx8k-spi.rpt | $(BIN_DIR)
	icepack $(ICEPACK_FLAGS) $< $@

$(BIN_DIR)/ice40hx8k-uart.bin: $(PNR_DIR)/ice40hx8k-uart.asc $(RPT_DIR)/ice40hx8k-uart.rpt | $(BIN_DIR)
	icepack $(ICEPACK_FLAGS) $< $@


# Generate timing constraints report
$(RPT_DIR)/ice40hx8k-spi.rpt: $(PNR_DIR)/ice40hx8k-spi.asc $(PCF_DIR)/ice40hx8k-spi.pcf | $(RPT_DIR)
	icetime $(COMMON_ICETIME_FLAGS) $(ICE40HX8K_ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<

$(RPT_DIR)/ice40hx8k-uart.rpt: $(PNR_DIR)/ice40hx8k-uart.asc $(PCF_DIR)/ice40hx8k-uart.pcf | $(RPT_DIR)
	icetime $(COMMON_ICETIME_FLAGS) $(ICE40HX8K_ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<


# Place and route
$(PNR_DIR)/ice40hx8k-spi.asc: $(SYNTH_DIR)/synth-spi.json $(PCF_DIR)/ice40hx8k-spi.pcf | $(PNR_DIR)
	nextpnr-ice40 $(COMMON_NEXTPNR_FLAGS) $(ICE40HX8K_NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@

$(PNR_DIR)/ice40hx8k-uart.asc: $(SYNTH_DIR)/synth-uart.json $(PCF_DIR)/ice40hx8k-uart.pcf | $(PNR_DIR)
	nextpnr-ice40 $(COMMON_NEXTPNR_FLAGS) $(ICE40HX8K_NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@


# Generate final PCF file
$(PCF_DIR)/ice40hx8k-spi.pcf: $(SRC_DIR)/pcf/ice40hx8k-main.pcf $(SRC_DIR)/pcf/ice40hx8k-spi.pcf | $(PCF_DIR)
	cat $^ > $@

$(PCF_DIR)/ice40hx8k-uart.pcf: $(SRC_DIR)/pcf/ice40hx8k-main.pcf $(SRC_DIR)/pcf/ice40hx8k-uart.pcf | $(PCF_DIR)
	cat $^ > $@