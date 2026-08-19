# Simulator to be used.
SIM ?= nvc
#EXTRA_ARGS += 

# VCD file output (Fully optional)
WAVE_NAME ?= npu_mul.fst
SIM_ARGS += --dump-arrays=16
SIM_ARGS += --format=fst
SIM_ARGS += --wave=$(WAVE_NAME)

# Simulator language
TOPLEVEL_LANG ?= vhdl

# Add VHDL sources
# Add more sources by replicating the following lines. BE AWARE OF COMPILE ORDER!
VHDL_SOURCES += $(PWD)/../../RTL/npu_types.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_config.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_mul.vhdl

VHDL_SOURCES += $(PWD)/../../wrappers/npu_mul_wrapper.vhdl

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = npu_mul_wrapper

# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
