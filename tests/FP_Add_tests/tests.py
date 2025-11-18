import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock

# Fixed point operations
import fp_op
from fixedpoint import *

# Random generator
import random

period_ns = 10
M_bits = 4
N_bits = 4

async def reset_seq(dut):
    dut.i_rstn.value = 0
    dut.i_a.value = 0
    dut.i_b.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1

    await RisingEdge(dut.i_clk)

async def test_two_numbers(dut, a_in, b_in):
    # Creating 2 fixedpoint numbers 
    a = FixedPoint(a_in, m=M_bits, n=N_bits, signed=True)
    b = FixedPoint(b_in, m=N_bits, n=N_bits, signed=True)
    a_fl = a.__float__()
    b_fl = b.__float__()
    # Counting sum and writing result as a fixed point
    c_fl = a_fl + b_fl
    c = FixedPoint(c_fl, m=N_bits, n=N_bits, signed=True)

    # Changing representation to an int (from binary representation of a fixed point number)
    iA = fp_op.fixed_to_int(a)
    iB = fp_op.fixed_to_int(b)
    iC = fp_op.fixed_to_int(c)

    # Assigning values
    dut.i_a.value = iA
    dut.i_b.value = iB

    for i in range(0,2):
        await RisingEdge(dut.i_clk)

    # Assertion
    assert dut.o_y.value == iC, (
        f"Addition isn't correct. a = {float(a)}, b = {float(b)}, c = {float(c)}"
    )

    await RisingEdge(dut.i_clk)

@cocotb.test()
async def pos_pos_result_pos(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, 2, 1.5)
    pass

@cocotb.test()
async def neg_pos_result_pos(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, -1.5, 1.5)
    pass

@cocotb.test()
async def neg_pos_result_neg(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, -2, 1.5)
    pass

@cocotb.test()
async def neg_neg_result_neg(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, -2, -1.5)
    pass

@cocotb.test()
async def randomised_test(dut):
    await reset_seq(dut)

    for i in range(0, 100):
        # Generating random bit sequence 
        # (2 bits shorter because module has equal sized inputs and output. Unused bits will be removed during synthesis)
        rand_a = hex(random.getrandbits(N_bits + M_bits - 2))
        rand_b = hex(random.getrandbits(N_bits + M_bits - 2))
        
        await test_two_numbers(dut, rand_a, rand_b)
    pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


