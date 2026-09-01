import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

# Random generator
import random
import logging

class npu_systolic_array_delay_monitor:
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
            raise RuntimeError("Monitor already started")
        self._task = cocotb.start_soon(self._run())

    async def _run(self):
        await RisingEdge(self._rstn)

        while True:
            await RisingEdge(self._clk)
            if self._ready.value == 1:
                await self._outQueue.put(self._data.value)
            # Warunek na pobranie danych i włożenie ich do kolejki

class npu_systolic_array_delay_driver:
    def __init__(self, name, dut, clk, rstn, valid, data, period):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._valid = valid
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

        for i in range(len(self._data)):
            self._data[i].value = 0
        self._valid.value = 0

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
                enable_val = 0
                for i in range(len(self._data)):
                    self._data[i].value = varData[0][i]
                    enable_val = enable_val | (varData[1][i] << i)
                self._valid.value = enable_val
                
                await self.wait(1)
            else:
                for i in range(len(self._data)):
                    self._data[i].value = 0
                self._valid.value = 0
                await self.wait(1)


class npu_systolic_array_delay_Scoreboard:
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
            self._log.error("Input is not the size as expected, monitor queue size = ", self._monitorQueue.qsize(), ", ideal queue size = ", self._idealCaseQueue.qsize())
            return errors

        while self._monitorQueue.empty() == False:
            i = i + 1
            monitorResult = await self._monitorQueue.get()
            idealResult = await self._idealCaseQueue.get()
            if  monitorResult != idealResult:
                errors = errors + 1
                self._log.error("Value Error: Expected output = ", idealResult, ", Monitor output: ", monitorResult, ", iter = ", i)
        return errors

class npu_systolic_array_delay_tb:
    #def __init__(self, dut, idealCaseQueue):
    def __init__(self, dut, idealCaseQueue):
        self._dut = dut
        #self._monitorQueue = asyncio.Queue()
        #self._idealCaseQueue = idealCaseQueue


        self.driver = npu_systolic_array_delay_driver(
            dut = self._dut, 
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            valid = self._dut.i_en,
            data = self._dut.i_data,
            name="npu_delay_driver",
            period=10
            )


        # self.monitor = npu_delay_monitor(
        #     dut = self._dut,
        #     clk = self._dut.i_clk,
        #     rstn = self._dut.i_rstn,
        #     ready=self._dut.o_en,
        #     data = self._dut.o_data,
        #     name="npu_pe_monitor",
        #     outQueue=self._monitorQueue,
        #     )
       
        # self.scoreboard = npu_delay_Scoreboard(
        #     idealCaseQueue=self._idealCaseQueue,
        #     monitorQueue=self._monitorQueue,
        #     name="npu_delay_Scoreboard",
            
        #)

    def start(self):
        self.driver.start()
        # self.monitor.start()