## Directory structure

* **src/** contains Verilog source code of all modules and PCF files for different FPGAs

* **test/** contains simulation test benches written in System Verilog for all modules in *src/*

* **docs/** contains various documentation files (module diagrams, etc.)

## Required tools

* TODO

## How to build

- make simulate will generate simulation files (.vcd) for all tests (output in *sim/* directory)

- make bin will build binary files for all FPGAs

* make rpt will generate timing constraint report files (output in *report/* directory)
