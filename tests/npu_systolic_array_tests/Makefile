# Simulator to be used.
SIM ?= nvc
#EXTRA_ARGS += 

# VCD file output (Fully optional)
WAVE_NAME ?= npu_systolic_array.fst
SIM_ARGS += --dump-arrays=16
SIM_ARGS += --format=fst
SIM_ARGS += --wave=$(WAVE_NAME)

# Simulator language
TOPLEVEL_LANG ?= vhdl

# Add VHDL sources
# Add more sources by replicating the following lines. BE AWARE OF COMPILE ORDER!

VHDL_SOURCES += $(PWD)/../../RTL/npu_types.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_config.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_add.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_mul.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_pe.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_delay.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_systolic_array_delay.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/npu_systolic_array.vhdl

VHDL_SOURCES += $(PWD)/../../wrappers/npu_systolic_array_wrapper.vhdl

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = npu_systolic_array_wrapper

# MODULE is the basename of the Python test file
# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
