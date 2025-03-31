# This Makefile module includes rules for building the final binary for the Icestick FPGA

ICESTICK_REF_FREQ=12
ICESTICK_SYS_FREQ=$(shell cat $(SRC_DIR)/config.vh | grep '`define SYS_FREQ' | awk '{print $$3}')
ICESTICK_PLL_DEFINES=$(shell ./plldefines.sh $(ICESTICK_REF_FREQ) $(ICESTICK_SYS_FREQ))

ICESTICK_YOSYS_FLAGS=$(ICESTICK_PLL_DEFINES) -q -p
ICESTICK_YOSYS_CMD=synth_ice40 -relut

ICESTICK_NEXTPNR_FLAGS=--hx1k --package tq144 --freq $(ICESTICK_SYS_FREQ) --opt-timing

ICESTICK_ICEPACK_FLAGS=-s

ICESTICK_ICETIME_FLAGS=-d hx1k -P tq144 -c $(ICESTICK_SYS_FREQ) -t

# Build icestick binary
$(BIN_DIR)/icestick-spi.bin: $(PNR_DIR)/icestick-spi.asc $(RPT_DIR)/icestick-spi.rpt | $(BIN_DIR)
	icepack $(ICESTICK_ICEPACK_FLAGS) $< $@

$(BIN_DIR)/icestick-uart.bin: $(PNR_DIR)/icestick-uart.asc $(RPT_DIR)/icestick-uart.rpt | $(BIN_DIR)
	icepack $(ICESTICK_ICEPACK_FLAGS) $< $@


# Generate timing constraints report
$(RPT_DIR)/icestick-spi.rpt: $(PNR_DIR)/icestick-spi.asc $(PCF_DIR)/icestick-spi.pcf | $(RPT_DIR)
	icetime $(ICESTICK_ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<

$(RPT_DIR)/icestick-uart.rpt: $(PNR_DIR)/icestick-uart.asc $(PCF_DIR)/icestick-uart.pcf | $(RPT_DIR)
	icetime $(ICESTICK_ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<


# Place and route
$(PNR_DIR)/icestick-spi.asc: $(SYNTH_DIR)/icestick-spi.json $(PCF_DIR)/icestick-spi.pcf | $(PNR_DIR)
	nextpnr-ice40 $(ICESTICK_NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@

$(PNR_DIR)/icestick-uart.asc: $(SYNTH_DIR)/icestick-uart.json $(PCF_DIR)/icestick-uart.pcf | $(PNR_DIR)
	nextpnr-ice40 $(ICESTICK_NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@


# Generate final PCF file
$(PCF_DIR)/icestick-spi.pcf: $(SRC_DIR)/pcf/icestick-main.pcf $(SRC_DIR)/pcf/icestick-spi.pcf | $(PCF_DIR)
	cat $^ > $@

$(PCF_DIR)/icestick-uart.pcf: $(SRC_DIR)/pcf/icestick-main.pcf $(SRC_DIR)/pcf/icestick-uart.pcf | $(PCF_DIR)
	cat $^ > $@


# Synthetize verilog modules
$(SYNTH_DIR)/icestick-spi.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/config.vh $(SRC_DIR)/MitmLogic.v $(SRC_DIR)/buses/BusInterface.v \
		$(SRC_DIR)/buses/spi/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v  | $(SYNTH_DIR)
	yosys -DBUS_SPI $(ICESTICK_YOSYS_FLAGS) "$(ICESTICK_YOSYS_CMD) -top TopLevelModule -json $@" $< $$(echo $^ | cut -d ' ' -f 3-)

$(SYNTH_DIR)/icestick-uart.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/config.vh $(SRC_DIR)/MitmLogic.v $(SRC_DIR)/buses/BusInterface.v \
		$(SRC_DIR)/buses/uart/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v  | $(SYNTH_DIR)
	yosys -DBUS_UART $(ICESTICK_YOSYS_FLAGS) "$(ICESTICK_YOSYS_CMD) -top TopLevelModule -json $@" $< $$(echo $^ | cut -d ' ' -f 3-)