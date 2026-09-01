import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio
import numpy as np

# Fixed point operations
from npu_systolic_array_tb import npu_systolic_array_tb
from QFormat import QFormat, FixedQ
from FixedQ_Mat import FixedQ_Mat
import random

period_ns = 10
M_bits = 8
N_bits = 8
array_size = 25
random_test_batch_size = 100
qfmt = QFormat(N_bits, M_bits)

@cocotb.test()
async def diagonal_weights_random_data_form_range_0_1_test(dut):
    tb = npu_systolic_array_tb(dut=dut, array_size=array_size, m=M_bits, n=N_bits)

    W = FixedQ_Mat(arr_size=array_size, fmt=qfmt)
    X = FixedQ_Mat(arr_size=array_size, fmt=qfmt)
    W.diag()
    X.fill_random(-1, 1)
    Y = W * X


    W.transpose()
    await tb.driver.send(0, W)
    await tb.driver.send(1, X)
    await tb.scoreboard.send(Y)

    tb.start()
    
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def random_weights_from_range_0_1_random_data_from_range_minus_1_1_test(dut):
    tb = npu_systolic_array_tb(dut=dut, array_size=array_size, m=M_bits, n=N_bits)

    W = FixedQ_Mat(arr_size=array_size, fmt=qfmt)
    X_vect = [FixedQ_Mat(arr_size=array_size, fmt=qfmt) for i in range(random_test_batch_size)]
    Y_vect = [FixedQ_Mat(arr_size=array_size, fmt=qfmt) for i in range(random_test_batch_size)]

    W.fill_random(0, 1)

    for i in range(random_test_batch_size):
        X_vect[i].fill_random(-1, 1)
        Y_vect[i] = W * X_vect[i]

    W.transpose()
    await tb.driver.send(0, W)
    
    for i in range(random_test_batch_size):
        await tb.driver.send(1, X_vect[i])
        await tb.scoreboard.send(Y_vect[i])
        
    tb.start()
    
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def random_weights_from_range_minus_1_1_random_data_from_range_minus_1_1_test(dut):
    tb = npu_systolic_array_tb(dut=dut, array_size=array_size, m=M_bits, n=N_bits)

    W = FixedQ_Mat(arr_size=array_size, fmt=qfmt)
    X_vect = [FixedQ_Mat(arr_size=array_size, fmt=qfmt) for i in range(random_test_batch_size)]
    Y_vect = [FixedQ_Mat(arr_size=array_size, fmt=qfmt) for i in range(random_test_batch_size)]

    W.fill_random(-1, 1)

    for i in range(random_test_batch_size):
        X_vect[i].fill_random(-1, 1)
        Y_vect[i] = W * X_vect[i]

    W.transpose()
    await tb.driver.send(0, W)
    
    for i in range(random_test_batch_size):
        await tb.driver.send(1, X_vect[i])
        await tb.scoreboard.send(Y_vect[i])
        
    tb.start()
    
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def random_weights_from_range_0_1_random_data_from_range_0_1_test(dut):
    tb = npu_systolic_array_tb(dut=dut, array_size=array_size, m=M_bits, n=N_bits)

    W = FixedQ_Mat(arr_size=array_size, fmt=qfmt)
    X_vect = [FixedQ_Mat(arr_size=array_size, fmt=qfmt) for i in range(random_test_batch_size)]
    Y_vect = [FixedQ_Mat(arr_size=array_size, fmt=qfmt) for i in range(random_test_batch_size)]

    W.fill_random(0, 1)

    for i in range(random_test_batch_size):
        X_vect[i].fill_random(0, 1)
        Y_vect[i] = W * X_vect[i]

    W.transpose()
    await tb.driver.send(0, W)
    
    for i in range(random_test_batch_size):
        await tb.driver.send(1, X_vect[i])
        await tb.scoreboard.send(Y_vect[i])
        
    tb.start()
    
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


