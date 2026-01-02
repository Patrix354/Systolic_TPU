import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

# Fixed point operations
import fp_op
import fixedpoint
from FP_Acc_tb import FP_Acc_tb
import random

period_ns = 10
in_M_bits = 8
in_N_bits = 8 

out_M_bits = 32
out_N_bits = 32

Input_size = 16

def cumsum_vect(input_vect):
    ret_vect = [input_vect[0]]
    for i in range(len(input_vect)):
        if i == 0:
            continue
        ret_vect.append(ret_vect[-1] + input_vect[i])
    return ret_vect

def float_to_int_fixedpoint_vector(input_vector, M_bits, N_bits):
    fixedpoint_input_vector = [fixedpoint.FixedPoint(i, m=M_bits, n=N_bits, signed=True) for i in input_vector]
    int_input_vector = [fp_op.fixed_to_int(i) for i in fixedpoint_input_vector]   # Final list to send
    return int_input_vector

async def chect_output(dut, output_vector, int_output_vector, input_vector):
    await RisingEdge(dut.o_ready)
    for i in range(len(input_vector)):
        await RisingEdge(dut.i_clk)
        assert dut.o_data.value == int_output_vector[i], (
        f"Error at iteration {i}, at value: {input_vector[i]}, expected output: {output_vector[i]}"
    )

@cocotb.test()
async def non_random_entry_test(dut):
    idealCaseQueue = asyncio.Queue()
    tb = FP_Acc_tb(dut, idealCaseQueue)

    # Example inupt numbers
    input_vector = [1.5, 3, 2.5, 2, -2, -1, 5, -3.5, 2, -4, 1.25, 1, 2, -3, 1, 1]
    int_input_vector = float_to_int_fixedpoint_vector(input_vector, in_M_bits, in_N_bits)

    # Expected output
    output_vector = cumsum_vect(input_vector)
    int_output_vector = float_to_int_fixedpoint_vector(output_vector, out_M_bits, out_N_bits)
    
    for i in int_output_vector:
        await idealCaseQueue.put(i)

    for i in int_input_vector:
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


