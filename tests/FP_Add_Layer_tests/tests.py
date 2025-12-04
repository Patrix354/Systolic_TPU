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

async def reset_seq(dut):
    dut.i_rstn.value = 0
    
    for child in dut.i_a:
        child.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1
    await RisingEdge(dut.i_clk)

@cocotb.test()
async def non_random_entry_test(dut):
    await reset_seq(dut)

    # Example inupt numbers
    float_a = [1.5, 3, 2.5, 2, -2, -1, 5, -3.5, 2, -4, 1.25, 1, 2, -3, 1, 1]
    fixedp_a = [FixedPoint(i, m=in_M_bits, n=in_N_bits, signed=True) for i in float_a]
    int_a = [fp_op.fixed_to_int(i) for i in fixedp_a]   # Final list to send


    # Expected output numbers
    float_y = []
    for i in range(0, len(float_a), 2):
        float_y.append(float_a[i] + float_a[i+1])
    fixedp_y = [FixedPoint(i, m=in_M_bits, n=in_N_bits, signed=True) for i in float_y]
    int_y = [fp_op.fixed_to_int(i) for i in fixedp_y]   # Expected list

    # Assign inputs
    for i in range(len(dut.i_a)):
        dut.i_a[i].value = int_a[i]

    for i in range(2):
        await RisingEdge(dut.i_clk)

    # Check output
    for i in range(len(dut.o_y)):
        assert dut.o_y[i].value == int_y[i]

    await RisingEdge(dut.i_clk)
    pass

@cocotb.test()
async def randomised_test(dut):
    await reset_seq(dut)

    for i in range(0, 100):
        in_a_long = []
        in_a_short = []

        for j in range(Input_size):
            rand_a = hex(random.getrandbits(in_bit_range_N + in_bit_range_M))
            in_a_short.append(FixedPoint(rand_a, m=in_bit_range_M, n=in_bit_range_N, signed=True))
            in_a_long.append(resize(in_a_short[-1], in_M_bits, in_N_bits))
            
        # Expected output numbers
        float_y = []
        for i in range(0, Input_size, 2):
            float_y.append(in_a_long[i].__float__() + in_a_long[i+1].__float__())

        fixedp_y = [FixedPoint(i, m=in_M_bits, n=in_N_bits, signed=True) for i in float_y]
        int_y = [fp_op.fixed_to_int(i) for i in fixedp_y]   # Expected list

        # Assign inputs
        for i in range(len(dut.i_a)):
            dut.i_a[i].value = fp_op.fixed_to_int(in_a_long[i])

        for i in range(2):
            await RisingEdge(dut.i_clk)

        # Check output
        for i in range(len(dut.o_y)):
            assert dut.o_y[i].value == int_y[i]

        await RisingEdge(dut.i_clk)
    pass    

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


