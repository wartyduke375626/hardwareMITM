# This Makefile module includes rules for building files common for both icestick and ice40hx8k FPGAS

REF_FREQ=12
SYS_FREQ=$(shell cat $(SRC_DIR)/config.vh | grep '`define SYS_FREQ' | awk '{print $$3}')

YOSYS_FLAGS=-q -p
YOSYS_CMD=synth_ice40 -relut

COMMON_NEXTPNR_FLAGS=--freq $(SYS_FREQ) --opt-timing

ICEPACK_FLAGS=-s

COMMON_ICETIME_FLAGS=-c $(SYS_FREQ) -t

# Synthetize verilog modules
$(SYNTH_DIR)/synth-spi.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/config.vh $(MODULE_DIR)/Pll.v $(SRC_DIR)/MitmLogic.v \
		$(SRC_DIR)/buses/BusInterface.v $(SRC_DIR)/buses/spi/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v  | $(SYNTH_DIR)
	yosys -DBUS_SPI $(YOSYS_FLAGS) "$(YOSYS_CMD) -top TopLevelModule -json $@" $< $$(echo $^ | cut -d ' ' -f 3-)

$(SYNTH_DIR)/synth-uart.json: $(SRC_DIR)/TopLevelModule.v $(SRC_DIR)/config.vh $(MODULE_DIR)/Pll.v $(SRC_DIR)/MitmLogic.v \
		$(SRC_DIR)/buses/BusInterface.v $(SRC_DIR)/buses/uart/*.v $(SRC_DIR)/io/*.v $(SRC_DIR)/primitives/*.v  | $(SYNTH_DIR)
	yosys -DBUS_UART $(YOSYS_FLAGS) "$(YOSYS_CMD) -top TopLevelModule -json $@" $< $$(echo $^ | cut -d ' ' -f 3-)


# Generate PLL verilog module
$(MODULE_DIR)/Pll.v: $(SRC_DIR)/config.vh | $(MODULE_DIR)
	icepll -i $(REF_FREQ) -o $(SYS_FREQ) -n Pll -m > $@