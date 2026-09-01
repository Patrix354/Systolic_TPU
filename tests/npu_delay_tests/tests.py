import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

from QFormat import QFormat, FixedQ
from npu_delay_tb import npu_delay_tb
import random

period_ns = 10
M_bits = 4
N_bits = 4


@cocotb.test()
async def random_entry_test(dut):
    fmt = QFormat(N_bits, M_bits)
    idealCaseQueue = asyncio.Queue()
    tb = npu_delay_tb(dut, idealCaseQueue)

    output_vector = [fmt.from_raw(random.getrandbits(N_bits + M_bits)).uraw() for i in range(100)]
    input_vector = output_vector.copy()
    
    for i in output_vector:
        await idealCaseQueue.put(i)

    for i in input_vector:
        await tb.driver.send(i)
    print(len(input_vector))
        
    tb.start()
    await tb.driver.wait(1000)
    assert await tb.scoreboard.verify() == 0

    pass


# @cocotb.test()
# async def randomised_test(dut):
#     # Reset Procedure
#     dut.i_rstn.value = 0
    
#     for i in dut.i_a:
#         i.value = 0

#     Clock(dut.i_clk, period_ns, unit='ns').start()
#     for i in range(0, 2):
#         await RisingEdge(dut.i_clk)

#     dut.i_rstn.value = 1
#     await RisingEdge(dut.i_clk)

#     # Repeating N times test procedure
#     for i in range(0, 100):
#         in_a_long = []
#         in_a_short = []

#         # Generating vector of test valures
#         for j in range(Input_size):
#             rand_a = hex(random.getrandbits(in_bit_range_N + in_bit_range_M))
#             in_a_short.append(FixedPoint(rand_a, m=in_bit_range_M, n=in_bit_range_N, signed=True))
#             in_a_long.append(resize(in_a_short[-1], in_M_bits, in_N_bits))
            
#         # Expected output
#         cumsum_fixedpoint_output_vector = FixedPoint(0, m=in_M_bits, n=in_N_bits, signed=True)
#         for i in in_a_long:
#             cumsum_fixedpoint_output_vector = fp_op.fixed_add(cumsum_fixedpoint_output_vector, i)
#             cumsum_fixedpoint_output_vector = resize(cumsum_fixedpoint_output_vector, in_M_bits, in_N_bits)
#         cumsum_int_output_vector = fp_op.fixed_to_int(cumsum_fixedpoint_output_vector)

#         # Assign inputs
#         for i in range(len(dut.i_a)):
#             dut.i_a[i].value = fp_op.fixed_to_int(in_a_long[i])

#         # Wait for result
#         for i in range(5):
#             await RisingEdge(dut.i_clk)

#         # Check output
#         assert dut.o_y.value == cumsum_int_output_vector
#     pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


