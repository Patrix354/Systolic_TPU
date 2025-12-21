import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

# Fixed point operations
import fp_op
import fixedpoint
from MAC_Core_tb import MAC_Core_tb
import random

period_ns = 10
in_M_bits = 4
in_N_bits = 4
out_M_bits = 16
out_N_bits = 16

@cocotb.test()
async def non_random_entry_test(dut):
    idealCaseQueue = asyncio.Queue()
    tb = MAC_Core_tb(dut, idealCaseQueue)

    input_vector = [1.5, -1.5, 3, 1.5]
    input_vector_fp = [fixedpoint.FixedPoint(i, m=in_N_bits, n=in_N_bits, signed=True) for i in input_vector]
    input_vector_int = [fp_op.fixed_to_int(i) for i in input_vector_fp]
    input_vector_mul = [input_vector[i]*input_vector[i+1] for i in range(0, len(input_vector), 2)]
    input_sum = 0
    for i in input_vector_mul:
        input_sum = input_sum + i
    input_sum_int = fp_op.fixed_to_int(fixedpoint.FixedPoint(input_sum, m=out_M_bits, n=out_N_bits, signed=True))

    await idealCaseQueue.put(input_sum_int)
    await tb.driver.send(input_vector_int)

    tb.start()

    await tb.driver.wait(20)

    assert await tb.scoreboard.verify() == 0

    pass

@cocotb.test()
async def dummy_test(dut):
    pass


