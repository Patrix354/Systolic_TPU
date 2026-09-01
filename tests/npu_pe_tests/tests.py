import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

from QFormat import QFormat, FixedQ
from npu_pe_tb import npu_pe_tb
import random

period_ns = 10
M_bits = 8
N_bits = 8  
fmt = QFormat(N_bits, M_bits)

random_test_batch_size = 5
'''
Do drivera podawane są dane w formacie [dana_x, dana_y, waga, sygnał_valid_dla_wagi, sygnał_valid]
'''
def load_weight(input_vectors, weight):
    input_vectors.append([0, 0, 0, 0, 0])
    input_vectors.append([0, 0, weight, 1, 0])
    input_vectors.append([0, 0, 0, 0, 0])

def put_data(input_vectors, x, y):
    input_vectors.append([x, y, 0, 0, 1])

def clear_all_inputs(input_vectors):
    input_vectors.append([0, 0, 0, 0, 0])


@cocotb.test()
async def unit_weight_random_xy_data_test(dut):
    x_idealCaseQueue = asyncio.Queue()
    y_idealCaseQueue = asyncio.Queue()
    tb = npu_pe_tb(dut, x_idealCaseQueue, y_idealCaseQueue, m_bits=M_bits, n_bits=N_bits)

    # List with entries representing inputs to the dut
    input_vectors = []
    # List with example data 
    # input_x_data = [fmt.from_float(random.uniform(-1, 1), saturate=False) for i in range(random_test_batch_size)]
    # input_y_data = [fmt.from_float(random.uniform(-1, 1), saturate=False) for i in range(random_test_batch_size)]
    input_x_data = [fmt.from_float(random.uniform(-1, 1), saturate=False) for i in range(random_test_batch_size)]
    input_y_data = [fmt.from_float(random.uniform(-1, 1), saturate=False) for i in range(random_test_batch_size)]
    # randomised weight from range [-1; 1]
    weight = fmt.from_float(1, saturate=False)

    # Clearing inputs and setting weight from range [-1; 1]
    clear_all_inputs(input_vectors)
    load_weight(input_vectors, weight.uraw())

    # Loading input data to the driver 
    for i in range(len(input_x_data)):
        put_data(input_vectors, input_x_data[i].uraw(), input_y_data[i].uraw())

    for i in input_vectors: 
        await tb.driver.send(i)

    # Clear all inputs on the end
    clear_all_inputs(input_vectors)

    # Expected output
    expected_x_data = input_x_data
    expected_y_data = [input_x_data[i]*weight+input_y_data[i] for i in range(len(input_x_data))]

    for i in range(len(expected_x_data)):
        await x_idealCaseQueue.put(expected_x_data[i].uraw())
        await y_idealCaseQueue.put(expected_y_data[i].uraw())

    tb.start()
    await tb.driver.wait(5000)
    assert await tb.scoreboard.verify() == 0

    pass


@cocotb.test()
async def random_weight_from_range_0_1_random_xy_data_from_range_minus_1_1_test(dut):
    x_idealCaseQueue = asyncio.Queue()
    y_idealCaseQueue = asyncio.Queue()
    tb = npu_pe_tb(dut, x_idealCaseQueue, y_idealCaseQueue, m_bits=M_bits, n_bits=N_bits)

    # List with entries representing inputs to the dut
    input_vectors = []
    # List with example data 
    input_x_data = [fmt.from_float(random.uniform(-1, 1)) for i in range(random_test_batch_size)]
    input_y_data = [fmt.from_float(random.uniform(-1, 1)) for i in range(random_test_batch_size)]
    # randomised weight from range [-1; 1]
    weight = fmt.from_float(random.uniform(0, 1))

    # Clearing inputs and setting weight from range [-1; 1]
    clear_all_inputs(input_vectors)
    load_weight(input_vectors, weight.uraw())

    # Loading input data to the driver 
    for i in range(len(input_x_data)):
        put_data(input_vectors, input_x_data[i].uraw(), input_y_data[i].uraw())

    for i in input_vectors: 
        await tb.driver.send(i)

    # Clear all inputs on the end
    clear_all_inputs(input_vectors)

    # Expected output
    expected_x_data = input_x_data
    expected_y_data = [input_x_data[i]*weight+input_y_data[i] for i in range(len(input_x_data))]

    for i in range(len(expected_x_data)):
        await x_idealCaseQueue.put(expected_x_data[i].uraw())
        await y_idealCaseQueue.put(expected_y_data[i].uraw())

    tb.start()
    await tb.driver.wait(5000)
    assert await tb.scoreboard.verify() == 0

    pass

@cocotb.test()
async def random_weight_from_range_minus_1_1_random_xy_data_from_range_minus_1_1_test(dut):
    x_idealCaseQueue = asyncio.Queue()
    y_idealCaseQueue = asyncio.Queue()
    tb = npu_pe_tb(dut, x_idealCaseQueue, y_idealCaseQueue, m_bits=M_bits, n_bits=N_bits)

    # List with entries representing inputs to the dut
    input_vectors = []
    # List with example data 
    input_x_data = [fmt.from_float(random.uniform(-1, 1)) for i in range(random_test_batch_size)]
    input_y_data = [fmt.from_float(random.uniform(-1, 1)) for i in range(random_test_batch_size)]
    # randomised weight from range [-1; 1]
    weight = fmt.from_float(random.uniform(-1, 1))

    # Clearing inputs and setting weight from range [-1; 1]
    clear_all_inputs(input_vectors)
    load_weight(input_vectors, weight.uraw())

    # Loading input data to the driver 
    for i in range(len(input_x_data)):
        put_data(input_vectors, input_x_data[i].uraw(), input_y_data[i].uraw())

    for i in input_vectors: 
        await tb.driver.send(i)

    # Clear all inputs on the end
    clear_all_inputs(input_vectors)

    # Expected output
    expected_x_data = input_x_data
    expected_y_data = [input_x_data[i]*weight+input_y_data[i] for i in range(len(input_x_data))]

    for i in range(len(expected_x_data)):
        await x_idealCaseQueue.put(expected_x_data[i].uraw())
        await y_idealCaseQueue.put(expected_y_data[i].uraw())

    tb.start()
    await tb.driver.wait(5000)
    assert await tb.scoreboard.verify() == 0

    pass


@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


