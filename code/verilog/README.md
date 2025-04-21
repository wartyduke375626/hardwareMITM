# Verilog directory

This directory contains all Verilog source files for building the FPGA configuration, test benches and other related files.

## Directory structure:

* **src/** - Verilog source files (including configuration)

* **tests/** - test benches

* **examples/** - MITM logic examples

* all script generated files will be placed in the **build/** directory

## How to build the FPGA MITM logic:

**Disclaimer:** _This project is an early proof of concept. Some parts of the automated build may not be well-tuned or optimally implemented. The sole purpose of this project is to demonstrate feasibility, not to serve as a production-ready solution._

1. Implement a MITM logic utilizing the bus interface. Two examples of MITM logic modules are provided in **examples/**. The module has to be named MitmLogic. Copy the MITM logic implementation to **src/MitmLogic.v**.

2. Configure parameters according to the MITM logic by editing **src/config.vh**.

3. If you need to change your PCF configuration you can edit the port assignments in **src/pcf/**. There are multiple PCF files for each board (Icestick Evaluation Kit and iCE40-HX8K Breakout Board). These files will be used to auto-generate the final PCF configuration based on the selected board and bus when running the build script.

4. Optionally, you can implement a test bench for your MITM logic in **tests/**, create a build rule for it in **test.mk** and add the target to the _make sim_ prerequisites in **Makefile**. Your test can then be run with all other tests with _make sim_, vcd files are generated in **build/simulations/**.

5. To build the final FPGA bitstream. Run _make board-bus_ (e.g. _make icestick-uart_ or _make ice40hx8k-spi_.) The script will generate the final bitstream in **build/bin/**.

6. Finally, you can upload the bitstream to the FPGA board using iceprog.