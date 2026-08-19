import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

from QFormat import QFormat, FixedQ
from npu_pe_tb import npu_pe_tb
import random

period_ns = 10
M_bits = 4
N_bits = 4

'''
Do drivera podawane są dane w formacie [dana_x, dana_y, waga, sygnał_valid_dla_wagi, sygnał_valid]
'''

def float_to_qfmt_vector(input_vector, fmt):
    ret = [fmt.from_float(i).uraw() for i in input_vector]
    return ret

def load_weight(input_vectors, weight, fmt):
    input_vectors.append([0, 0, 0, 0, 0])
    input_vectors.append([0, 0, fmt.from_float(weight).uraw(), 1, 0])
    input_vectors.append([0, 0, 0, 0, 0])

def put_data(input_vectors, x, y, fmt):
    input_vectors.append([fmt.from_float(x).uraw(), fmt.from_float(y).uraw(), 0, 0, 1])

def clear_all_inputs(input_vectors):
    input_vectors.append([0, 0, 0, 0, 0])

@cocotb.test()
async def non_random_entry_test(dut):
    fmt = QFormat(N_bits, M_bits)
    x_idealCaseQueue = asyncio.Queue()
    y_idealCaseQueue = asyncio.Queue()
    tb = npu_pe_tb(dut, x_idealCaseQueue, y_idealCaseQueue)

    # Example inupt numbers
    input_vectors = []

    clear_all_inputs(input_vectors)
    load_weight(input_vectors, 0.5, fmt=fmt)
    put_data(input_vectors, 0.5, 1, fmt=fmt)
    put_data(input_vectors, 0.5, 2, fmt=fmt)
    put_data(input_vectors, 0.25, 1, fmt=fmt)
    clear_all_inputs(input_vectors)

    # Expected output
    output_x_vector = [0.5, 0.5, 0.25]
    output_y_vector = [1.25, 2.25, 1.125]
    qfmt_output_x_vector = float_to_qfmt_vector(output_x_vector, fmt)
    qfmt_output_y_vector = float_to_qfmt_vector(output_y_vector, fmt)
    
    for i in qfmt_output_x_vector:
        await x_idealCaseQueue.put(i)

    for i in qfmt_output_y_vector:
        await y_idealCaseQueue.put(i)

    for i in input_vectors:
        await tb.driver.send(i)
        
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


