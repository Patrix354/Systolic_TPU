import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio
import logging
from typing import Optional
from npu_sram_tb import *


@cocotb.test()
async def run_npu_sram_test(dut):
    """Główny scenariusz testowy dla npu_sram_wrapper z użyciem pauzy (delay)"""
    
    READ_LATENCY = 2
    tb = npu_sram_tb(dut, read_latency=READ_LATENCY, period_a=10, period_b=10)

    await Timer(50, units='ns')

    await tb.driver_a.set_enable(1)
    for i in range(255):
        await tb.driver_a.write(addr=i, data=(i<<1))
        await tb.driver_b.delay(1)
    await tb.driver_a.set_enable(0)

    await tb.driver_b.delay(10)

    await tb.driver_b.set_enable(1)
    for i in range(255):
        await tb.driver_b.read(addr=i)
        await tb.idealCaseQueue_B.put((i, (i<<1)))
    await tb.driver_b.delay(READ_LATENCY)
    await tb.driver_b.set_enable(0)

    tb.start()

    await Timer(12000, units='ns')

    errors_a = await tb.scoreboard_a.verify()
    errors_b = await tb.scoreboard_b.verify()

    assert errors_a == 0, f"Błędy na Porcie A: {errors_a}"
    assert errors_b == 0, f"Błędy na Porcie B: {errors_b}"