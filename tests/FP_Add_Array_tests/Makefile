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
VHDL_SOURCES += $(PWD)/../../RTL/FP_Add.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/FP_Add_Array.vhd
VHDL_SOURCES += $(PWD)/../../RTL/Types.vhdl
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = fp_add_array

# MODULE is the basename of the Python test file
# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim