import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock
import asyncio
import logging
from typing import Optional

class npu_sram_port_monitor:

    def __init__(
        self,
        name,
        dut,
        clk,
        rstn,
        en,
        we,
        addr,
        data_out,
        outQueue,
        read_latency=2,
    ):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._en = en
        self._we = we
        self._addr = addr
        self._data_out = data_out
        self._read_latency = read_latency
        self._outQueue = outQueue
        self._task: Optional[asyncio.Task] = None
        self.name = name
        self.log = logging.getLogger(name)

    async def _wait_active_en_cycles(self, cycles: int) -> bool:
        """Czeka na określoną liczbę aktywnej latencji (tylko gdy EN=1).

        Zwraca False, jeśli w międzyczasie nastąpił reset.
        """
        cycles_left = cycles
        while cycles_left > 0:
            await RisingEdge(self._clk)

            # Jeśli nastąpił reset, przerywamy przechwytywanie
            if self._rstn.value.is_resolvable and int(self._rstn.value) == 0:
                return False

            # Potok przesuwa się tylko przy aktywnym EN
            if self._en.value.is_resolvable and int(self._en.value) == 1:
                cycles_left -= 1

        return True

    def start(self):
        if self._task is not None:
            raise RuntimeError("Monitor already started")
        self._task = cocotb.start_soon(self._run())

    async def _run(self):
        while True:
            await RisingEdge(self._clk)

            # Sprawdzenie czy wartości na magistrali są stabilne (nie 'X' / 'Z')
            if not (
                self._rstn.value.is_resolvable
                and self._en.value.is_resolvable
                and self._we.value.is_resolvable
            ):
                continue

            # Inicjalizacja odczytu gdy: rstn=1, en=1, we=0
            if (
                int(self._rstn.value) == 1
                and int(self._en.value) == 1
                and int(self._we.value) == 0
            ):
                if self._addr.value.is_resolvable:
                    req_addr = int(self._addr.value)
                    cocotb.start_soon(self._capture_read(req_addr))

    async def _capture_read(self, addr: int):
        # Oczekujemy na latencję uwzględniając tylko cykle z EN=1
        completed_normally = await self._wait_active_en_cycles(
            self._read_latency
        )

        if not completed_normally:
            self.log.warning(
                f"Read from Addr 0x{addr:X} cancelled due to Reset!"
            )
            return

        # Pobieramy wynik z wyjścia
        if self._data_out.value.is_resolvable:
            data_val = int(self._data_out.value)
            await self._outQueue.put((addr, data_val))
            self.log.info(
                f"Captured Read from Addr 0x{addr:X}: Data = 0x{data_val:X}"
            )
        else:
            self.log.error(
                f"Captured Read from Addr 0x{addr:X} returned invalid data ('X'/'Z'): {self._data_out.value}"
            )

class npu_sram_port_driver:
    def __init__(self, name, dut, clk, rstn, en, we, addr, data_in, period):
        self._dut = dut
        self._clk = clk
        self._rstn = rstn
        self._en = en
        self._we = we
        self._addr = addr
        self._data_in = data_in
        self._period = period
        self._task: Optional[asyncio.Task] = None
        self._inQueue = asyncio.Queue()
        self.name = name
        self.log = logging.getLogger(name)

    async def wait(self, cycles):
        for _ in range(cycles):
            await RisingEdge(self._clk)

    async def _reset(self):
        self._rstn.value = 0
        self._en.value = 0
        self._we.value = 0
        self._addr.value = 0
        self._data_in.value = 0
        await self.wait(3)
        self._rstn.value = 1
        await self.wait(2)
        self.log.info("Reset performed & Port initialized")

    async def write(self, addr, data):
        await self._inQueue.put(('WRITE', addr, data))

    async def read(self, addr):
        await self._inQueue.put(('READ', addr, 0))

    async def set_enable(self, val):
        if val <= 0:
            await self._inQueue.put(('SET_EN', 0, 0))
        else:
            await self._inQueue.put(('SET_EN', 1, 0))

    async def delay(self, cycles):
        """Dodaje do kolejki polecenie oczekiwania, gdzie nic nie jest wykonywane."""
        await self._inQueue.put(('DELAY', cycles, 0))

    def start(self):
        if self._task is not None:
            raise RuntimeError("Driver already started")
        self._task = cocotb.start_soon(self._run())
        self.log.info("Started")

    async def _run(self):
        cocotb.start_soon(Clock(self._clk, self._period, units='ns').start())
        await self._reset()

        while True:
            if not self._inQueue.empty():
                op, addr, data = await self._inQueue.get()
                if op == 'DELAY':
                    self._we.value = 0
                    self._addr.value = 0
                    self._data_in.value = 0
                    await self.wait(addr)  # addr trzyma liczbę cykli opóźnienia
                elif op == 'WRITE':
                    self._we.value = 1
                    self._addr.value = addr
                    self._data_in.value = data
                    await self.wait(1)
                elif op == 'READ':
                    self._we.value = 0
                    self._addr.value = addr
                    self._data_in.value = 0
                    await self.wait(1)
                elif op == 'SET_EN':
                    self._en.value = addr
            else:
                self._we.value = 0
                self._addr.value = 0
                self._data_in.value = 0
                await self.wait(1)


class npu_sram_Scoreboard:
    def __init__(self, name, idealCaseQueue, monitorQueue):
        self.name = name
        self.log = logging.getLogger(name)
        self._idealCaseQueue = idealCaseQueue
        self._monitorQueue = monitorQueue

    async def verify(self):
        i = 0
        errors = 0

        if self._monitorQueue.qsize() != self._idealCaseQueue.qsize():
            self.log.error(f"Data size mismatch! Monitor: {self._monitorQueue.qsize()}, Ideal: {self._idealCaseQueue.qsize()}")
            return -1

        while not self._monitorQueue.empty():
            i += 1
            monitorData = await self._monitorQueue.get()
            idealData = await self._idealCaseQueue.get()
            if monitorData != idealData:
                self.log.error(f"Mismatch at sample {i}: Monitor = {monitorData}, Ideal = {idealData}")
                errors += 1
            else:
                self.log.info(f"Match at sample {i}: {monitorData}")
        return errors


class npu_sram_tb:
    def __init__(self, dut, read_latency=2, period_a=10, period_b=10):
        self._dut = dut
        self.read_latency = read_latency
        self._period_a = period_a
        self._period_b = period_b
        self.monitorQueue_A = asyncio.Queue()
        self.idealCaseQueue_A = asyncio.Queue()

        self.monitorQueue_B = asyncio.Queue()
        self.idealCaseQueue_B = asyncio.Queue()

        # Driver i Monitor Portu A
        self.driver_a = npu_sram_port_driver(
            dut=self._dut,
            clk=self._dut.i_clk_a,
            rstn=self._dut.i_rstn_a,
            en=self._dut.i_en_a,
            we=self._dut.i_we_a,
            addr=self._dut.i_addr_a,
            data_in=self._dut.i_data_a,
            period=self._period_a,
            name="npu_sram_Driver_A"
        )
        self.monitor_a = npu_sram_port_monitor(
            dut=self._dut,
            clk=self._dut.i_clk_a,
            rstn=self._dut.i_rstn_a,
            en=self._dut.i_en_a,
            we=self._dut.i_we_a,
            addr=self._dut.i_addr_a,
            data_out=self._dut.o_data_a,
            outQueue=self.monitorQueue_A,
            read_latency=self.read_latency,
            name="npu_sram_Monitor_A"
        )

        # Driver i Monitor Portu B
        self.driver_b = npu_sram_port_driver(
            dut=self._dut,
            clk=self._dut.i_clk_b,
            rstn=self._dut.i_rstn_b,
            en=self._dut.i_en_b,
            we=self._dut.i_we_b,
            addr=self._dut.i_addr_b,
            data_in=self._dut.i_data_b,
            period=self._period_b,
            name="npu_sram_Driver_B"
        )
        self.monitor_b = npu_sram_port_monitor(
            dut=self._dut,
            clk=self._dut.i_clk_b,
            rstn=self._dut.i_rstn_b,
            en=self._dut.i_en_b,
            we=self._dut.i_we_b,
            addr=self._dut.i_addr_b,
            data_out=self._dut.o_data_b,
            outQueue=self.monitorQueue_B,
            read_latency=self.read_latency,
            name="npu_sram_Monitor_B"
        )

        self.scoreboard_a = npu_sram_Scoreboard("npu_sram_Scoreboard_Port_A", self.idealCaseQueue_A, self.monitorQueue_A)
        self.scoreboard_b = npu_sram_Scoreboard("npu_sram_Scoreboard_Port_B", self.idealCaseQueue_B, self.monitorQueue_B)

    def start(self):
        self.driver_a.start()
        self.driver_b.start()
        self.monitor_a.start()
        self.monitor_b.start()

