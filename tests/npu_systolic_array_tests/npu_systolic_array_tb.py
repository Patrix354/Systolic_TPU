import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer
from cocotb.clock import Clock
from cocotb.types import LogicArray
import asyncio

import logging

from FixedQ_Mat import FixedQ_Mat
from QFormat import QFormat, FixedQ
import numpy as np

class npu_systolic_array_driver:
    def __init__(self, name, m, n, dut, clk, rstn, clr, valid, weight_en, weight, data, array_size, period):
        self._dut = dut
        self._array_size = array_size
        self._clk = clk
        self._rstn = rstn
        self._clr = clr
        self._valid = valid
        self._data = data
        self._weight = weight
        self._weight_en = weight_en
        self._period = period
        self._m = m
        self._n = n
        self._qfmt = QFormat(n, m)
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
        self._valid.value = 0
        self._clr.value = 0
        self._weight_en.value = 0
        for i in range(self._array_size):
            self._weight[i].value = 0
            self._data[i].value = 0

        await self.wait(2)
        self._rstn.value = 1
        await self.wait(2)

    async def send(self, op, input_matrix):
        await self._inQueue.put([op, input_matrix])

    def start(self):
        self.start_clock()
        if self._task is not None:
            raise RuntimeError("Driver already started")
        self._task = cocotb.start_soon(self._run())

    async def _load_weights(self, mat):
        for col in range(self._array_size):
            for row in range(self._array_size):
                self._weight[row].value = mat.X[row][col].uraw()
            self._weight_en.value = (1 << col)
            await self.wait(1)

        for row in range(self._array_size):
            self._weight[row].value = 0
        self._weight_en.value = 0
        await self.wait(1)

    async def _load_data(self, data):
        for col in range(self._array_size):
            for row in range(self._array_size):
                self._data[row].value = data.X[row][col].uraw()
            self._valid.value = 1 
            await self.wait(1)

    async def _run(self):
        await self._reset()

        while True:
            if self._inQueue.empty() == False:
                varData = await self._inQueue.get()
                if varData[0] == 0:
                    await self._load_weights(varData[1])
                else:
                    await self._load_data(varData[1])

            else:
                for row in range(self._array_size):
                    self._data[row].value = 0
                    self._valid.value = 0
                await self.wait(1)

class npu_systolic_array_monitor:
    def __init__(self, name, m, n, dut, clk, rstn, ready, data, array_size, outQueue):
        self._dut = dut
        self._array_size = array_size
        self._rstn = rstn
        self._clk = clk
        self._ready = ready
        self._data = data
        self._m = m
        self._n = n
        self._qfmt = QFormat(n, m)
        self._task: Task[None] | None = None
        self._outQueue = outQueue
        self._name = name 
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)
        self._col_counter = 0

    async def wait(self, cycles):
        for i in range(cycles):
            await RisingEdge(self._clk)


    def start(self):
        if self._task is not None:
            raise RuntimeError("Monitor already started")
        self._task = cocotb.start_soon(self._run())

    async def _run(self):
        await RisingEdge(self._rstn)

        outMatrix = FixedQ_Mat(arr_size=self._array_size, fmt=self._qfmt)

        while True:
            await RisingEdge(self._clk)
            if self._ready.value == 1:
                if self._col_counter >= self._array_size - 1:
                    for i in range(len(self._data)):
                        outMatrix.X[i][self._col_counter] = self._qfmt.from_raw(int(self._data[i].value), saturate=False)
                    self._col_counter = 0
                    await self._outQueue.put(outMatrix)
                else:
                    for i in range(len(self._data)):
                        outMatrix.X[i][self._col_counter] = self._qfmt.from_raw(int(self._data[i].value), saturate=False)
                    self._col_counter = self._col_counter + 1
            # Warunek na pobranie danych i włożenie ich do kolejki

class npu_systolic_array_scoreboard:
    def __init__(self, monitorQueue, name):
        self._monitorQueue = monitorQueue
        self._goldenQueue = asyncio.Queue()
        self._name = name
        self._log = logging.getLogger(self._name)
        self._log.setLevel(logging.INFO)

    async def send(self, Mat):
        await self._goldenQueue.put(Mat)

    async def verify(self):    
        i = 0

        # if self._monitorQueue.qsize() != self._goldenQueue.qsize():
        #     self._log.error("Input is not the size as expected, monitor queue size = ", self._monitorQueue.qsize(), ", golden queue size = ", self._goldenQueue.qsize())
        #     return -1
    
        while(self._goldenQueue.empty() == False):
            await Timer(1, unit="ns")
            if self._monitorQueue.empty() == False:
                i = i + 1
                monitorResult = await self._monitorQueue.get()
                idealResult = await self._goldenQueue.get()
                if monitorResult == idealResult:
                    print(f"iter = {i}")
                elif monitorResult != idealResult:
                    #self._log.error("Value Error: Expected output = ", idealResult, ", Monitor output: ", monitorResult, ", iter = ", i)
                    self._log.error("Value Error: Expected output and Monitor output dont match, iter = ", i)
                    monitorResult.disp()
                    idealResult.disp()
                    return 1
        return 0

class npu_systolic_array_tb:
    def __init__(self, dut, m, n, array_size):
        self._dut = dut
        self._monitorOutput = asyncio.Queue()
        self._array_size = array_size
        self._m = m
        self._n = n

        self.driver = npu_systolic_array_driver(
            dut=self._dut,
            clk=self._dut.i_clk,
            rstn=self._dut.i_rstn,
            clr=self._dut.i_clr,
            valid=self._dut.i_en,
            data=self._dut.i_data,
            weight=self._dut.i_w,
            m = self._m,
            n = self._n,
            weight_en=self._dut.i_w_en,
            array_size=self._array_size,
            name="npu_systolic_array_driver",
            period=10
        )

        self.monitor = npu_systolic_array_monitor(
            dut=self._dut,
            clk=self._dut.i_clk,
            rstn=self._dut.i_rstn,
            ready=self._dut.o_en,
            data=self._dut.o_data,
            array_size=self._array_size,
            outQueue=self._monitorOutput,
            name="npu_systolic_array_monitor",
            m=self._m,
            n=self._n
        )

        self.scoreboard = npu_systolic_array_scoreboard(
            monitorQueue=self._monitorOutput,
            name="npu_systoilic_array_Scoreboard"
        )

    def start(self):
        self.monitor.start()
        self.driver.start() 

