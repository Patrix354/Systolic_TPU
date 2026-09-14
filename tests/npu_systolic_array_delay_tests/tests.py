import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

from QFormat import QFormat, FixedQ
from npu_systolic_array_delay_tb import npu_systolic_array_delay_tb
import random

period_ns = 10
M_bits = 4
N_bits = 4
array_size = 3

@cocotb.test()
async def input_delay_test(dut):
    fmt = QFormat(N_bits, M_bits)
    idealCaseQueue = asyncio.Queue()
    tb = npu_systolic_array_delay_tb(dut, idealCaseQueue)


    #output_vector = [fmt.from_raw(random.getrandbits(N_bits + M_bits)).uraw() for i in range(100)]
    input_vector = [[1.5, 4.25, 5.125],
                    [1.25, 4.125, 5.5],
                    [1.125, 4.5, 5.25]]
    
    en_input_vector = [[1, 1, 1],
                       [1, 1, 1],
                       [1, 1, 1]]
    
    qfmt_input_vector = []
    for i in range(3):
        qfmt_input_vector.append([fmt.from_float(j).uraw() for j in input_vector[i]])
    # for i in output_vector:
    #     await idealCaseQueue.put(i)

    for i in range(len(qfmt_input_vector)):
        await tb.driver.send([qfmt_input_vector[i], en_input_vector[i]])
        
    tb.start()
    await tb.driver.wait(1000)
   # assert await tb.scoreboard.verify() == 0

    pass


@cocotb.test()
async def output_delay_test(dut):
    fmt = QFormat(N_bits, M_bits)
    idealCaseQueue = asyncio.Queue()
    tb = npu_systolic_array_delay_tb(dut, idealCaseQueue)


    #output_vector = [fmt.from_raw(random.getrandbits(N_bits + M_bits)).uraw() for i in range(100)]
    input_vector = [[0    , 0    , 5.125],
                    [0    , 4.25 , 5.5],
                    [1.5  , 4.125, 5.25],
                    [1.25 , 4.5  , 0],
                    [1.125, 0    , 0]]

    en_input_vector = [[0, 0, 1],
                       [0, 1, 1],
                       [1, 1, 1],
                       [1, 1, 0],
                       [1, 0, 0]]
    
    qfmt_input_vector = []
    for i in range(5):
        qfmt_input_vector.append([fmt.from_float(j).uraw() for j in input_vector[i]])
    # for i in output_vector:
    #     await idealCaseQueue.put(i)

    for i in range(len(qfmt_input_vector)):
        await tb.driver.send([qfmt_input_vector[i], en_input_vector[i]])
        
    tb.start()
    await tb.driver.wait(1000)
   # assert await tb.scoreboard.verify() == 0

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


