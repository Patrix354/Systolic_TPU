import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

# Random generator
import random
import logging

class npu_pe_monitor:
    def __init__(self, name, dut, clk, rstn, ready, x_data, y_data, x_outQueue, y_outQueue):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._ready = ready
        self._x_data = x_data
        self._y_data = y_data
        self._task: Task[None] | None = None
        self._x_outQueue = x_outQueue
        self._y_outQueue = y_outQueue
        self._name = name 
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)

    async def wait(self, cycles):
        for i in range(cycles):
            await RisingEdge(self._clk)

    def start(self):
        if self._task is not None:
            raise RuntimeError("Monitor already started")
        self._task = cocotb.start_soon(self._run())

    async def _run(self):
        await RisingEdge(self._rstn)

        while True:
            await RisingEdge(self._clk)
            if self._ready.value == 1:
                await self._x_outQueue.put(self._x_data.value)
                await self._y_outQueue.put(self._y_data.value)
            # Warunek na pobranie danych i włożenie ich do kolejki

class npu_pe_driver:
    def __init__(self, name, dut, clk, rstn, valid, weight_en, weight, x_data, y_data, period):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._valid = valid
        self._x_data = x_data
        self._y_data = y_data
        self._weight = weight
        self._weight_en = weight_en
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
        self._x_data.value = 0
        self._y_data.value = 0
        self._valid.value = 0
        self._weight_en.value = 0
        self._weight.value = 0

        await self.wait(2)        
        self._rstn.value = 1
        await self.wait(2)

    async def send(self, input_list):
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
                self._x_data.value = varData[0]
                self._y_data.value = varData[1]
                self._weight.value = varData[2]
                self._weight_en.value = varData[3]
                self._valid.value = varData[4]
                
                await self.wait(1)
            else:
                self._x_data.value = 0
                self._y_data.value = 0
                self._weight.value = 0
                self._weight_en.value = 0
                self._valid.value = 0
                await self.wait(1)


class npu_pe_Scoreboard:
    def __init__(self, name, x_idealCaseQueue, x_monitorQueue, y_idealCaseQueue, y_monitorQueue):
        self._x_idealCaseQueue = x_idealCaseQueue
        self._x_monitorQueue = x_monitorQueue
        self._y_idealCaseQueue = y_idealCaseQueue
        self._y_monitorQueue = y_monitorQueue
        self._name = name 
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)
    
    async def verify(self):
        i = 0
        errors = 0

        if self._x_monitorQueue.qsize() != self._x_idealCaseQueue.qsize():
            errors = -1
            self._log.error("Input is not the size as expected, monitor queue size = ", self._monitorQueue.qsize(), ", ideal queue size = ", self._idealCaseQueue.qsize())
            return errors
        
        if self._y_monitorQueue.qsize() != self._y_idealCaseQueue.qsize():
            errors = -1
            self._log.error("Input is not the size as expected, monitor queue size = ", self._monitorQueue.qsize(), ", ideal queue size = ", self._idealCaseQueue.qsize())
            return errors

        while self._x_monitorQueue.empty() == False:
            i = i + 1
            monitorResult = await self._x_monitorQueue.get()
            idealResult = await self._x_idealCaseQueue.get()
            if  monitorResult != idealResult:
                errors = errors + 1
                self._log.error("Value Error: Expected output = ", idealResult, ", Monitor output: ", monitorResult, ", iter = ", i)

        while self._y_monitorQueue.empty() == False:
            i = i + 1
            monitorResult = await self._y_monitorQueue.get()
            idealResult = await self._y_idealCaseQueue.get()
            if  monitorResult != idealResult:
                errors = errors + 1
                self._log.error("Value Error: Expected output = ", idealResult, ", Monitor output: ", monitorResult, ", iter = ", i)
        return errors


class npu_pe_tb:
    def __init__(self, dut, x_idealCaseQueue, y_idealCaseQueue):
        self._dut = dut
        self._x_monitorQueue = asyncio.Queue()
        self._x_idealCaseQueue = x_idealCaseQueue
        self._y_monitorQueue = asyncio.Queue()
        self._y_idealCaseQueue = y_idealCaseQueue


        self.driver = npu_pe_driver(
            dut = self._dut, 
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            valid = self._dut.i_en,
            x_data = self._dut.i_x,
            y_data = self._dut.i_y,
            weight = self._dut.i_w,
            weight_en = self._dut.i_w_en,
            name="npu_pe_driver",
            period=10
            )


        self.monitor = npu_pe_monitor(
            dut = self._dut,
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            ready=self._dut.o_en,
            x_data = self._dut.o_x,
            y_data = self._dut.o_y,
            name="npu_pe_monitor",
            x_outQueue=self._x_monitorQueue,
            y_outQueue=self._y_monitorQueue
            )
       
        self.scoreboard = npu_pe_Scoreboard(
            x_idealCaseQueue=self._x_idealCaseQueue,
            x_monitorQueue=self._x_monitorQueue,
            y_idealCaseQueue=self._y_idealCaseQueue,
            y_monitorQueue=self._y_monitorQueue,
            name="npu_pe_Scoreboard",
            
        )

    def start(self):
        self.driver.start()
        self.monitor.start()