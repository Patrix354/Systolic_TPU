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
M_bits = 8
N_bits = 8
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
    float_a = [1.5, 3, 2.5, 6, -2, -1, 5, -3.5, 9, -4, 1.25, 1, 2, -3, 1, 1]
    fixedp_a = [FixedPoint(i, m=M_bits, n=N_bits, signed=True) for i in float_a]
    int_a = [fp_op.fixed_to_int(i) for i in fixedp_a]


    # Expected output numbers
    float_y = []
    for i in range(0, len(float_a), 2):
        float_y.append(float_a[i] + float_a[i+1])
    fixedp_y = [FixedPoint(i, m=M_bits, n=N_bits, signed=True) for i in float_y]
    int_y = [fp_op.fixed_to_int(i) for i in fixedp_y]

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

# @cocotb.test()
# async def randomised_test(dut):
#     dut.i_rstn.value = 0
#     dut.i_a.value = 0
#     dut.i_b.value = 0

#     Clock(dut.i_clk, period_ns, unit='ns').start()
#     for i in range(0, 2):
#         await RisingEdge(dut.i_clk)

#     dut.i_rstn.value = 1

#     await RisingEdge(dut.i_clk)

#     for i in range(0, 100):
#         rand_a = hex(random.getrandbits(N_bits + M_bits))
#         rand_b = hex(random.getrandbits(N_bits + M_bits))
        
#         a = FixedPoint(rand_a, m=M_bits, n=N_bits, signed=True)
#         b = FixedPoint(rand_b, m=M_bits, n=N_bits, signed=True)
#         c = fp_op.fixed_add(a, b)

#         iA = fp_op.fixed_to_int(a)
#         iB = fp_op.fixed_to_int(b)
#         iC = fp_op.fixed_to_int(c)

#         dut.i_a.value = iA
#         dut.i_b.value = iB

#         for j in range(0,2):
#             await RisingEdge(dut.i_clk)

#         assert dut.o_y.value == iC, (
#             f'''Addition isn't correct. a = {float(a)}, b = {float(b)},
#              c = {float(c)}. Iteration {i}"'''
#         )
#     pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


