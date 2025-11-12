import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.types import Array, LogicArray, Range
from cocotb.clock import Clock

# Fixed point operations
import fp_op
from fixedpoint import *

# Random generator
import random

period_ns = 10
in_bit_range_M = 4
in_bit_range_N = 4 

in_M_bits = 8
in_N_bits = 8

Input_size = 16

@cocotb.test()
async def non_random_entry_test(dut):
    dut.i_rstn.value = 0
    
    for child in dut.i_a:
        child.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1
    await RisingEdge(dut.i_clk)

    # Example inupt numbers
    float_a = [1.5, 3, 2.5, 2, -2, -1, 5, -3.5, 2, -4, 1.25, 1, 2, -3, 1, 1]
    fixedp_a = [FixedPoint(i, m=in_M_bits, n=in_N_bits, signed=True) for i in float_a]
    int_a = [fp_op.fixed_to_int(i) for i in fixedp_a]   # Final list to send


    # Expected output numbers
    float_y = 0
    for i in float_a:
        float_y = float_y + i
    fixedp_y = FixedPoint(float_y, m=in_M_bits, n=in_N_bits, signed=True)
    int_y = fp_op.fixed_to_int(fixedp_y)

    # Assign inputs
    for i in range(len(dut.i_a)):
        dut.i_a[i].value = int_a[i]

    for i in range(10):
        await RisingEdge(dut.i_clk)

    # Check output
    assert dut.o_y.value == int_y

    await RisingEdge(dut.i_clk)
    pass

@cocotb.test()
async def randomised_test(dut):

    pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


