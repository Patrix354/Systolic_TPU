import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

# Random generator
import random
import logging

class npu_mul_monitor:
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

class npu_mul_driver:
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

    async def wait(self, cycles):
        for i in range(0, cycles):
            await RisingEdge(self._clk)

    async def _reset(self):
        self._rstn.value = 0
        self._a.value = 0
        self._b.value = 0
        self._valid.value = 0

        await self.wait(3)        
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
        Clock(self._clk, self._period, unit='ns').start()
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


class npu_mul_Scoreboard:
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
            i = i + 1
            monitorData = await self._monitorQueue.get()
            idealData = await self._idealCaseQueue.get()
            if monitorData != idealData:
                self.log.error(f"monitorData != idealData: monitorData = {(int(monitorData))} idealData = {int(idealData)}, i = {i}")
                errors = errors + 1
        return errors


class npu_mul_tb:
    def __init__(self, dut, idealCaseQueue):
        self._dut = dut
        self._monitorQueue = asyncio.Queue()
        self._idealCaseQueue = idealCaseQueue

        self.driver = npu_mul_driver(
            dut = self._dut, 
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            valid = self._dut.i_valid,
            a=self._dut.i_a,
            b=self._dut.i_b,
            period=10,
            name="npu_mul_Driver"
            )

        self.monitor = npu_mul_monitor(
            dut = self._dut,
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            ready = self._dut.o_ready,
            y = self._dut.o_y,
            outQueue=self._monitorQueue,
            name="npu_mul_Monitor"
            )
        
        self.scoreboard = npu_mul_Scoreboard(
            idealCaseQueue=self._idealCaseQueue,
            monitorQueue=self._monitorQueue,
            name="npu_mul_Scoreboard"
        )

    def start(self):
        self.driver.start()
        self.monitor.start()