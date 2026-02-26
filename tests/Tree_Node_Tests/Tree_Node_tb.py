import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio

# Random generator
import random
import logging

class Tree_Node_monitor:
    def __init__(self, name, dut, clk, rstn, debug_lines, output_lines, outQueue):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._debug_lines = debug_lines
        self._output_lines = output_lines
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
            # if self._ready.value == 1:
            #     await self._outQueue.put(self._data.value)

class Tree_Node_driver:
    def __init__(self, name, dut, clk, rstn, period, input_lines, output_lines, line_num):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._input_lines = input_lines
        self._output_lines = output_lines
        self._period = period
        self._task: Task[None] | None = None
        self._inQueue = asyncio.Queue()
        self._line_number = line_num
        self._name = name 
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)

    def start_clock(self):
        Clock(self._clk, self._period, unit='ns').start()

    async def wait(self, cycles):
        for i in range(cycles):
            await RisingEdge(self._clk)

    async def _reset(self):
        for i in range(self._line_number):
            self._input_lines[i].data.value = 0
            self._input_lines[i].address.value = 0
            self._input_lines[i].operation.value = 0
            self._input_lines[i].valid.value = 0

        self._rstn.value = 0
        await self.wait(2)
        self._rstn.value = 1
        await self.wait(2)

    async def send(self, input_list):
        await self._inQueue.put(input_list)

    async def _put(self, input_list):
        self._input_lines[input_list["line"]].data.value = input_list["data"]
        self._input_lines[input_list["line"]].address.value = input_list["address"]
        self._input_lines[input_list["line"]].operation.value = input_list["op"]
        self._input_lines[input_list["line"]].valid.value = 1
        
        while True:
            await self.wait(1)
            if(self._output_lines[input_list["line"]].ready.value == 1 and self._output_lines[input_list["line"]].active.value == 1):
                break

        self._input_lines[input_list["line"]].valid.value = 0
        await self.wait(input_list["pause"])

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
                await self._put(varData)
            await self.wait(1)


class Tree_Node_Scoreboard:
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


class Tree_Node_tb:
    def __init__(self, dut, idealCaseQueue):
        self._dut = dut
        self._monitorQueue = asyncio.Queue()
        self._idealCaseQueue = idealCaseQueue

        self.driver = Tree_Node_driver(
            dut = self._dut, 
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            name="Tree_Node_driver",
            input_lines=self._dut.i_NoC_ports, 
            output_lines=self._dut.o_NoC_ports,
            line_num=4,
            period=10
            )

        self.monitor = Tree_Node_monitor(
            dut = self._dut,
            clk = self._dut.i_clk,
            rstn = self._dut.i_rstn,
            debug_lines = self._dut.o_debug, 
            output_lines = self._dut.o_NoC_ports,
            name="Tree_Node_monitor",
            outQueue=self._monitorQueue
            )
        
        self.scoreboard = Tree_Node_Scoreboard(
            idealCaseQueue=self._idealCaseQueue,
            name="Tree_Node_Scoreboard",
            monitorQueue=self._monitorQueue
        )

    def start(self):
        self.driver.start()
        self.monitor.start()