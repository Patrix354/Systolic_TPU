import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio
import logging

# Fixed point operations
from QFormat import QFormat, FixedQ
from npu_mul_tb import npu_mul_tb

# Random generator
import random

period_ns = 10
M_bits = 8
N_bits = 8
fmt = QFormat(N_bits, M_bits)
random_test_batch = 1000

@cocotb.test()
async def pos_neg_entry_test(dut):
    idealCaseQueue = asyncio.Queue()

    # Performing necessary calculation
    a = fmt.from_float(1.5)
    b = fmt.from_float(-1.5)
    c = a * b
    # Defining expected output
    await idealCaseQueue.put(c.uraw())

    # Run testbench
    tb = npu_mul_tb(dut, idealCaseQueue)
    tb.start()
    await tb.driver.send(a.uraw(), b.uraw())
    await tb.driver.wait(100)

    # Assert every output number is equal expected value
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def neg_pos_entry_test(dut):
    idealCaseQueue = asyncio.Queue()

    # Performing necessary calculation
    a = fmt.from_float(-1.5)
    b = fmt.from_float(1.5)
    c = a * b

    # Defining expected output
    await idealCaseQueue.put(c.uraw())

    # Run testbench
    tb = npu_mul_tb(dut, idealCaseQueue)
    tb.start()
    await tb.driver.send(a.uraw(), b.uraw())
    await tb.driver.wait(100)

    # Assert every output number is equal expected value
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def pos_pos_entry_test(dut):
    idealCaseQueue = asyncio.Queue()

    # Performing necessary calculation
    a = fmt.from_float(1.5)
    b = fmt.from_float(1.5)
    c = a * b

    # Defining expected output
    await idealCaseQueue.put(c.uraw())

    # Run testbench
    tb = npu_mul_tb(dut, idealCaseQueue)
    tb.start()
    await tb.driver.send(a.uraw(), b.uraw())
    await tb.driver.wait(100)

    # Assert every output number is equal expected value
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def neg_neg_entry_test(dut):
    idealCaseQueue = asyncio.Queue()

    # Performing necessary calculation
    a = fmt.from_float(-1.5)
    b = fmt.from_float(-1.5)
    c = a * b

    # Defining expected output
    await idealCaseQueue.put(c.uraw())

    # Run testbench
    tb = npu_mul_tb(dut, idealCaseQueue)
    tb.start()
    await tb.driver.send(a.uraw(), b.uraw())
    await tb.driver.wait(100)

    # Assert every output number is equal expected value
    assert await tb.scoreboard.verify() == 0
    pass

# TODO: Dodaj testy dla krańców zakresów    

@cocotb.test()
async def random_data_from_range_minus_1_1_test(dut):
    idealCaseQueue = asyncio.Queue()

    # Instantiate testbnch
    tb = npu_mul_tb(dut, idealCaseQueue)

    for i in range(0, random_test_batch):
        # Generating random bits 
        a = fmt.from_float(random.uniform(-1, 1), saturate=False)
        b = fmt.from_float(random.uniform(-1, 1), saturate=False)
        c = a * b
    
        await tb.driver.send(a.uraw(), b.uraw())
        # Defining expected output
        await idealCaseQueue.put(c.uraw())

    # Run testbench
    tb.start()
    await tb.driver.wait(20000)

    # Assert every output number is equal expected value
    assert await tb.scoreboard.verify() == 0
    pass


@cocotb.test()
async def dummy_test(dut):
    pass


