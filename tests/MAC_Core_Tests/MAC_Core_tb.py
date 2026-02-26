import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

# Random generator
import random
import logging

class MAC_Core_monitor:
    def __init__(self, name, dut, clk, rstn, ready, data, outQueue):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._ready = ready
        self._data = data
        self._task: Task[None] | None = None
        self._outQueue = outQueue
        self._name = name 
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)

    async def wait(self, cycles):
        for i in range(cycles):
            await RisingEdge(self._clk)

    def start(self):
        if self._task is not None:
            raise RuntimeError("Driver already started")
        self._task = cocotb.start_soon(self._run())

    async def _run(self):
        await RisingEdge(self._rstn)

        while True:
            await RisingEdge(self._clk)
            if self._ready.value == 1:
                await self._outQueue.put(self._data.value)

class MAC_Core_driver:
    def __init__(self, name, dut, clk, rstn, valid, zero, data, period):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._valid = valid
        self._zero = zero
        self._data = data
        self._period = period
        self._task: Task[None] | None = None
        self._inQueue = asyncio.Queue()
        self._name = name 
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)

    def start_clock(self):
        Clock(self._clk, self._period, unit='ns').start()

    async def wait(self, cycles):
        for i in range(cycles):
            await RisingEdge(self._clk)

    async def _reset(self):
        self._rstn.value = 0
        for i in self._data:
            i.value = 0
        self._valid.value = 0
        self._zero.value = 0

        await self.wait(2)        
        self._rstn.value = 1
        await self.wait(2)
    
    async def zero_acc(self):
        self._zero.value = 1
        await self.wait(2)
        self._zero.value = 0
        await self.wait(2)

    async def send(self, input_list):
        if len(input_list) != len(self._data):
            raise IndexError("input list has to be the same length as input size")
        await self._inQueue.put(input_list)

    def start(self):
        self.start_clock()
        if self._task is not None:
            raise RuntimeError("Driver already started")
        self._task = cocotb.start_soon(self._run())

    async def _run(self):
        await self._reset()

        while True:
            if self._inQueue.empty() == False:
                varData = await self._inQueue.get()
                for i in reversed(self._data.range):
                    self._data[i].value = varData[i]
                self._valid.value = 1
                await self.wait(1)
            else:
                self._valid.value = 0
                for i in self._data:
                    i.value = 0
                await self.wait(1)


class MAC_Core_Scoreboard:
    def __init__(self, name, idealCaseQueue, monitorQueue):
        self._idealCaseQueue = idealCaseQueue
        self._monitorQueue = monitorQueue
        self._name = name 
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)
    
    async def verify(self):
        i = 0
        errors = 0

        if self._monitorQueue.qsize() != self._idealCaseQueue.qsize():
            errors = -1
            self._log.error("Input is not the size as expected")
            return errors

        while self._monitorQueue.empty() == False:
            i = i + 1
            monitorResult = await self._monitorQueue.get()
            idealResult = await self._idealCaseQueue.get()
            if  monitorResult != idealResult:
                errors = errors + 1
                self._log.error("Value Error: Expected output = ", idealResult, ", Monitor output: ", monitorResult, ", iter = ", i)
        return errors


class MAC_Core_tb:
    def __init__(self, dut, idealCaseQueue):
        self._dut = dut
        self._monitorQueue = asyncio.Queue()
        self._idealCaseQueue = idealCaseQueue

        self.driver = MAC_Core_driver(
            dut = self._dut, 
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            valid = self._dut.i_valid,
            zero = self._dut.i_zero,
            data=self._dut.i_data,
            name="MAC_Core_driver",
            period=10
            )

        self.monitor = MAC_Core_monitor(
            dut = self._dut,
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            ready=self._dut.o_done,
            data = self._dut.o_data,
            name="MAC_Core_monitor",
            outQueue=self._monitorQueue
            )
        
        self.scoreboard = MAC_Core_Scoreboard(
            idealCaseQueue=self._idealCaseQueue,
            name="MAC_Core_Scoreboard",
            monitorQueue=self._monitorQueue
        )

    def start(self):
        self.driver.start()
        self.monitor.start()