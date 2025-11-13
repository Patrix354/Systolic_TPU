# Simulator to be used.
SIM ?= nvc
#EXTRA_ARGS += 

# Additional simulator args
# Design parameters
SIM_ARGS += -gINTEGER_PART=4
SIM_ARGS += -gFRACTIONAL_PART=4

# VCD file output (Fully optional)
VCD_NAME ?= mac_cell_tests.vcd
SIM_ARGS += --format=vcd
SIM_ARGS += --wave=$(VCD_NAME)

# Simulator language
TOPLEVEL_LANG ?= vhdl

# Add VHDL sources
# Add more sources by replicating the following lines. BE AWARE OF COMPILE ORDER!
VHDL_SOURCES += $(PWD)/../../RTL/Types.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/MAC_Cell.vhdl
# Add verilog sources
# Add more sources by replicating the following lines. BE AWARE OF COMPILE ORDER!
#VERILOG_SOURCES += $(PWD)/../../RTL/FP_Add.v
#VERILOG_SOURCES += $(PWD)/../../RTL/FP_Add_Layer.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = mac_cell

# MODULE is the basename of the Python test file
# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
