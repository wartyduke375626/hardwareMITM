# This Makefile module includes rules for building the final binary for the icestick FPGA

REF_FREQ=12
SYS_FREQ=48
PLL_DEFINES=$(shell ./plldefines.sh $(REF_FREQ) $(SYS_FREQ))

YOSYS_FLAGS=$(PLL_DEFINES) -q -p
YOSYS_CMD=synth_ice40 -relut

NEXTPNR_FLAGS=--hx1k --package tq144 --freq $(SYS_FREQ) --opt-timing

ICEPACK_FLAGS=-s

ICETIME_FLAGS=-d hx1k -P tq144 -c $(SYS_FREQ) -t

test:
	echo $(PLL_DEFINES)

# Build icestick binary
$(BIN_DIR)/icestick-uart.bin: $(PNR_DIR)/icestick-uart.asc $(RPT_DIR)/icestick-uart.rpt | $(BIN_DIR)
	icepack $(ICEPACK_FLAGS) $< $@


# Generate timing constraints report
$(RPT_DIR)/icestick-uart.rpt: $(PNR_DIR)/icestick-uart.asc $(PCF_DIR)/icestick-uart.pcf | $(RPT_DIR)
	icetime $(ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<


# Place and route
$(PNR_DIR)/icestick-uart.asc: $(SYNTH_DIR)/icestick-uart.json $(PCF_DIR)/icestick-uart.pcf | $(PNR_DIR)
	nextpnr-ice40 $(NEXTPNR_FLAGS) --json $< --pcf $$(echo $^ | cut -d ' ' -f 2) --asc $@


# Generate final PCF file
$(PCF_DIR)/icestick-uart.pcf: $(SRC_DIR)/pcf/icestick-main.pcf $(SRC_DIR)/pcf/icestick-uart.pcf | $(PCF_DIR)
	cat $^ > $@


# Synthetize verilog modules
$(SYNTH_DIR)/icestick-uart.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/config.vh $(SRC_DIR)/MitmLogic.v $(SRC_DIR)/buses/BusInterface.v \
		$(SRC_DIR)/buses/uart/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v  | $(SYNTH_DIR)
	yosys -DBUS_UART $(YOSYS_FLAGS) "$(YOSYS_CMD) -top TopLevelModule -json $@" $< $$(echo $^ | cut -d ' ' -f 3-)