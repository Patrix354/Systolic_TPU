# Simulator to be used.
VCD_NAME ?= mac_cell_tests.vcd
SIM ?= ghdl
#EXTRA_ARGS += 
SIM_ARGS=--vcd=$(VCD_NAME)

TOPLEVEL_LANG ?= vhdl

# Add VHDL Sources
VHDL_SOURCES += $(PWD)/../../RTL/MAC_Cell.vhdl

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = mac_cell

# MODULE is the basename of the Python test file
# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
