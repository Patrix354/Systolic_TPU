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
    # Reset procedure
    dut.i_rstn.value = 0
    
    for i in dut.i_a:
        i.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1
    await RisingEdge(dut.i_clk)

    # Example inupt numbers
    float_a = [1.5, 3, 2.5, 2, -2, -1, 5, -3.5, 2, -4, 1.25, 1, 2, -3, 1, 1]
    fixedp_a = [FixedPoint(i, m=in_M_bits, n=in_N_bits, signed=True) for i in float_a]
    int_a = [fp_op.fixed_to_int(i) for i in fixedp_a]   # Final list to send

    # Expected output
    float_y = 0
    for i in float_a:
        float_y = float_y + i
    fixedp_y = FixedPoint(float_y, m=in_M_bits, n=in_N_bits, signed=True)
    int_y = fp_op.fixed_to_int(fixedp_y)

    # Assign inputs
    for i in range(len(dut.i_a)):
        dut.i_a[i].value = int_a[i]

    # Wait for results
    for i in range(16):
        await RisingEdge(dut.i_clk)

    # Check output
    assert dut.o_y.value == int_y

    await RisingEdge(dut.i_clk)
    pass

@cocotb.test()
async def randomised_test(dut):
    # Reset Procedure
    dut.i_rstn.value = 0
    
    for i in dut.i_a:
        i.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1
    await RisingEdge(dut.i_clk)

    # Repeating N times test procedure
    for i in range(0, 100):
        in_a_long = []
        in_a_short = []

        # Generating vector of test valures
        for j in range(Input_size):
            rand_a = hex(random.getrandbits(in_bit_range_N + in_bit_range_M))
            in_a_short.append(FixedPoint(rand_a, m=in_bit_range_M, n=in_bit_range_N, signed=True))
            in_a_long.append(resize(in_a_short[-1], in_M_bits, in_N_bits))
            
        # Expected output
        fixedp_y = FixedPoint(0, m=in_M_bits, n=in_N_bits, signed=True)
        for i in in_a_long:
            fixedp_y = fp_op.fixed_add(fixedp_y, i)
            fixedp_y = resize(fixedp_y, in_M_bits, in_N_bits)
        int_y = fp_op.fixed_to_int(fixedp_y)

        # Assign inputs
        for i in range(len(dut.i_a)):
            dut.i_a[i].value = fp_op.fixed_to_int(in_a_long[i])

        # Wait for result
        for i in range(16):
            await RisingEdge(dut.i_clk)

        # Check output
        assert dut.o_y.value == int_y
    pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


