# Simulator to be used.
SIM ?= nvc

# VCD file output (Fully optional)
VCD_NAME ?= npu_add.vcd
SIM_ARGS += --format=vcd
SIM_ARGS += --wave=$(VCD_NAME)

# Simulator language
TOPLEVEL_LANG ?= vhdl

# Add VHDL sources
# Add more sources by replicating the following lines. BE AWARE OF COMPILE ORDER!
VHDL_SOURCES += $(PWD)/../../RTL/npu_types.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_config.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_add.vhdl

VHDL_SOURCES += $(PWD)/../../wrappers/npu_add_wrapper.vhdl

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = npu_add_wrapper

# MODULE is the basename of the Python test file
# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
