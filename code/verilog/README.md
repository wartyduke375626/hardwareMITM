# Verilog Directory

This directory contains all Verilog source files for building the FPGA configuration, test benches and other related files.

## Directory structure:

* **src/** - Verilog source files (including configuration)

* **tests/** - test benches

* **examples/** - MITM logic examples

* all script-generated files will be placed in the **build/** directory

## Dependencies:

In order to use the automated build script, the following dependencies are required:

* **yosys** - https://github.com/YosysHQ/yosys

* **nextpnr** - https://github.com/YosysHQ/nextpnr (only _nextpnr-ice40_ is required)

* **Project IceStorm** - https://github.com/YosysHQ/icestorm (specifically _icepack_, _iceprog_, _icetime_, _icepll_)

* **ICARUS Verilog** - https://github.com/steveicarus/iverilog (for test benches only, not required to build the final bitstream)

Additionally, a tool like **GTKWave** can be used to graphically display simulated vcd files (https://github.com/gtkwave/gtkwave).

On Linux you can install the following packages (e.g. using _apt_):

`apt install yosys nextpnr-ice40 fpga-icestorm iverilog gtkwave`

## How to build the FPGA MITM logic:

**Disclaimer:** _This project is an early proof of concept. Some parts of the automated build may not be well-tuned or optimally implemented. The sole purpose of this project is to demonstrate feasibility, not to serve as a production-ready solution._

1. Implement a MITM logic utilizing the bus interface. Two examples of MITM logic modules are provided in **examples/**. The module has to be named `MitmLogic`. Copy the MITM logic implementation to **src/MitmLogic.v**.

2. Configure parameters according to the MITM logic by editing **src/config.vh**.

3. If you need to change your PCF configuration, you can edit the port assignments in **src/pcf/**. There are multiple PCF files for each board (Icestick Evaluation Kit and iCE40-HX8K Breakout Board). These files will be used to auto-generate the final PCF configuration based on the selected board and bus when running the build script.

4. Optionally, you can implement a test bench for your MITM logic in **tests/**, create a build rule for it in **test.mk** and add the target to the `make sim` prerequisites in **Makefile**. Your test can then be run with all other tests with `make sim`, vcd files are generated in **build/simulations/**.

5. To build the final FPGA bitstream, run `make <board>-<bus>` (e.g. `make icestick-uart` or `make ice40hx8k-spi`). The script will generate the final bitstream in **build/bin/**.

6. Finally, you can upload the bitstream to the FPGA board using **iceprog** (e.g. `iceprog build/bin/icestick-uart.bin`). On Linux, it should work straightforwardly. On Windows, for **iceprog** to work you need to install the **libusbK** driver on both the USB serial interfaces of the FPGA board, e.g. using **Zadig** (https://github.com/pbatard/libwdi/wiki/Zadig).

## Known problems:

* On Ubuntu 22.04.5 releases, _fpga-icestorm_ package provided via apt, the **icetime** utility does not correctly parse the generated PCF files. (error: _icetime: icetime.cc:232: void read_pcf(const char*): Assertion `args.size() == 2' failed_). As this utility is only used to verify timing constraints it is not required to properly compile the code. As a quick workaround, comment out the lines involving 'icetime' from icestick.mk and ice40hx8k.mk (e.g. #icetime $(COMMON_ICETIME_FLAGS) $(ICESTICK_ICETIME_FLAGS) -p $$(echo $^ | cut -d ' ' -f 2) -r $@ $<).
