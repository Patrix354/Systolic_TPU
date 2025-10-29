# Simulator to be used.
VCD_NAME ?= fp_mul_tests.vcd
SIM ?= ghdl
#EXTRA_ARGS += 
SIM_ARGS += --vcd=$(VCD_NAME)
SIM_ARGS += -gINTEGER_PART=4
SIM_ARGS += -gFRACTIONAL_PART=4

TOPLEVEL_LANG ?= vhdl

# Add VHDL sources
# Add more sources by replicating the following lines.
VHDL_SOURCES += $(PWD)/../../RTL/FP_Mul.vhdl

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = fp_mul

# MODULE is the basename of the Python test file
# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim