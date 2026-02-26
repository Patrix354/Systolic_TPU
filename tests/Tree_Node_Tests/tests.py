import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

from Tree_Node_tb import Tree_Node_tb
import random

@cocotb.test()
async def single_non_random_entry_test(dut):
    idealCaseQueue = asyncio.Queue()
    tb = Tree_Node_tb(dut, idealCaseQueue)

    input_vector = [dict(data=1, address=8, op=1, line=1, pause=3), dict(data=2, address=8, op=4, line=1, pause=3), dict(data=3, address=8, op=3, line=2, pause=3),
                    dict(data=2, address=16, op=4, line=2, pause=3), dict(data=4, address=16, op=2, line=1, pause=3), dict(data=6, address=16, op=3, line=1, pause=3), 
                    dict(data=4, address=32, op=1, line=1, pause=3), dict(data=8, address=32, op=2, line=1, pause=3), dict(data=12, address=32, op=3, line=1, pause=3)]

    for i in input_vector:
        await tb.driver.send(i)

    tb.start()

    await tb.driver.wait(500)

    #assert await tb.scoreboard.verify() == 0
    pass

# @cocotb.test()
# async def double_non_random_entry_test(dut):
#     idealCaseQueue = asyncio.Queue()
#     tb = MAC_Core_tb(dut, idealCaseQueue)

#     input_vector = [1.5, -1.5, 3, 3]
#     input_vector_fp = [fixedpoint.FixedPoint(i, m=in_N_bits, n=in_N_bits, signed=True) for i in input_vector]
#     input_vector_int = [fp_op.fixed_to_int(i) for i in input_vector_fp]
#     input_vector_mul = [input_vector[i]*input_vector[i+1] for i in range(0, len(input_vector), 2)]
#     input_sum = 0
#     for i in input_vector_mul:
#         input_sum = input_sum + i
#     input_sum_int = fp_op.fixed_to_int(fixedpoint.FixedPoint(input_sum, m=out_M_bits, n=out_N_bits, signed=True))

#     await idealCaseQueue.put(input_sum_int)
#     await tb.driver.send(input_vector_int)

#     input_vector = [1.5, -1.5, 3, 2]
#     input_vector_fp = [fixedpoint.FixedPoint(i, m=in_N_bits, n=in_N_bits, signed=True) for i in input_vector]
#     input_vector_int = [fp_op.fixed_to_int(i) for i in input_vector_fp]
#     input_vector_mul = [input_vector[i]*input_vector[i+1] for i in range(0, len(input_vector), 2)]
#     for i in input_vector_mul:
#         input_sum = input_sum + i
#     input_sum_int = fp_op.fixed_to_int(fixedpoint.FixedPoint(input_sum, m=out_M_bits, n=out_N_bits, signed=True))

#     await idealCaseQueue.put(input_sum_int)
#     await tb.driver.send(input_vector_int)

#     tb.start()

#     await tb.driver.wait(600)

#     assert await tb.scoreboard.verify() == 0

#     pass

@cocotb.test()
async def dummy_test(dut):
    pass


