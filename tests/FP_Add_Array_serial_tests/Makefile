# Simulator to be used.
SIM ?= nvc
#EXTRA_ARGS += 

# Additional simulator args
# Design parameters
SIM_ARGS += -gINTEGER_PART=8
SIM_ARGS += -gFRACTIONAL_PART=8
SIM_ARGS += -gINPUT_SIZE=16

# VCD file output (Fully optional)
#VCD_NAME ?= fp_add_layer_tests.vcd
SIM_ARGS += --format=vcd
SIM_ARGS += --wave=$(VCD_NAME)

# Simulator language
TOPLEVEL_LANG ?= vhdl

# Add VHDL sources
# Add more sources by replicating the following lines. BE AWARE OF COMPILE ORDER!

VHDL_SOURCES += $(PWD)/../../RTL/Types.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/FP_Add.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/FP_Add_Layer.vhdl
VHDL_SOURCES += $(PWD)/../../RTL/FP_Add_Array.vhdl
VHDL_SOURCES += $(PWD)/../../wrappers/FP_Add_Array_serial_wrap.vhdl


# Add verilog sources
# Add more sources by replicating the following lines. BE AWARE OF COMPILE ORDER!
#VERILOG_SOURCES += $(PWD)/../../RTL/FP_Add.v
#VERILOG_SOURCES += $(PWD)/../../RTL/FP_Add_Layer.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = FP_Add_Array_serial_wrap

# MODULE is the basename of the Python test file
# Corresponds the filename of the python file
COCOTB_TEST_MODULES = tests

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
