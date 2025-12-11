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

@cocotb.test()
async def non_random_entry_test(dut):
    dut.i_rstn.value = 0
    dut.i_a.value = 0
    dut.i_b.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1
    dut.i_valid.value = 0

    await RisingEdge(dut.i_clk)

    a = FixedPoint(1.5, m=M_bits, n=N_bits, signed=True)
    b = FixedPoint(-1.5, m=N_bits, n=N_bits, signed=True)
    c = fp_op.fixed_mul(a, b)

    iA = fp_op.fixed_to_int(a)
    iB = fp_op.fixed_to_int(b)
    iC = fp_op.fixed_to_int(c)

    dut.i_a.value = iA
    dut.i_b.value = iB

    dut.i_valid.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0
    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    assert dut.o_y.value == iC, (
        f"Multiplication isn't correct. a = {float(a)}, b = {float(b)}, c = {float(c)}"
    )


    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)
    pass

@cocotb.test()
async def randomised_test(dut):
    dut.i_rstn.value = 0
    dut.i_a.value = 0
    dut.i_b.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1

    await RisingEdge(dut.i_clk)

    for i in range(0, 10):
        rand_a = hex(random.getrandbits(N_bits + M_bits))
        rand_b = hex(random.getrandbits(N_bits + M_bits))
        
        a = FixedPoint(rand_a, m=M_bits, n=N_bits, signed=True)
        b = FixedPoint(rand_b, m=M_bits, n=N_bits, signed=True)
        c = fp_op.fixed_mul(a, b)

        iA = fp_op.fixed_to_int(a)
        iB = fp_op.fixed_to_int(b)
        iC = fp_op.fixed_to_int(c)

        dut.i_a.value = iA
        dut.i_b.value = iB
        dut.i_valid.value = 1
        await RisingEdge(dut.i_clk)
        dut.i_valid.value = 0
        await RisingEdge(dut.i_clk)
        await RisingEdge(dut.i_clk)

        assert dut.o_y.value == iC, (
            f'''Multiplication isn't correct. a = {float(a)}, b = {float(b)},
             c = {float(c)}. Iteration {i}"'''
        )
        await RisingEdge(dut.i_clk)
        await RisingEdge(dut.i_clk)
    pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


