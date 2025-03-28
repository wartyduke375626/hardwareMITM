# This Makefile module includes rules for building the final binary for the iCE40-HX8K breakout board FPGA

REF_FREQ=12
SYS_FREQ=$(shell cat $(SRC_DIR)/config.vh | grep '`define SYS_FREQ' | awk '{print $$3}')
PLL_DEFINES=$(shell ./plldefines.sh $(REF_FREQ) $(SYS_FREQ))

YOSYS_FLAGS=$(PLL_DEFINES) -q -p
YOSYS_CMD=synth_ice40 -relut

NEXTPNR_FLAGS=--hx8k --package ct256 --freq $(SYS_FREQ) --opt-timing

ICEPACK_FLAGS=-s

ICETIME_FLAGS=-d hx8k -P ct256 -c $(SYS_FREQ) -t

# Build icestick binary
$(BIN_DIR)/ice40hx8k-spi.bin: $(PNR_DIR)/ice40hx8k-spi.asc $(RPT_DIR)/ice40hx8k-spi.rpt | $(BIN_DIR)
	icepack $(ICEPACK_FLAGS) $< $@

$(BIN_DIR)/ice40hx8k-uart.bin: $(PNR_DIR)/ice40hx8k-uart.asc $(RPT_DIR)/ice40hx8k-uart.rpt | $(BIN_DIR)
	icepack $(ICEPACK_FLAGS) $< $@


# Generate timing constraints report
$(RPT_DIR)/ice40hx8k-spi.rpt: $(PNR_DIR)/ice40hx8k-spi.asc $(PCF_DIR)/ice40hx8k-spi.pcf | $(RPT_DIR)
	icetime $(ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<

$(RPT_DIR)/ice40hx8k-uart.rpt: $(PNR_DIR)/ice40hx8k-uart.asc $(PCF_DIR)/ice40hx8k-uart.pcf | $(RPT_DIR)
	icetime $(ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<


# Place and route
$(PNR_DIR)/ice40hx8k-spi.asc: $(SYNTH_DIR)/ice40hx8k-spi.json $(PCF_DIR)/ice40hx8k-spi.pcf | $(PNR_DIR)
	nextpnr-ice40 $(NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@

$(PNR_DIR)/ice40hx8k-uart.asc: $(SYNTH_DIR)/ice40hx8k-uart.json $(PCF_DIR)/ice40hx8k-uart.pcf | $(PNR_DIR)
	nextpnr-ice40 $(NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@


# Generate final PCF file
$(PCF_DIR)/ice40hx8k-spi.pcf: $(SRC_DIR)/pcf/ice40hx8k-main.pcf $(SRC_DIR)/pcf/ice40hx8k-spi.pcf | $(PCF_DIR)
	cat $^ > $@

$(PCF_DIR)/ice40hx8k-uart.pcf: $(SRC_DIR)/pcf/ice40hx8k-main.pcf $(SRC_DIR)/pcf/ice40hx8k-uart.pcf | $(PCF_DIR)
	cat $^ > $@


# Synthetize verilog modules
$(SYNTH_DIR)/ice40hx8k-spi.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/config.vh $(SRC_DIR)/MitmLogic.v $(SRC_DIR)/buses/BusInterface.v \
		$(SRC_DIR)/buses/spi/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v  | $(SYNTH_DIR)
	yosys -DBUS_SPI $(YOSYS_FLAGS) "$(YOSYS_CMD) -top TopLevelModule -json $@" $< $$(echo $^ | cut -d ' ' -f 3-)

$(SYNTH_DIR)/ice40hx8k-uart.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/config.vh $(SRC_DIR)/MitmLogic.v $(SRC_DIR)/buses/BusInterface.v \
		$(SRC_DIR)/buses/uart/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v  | $(SYNTH_DIR)
	yosys -DBUS_UART $(YOSYS_FLAGS) "$(YOSYS_CMD) -top TopLevelModule -json $@" $< $$(echo $^ | cut -d ' ' -f 3-)