import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock

# Fixed point operations
import fp_op
from fixedpoint import *

# Random generator
import random

in_M_bits = 4
in_N_bits = 4
out_M_bits = 8
out_N_bits = 8

@cocotb.test()
async def non_random_entry_test(dut):
    a = FixedPoint(1.5, m=in_M_bits, n=in_N_bits, signed=True)
    y = resize(a, out_N_bits, out_M_bits)

    iA = fp_op.fixed_to_int(a)
    iY = fp_op.fixed_to_int(y)
  
    dut.i_data.value = 0
    await Timer(10, unit='ns')

    dut.i_data.value = iA
    await Timer(10, unit="ns")
    assert dut.o_data.value == iY

    pass

@cocotb.test()
async def randomised_test(dut):
    dut.i_data.value = 0
    await Timer(10, unit='ns')

    for i in range(0, 100):
        rand_a = hex(random.getrandbits(in_N_bits + in_M_bits))
        
        a = FixedPoint(rand_a, m=in_M_bits, n=in_N_bits, signed=True)
        y = resize(a, out_M_bits, out_N_bits)

        iA = fp_op.fixed_to_int(a)
        iY = fp_op.fixed_to_int(y)
        
        dut.i_data.value = iA
        await Timer(10, unit="ns")
        assert dut.o_data.value == iY
    pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


