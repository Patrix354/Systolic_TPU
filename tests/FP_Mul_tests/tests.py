import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio
import logging

# Fixed point operations
import fp_op
import fixedpoint

# Random generator
import random

period_ns = 10
M_bits = 4
N_bits = 4

class FP_Mul_monitor:
    def __init__(self, name, dut, clk, rstn, ready, y, outQueue):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._ready = ready
        self._y = y
        self._task: Task[None] | None = None
        self._outQueue = outQueue
        self.name = name
        self.log = logging.getLogger(name)

    async def wait(self, cycles):
        for i in range(0, cycles):
            await RisingEdge(self._clk)

    def start(self):
        if self._task is not None:
            raise RuntimeError("Driver already started")
        self._task = cocotb.start_soon(self._run())

    async def _run(self):
        await RisingEdge(self._rstn)

        while True:
            if self._ready.value == 1:
                await self._outQueue.put(self._y.value)
            await self.wait(1)

class FP_Mul_driver:
    def __init__(self, name, dut, clk, rstn, valid, a, b, period):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._valid = valid
        self._a = a
        self._b = b
        self._period = period
        self._task: Task[None] | None = None
        self._inQueue = asyncio.Queue()
        self.name = name
        self.log = logging.getLogger(name)

    def start_clock(self):
        Clock(self._clk, self._period, unit='ns').start()

    async def wait(self, cycles):
        for i in range(0, cycles):
            await RisingEdge(self._clk)

    async def _reset(self):
        self._rstn.value = 0
        self._a.value = 0
        self._b.value = 0
        self._valid.value = 0
        
        self.start_clock()
        await self.wait(1)        
        self._rstn.value = 1
        await self.wait(2)
        self.log.info("Reset performed")

    async def send(self, a, b):
        await self._inQueue.put([a, b])

    def start(self):
        if self._task is not None:
            raise RuntimeError("Driver already started")
        self._task = cocotb.start_soon(self._run())
        self.log.info("Started")

    async def _run(self):
        await self._reset()

        while True:
            if self._inQueue.empty() == False:
                varData = await self._inQueue.get()
                self._a.value = varData[0]
                self._b.value = varData[1]
                self._valid.value = 1
                await self.wait(1)
            else:
                self._valid.value = 0
                self._a.value = 0
                self._b.value = 0
                await self.wait(1)


class FP_Mul_Scoreboard:
    def __init__(self, name, idealCaseQueue, monitorQueue):
        self.name = name
        self.log = logging.getLogger(name)
        self._idealCaseQueue = idealCaseQueue
        self._monitorQueue = monitorQueue
    
    async def verify(self):
        i = 0
        errors = 0

        if self._monitorQueue.qsize() != self._idealCaseQueue.qsize():
            self.log.error("Not Collected all data")
            errors = -1
            return errors

        while self._monitorQueue.empty() == False:
            monitorData = await self._monitorQueue.get()
            idealData = await self._idealCaseQueue.get()
            if monitorData != idealData:
                self.log.error("monitorData != idealData: monitorData = ", monitorData, " , idealData = ", idealData)
                errors = errors + 1
        return errors


class FP_Mul_tb:
    def __init__(self, dut, idealCaseQueue):
        self._dut = dut
        self._monitorQueue = asyncio.Queue()
        self._idealCaseQueue = idealCaseQueue

        self.driver = FP_Mul_driver(
            dut = self._dut, 
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            valid = self._dut.i_valid,
            a=self._dut.i_a,
            b=self._dut.i_b,
            period=10,
            name="FP_Mul_Driver"
            )

        self.monitor = FP_Mul_monitor(
            dut = self._dut,
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            ready = self._dut.o_ready,
            y = self._dut.o_y,
            outQueue=self._monitorQueue,
            name="FP_Mul_Monitor"
            )
        
        self.scoreboard = FP_Mul_Scoreboard(
            idealCaseQueue=self._idealCaseQueue,
            monitorQueue=self._monitorQueue,
            name="FP_Mul_Scoreboard"
        )

    def start(self):
        self.driver.start()
        self.monitor.start()

@cocotb.test()
async def non_random_entry_test(dut):
    idealCaseQueue = asyncio.Queue()

    # Creating two Fixed point numbers 
    a = fixedpoint.FixedPoint(1.5, m=M_bits, n=N_bits, signed=True)
    b = fixedpoint.FixedPoint(-1.5, m=N_bits, n=N_bits, signed=True)
    c = fp_op.fixed_mul(a, b)   # Fixed point multiplication

    # Conversion Fixed point number to int (raw bits)
    iA = fp_op.fixed_to_int(a)
    iB = fp_op.fixed_to_int(b)
    iC = fp_op.fixed_to_int(c)

    # Defining expected output
    await idealCaseQueue.put(iC)

    # Run testbench
    tb = FP_Mul_tb(dut, idealCaseQueue)
    tb.start()
    await tb.driver.send(iA, iB)
    await tb.driver.wait(10)

    # Assert every output number is equal expected value
    assert await tb.scoreboard.verify() == 0
    pass

@cocotb.test()
async def random_entry_test(dut):
    idealCaseQueue = asyncio.Queue()

    # Instantiate testbnch
    tb = FP_Mul_tb(dut, idealCaseQueue)

    for i in range(0, 100):
        # Generating random bits 
        rand_a = hex(random.getrandbits(N_bits + M_bits))
        rand_b = hex(random.getrandbits(N_bits + M_bits))
        
        a = fixedpoint.FixedPoint(rand_a, m=M_bits, n=N_bits, signed=True)
        b = fixedpoint.FixedPoint(rand_b, m=M_bits, n=N_bits, signed=True)
        c = fp_op.fixed_mul(a, b)

        iA = fp_op.fixed_to_int(a)
        iB = fp_op.fixed_to_int(b)
        iC = fp_op.fixed_to_int(c)

        await tb.driver.send(iA, iB)
        # Defining expected output
        await idealCaseQueue.put(iC)

    # Run testbench
    tb.start()
    await tb.driver.wait(200)

    # Assert every output number is equal expected value
    assert await tb.scoreboard.verify() == 0
    pass


@cocotb.test()
async def dummy_test(dut):
    pass


