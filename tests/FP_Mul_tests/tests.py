import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock

@cocotb.test()
async def downup_test(dut):
    for i in [0, 1]:
        x = i
        dut.X.value = x
        await Timer(2, unit="ns")

        assert dut.Y.value == 1 - i, (
            f"Inverter result is incorrect: {dut.Y.value} != 0"
        )
    pass

@cocotb.test()
async def updown_test(dut):
    for i in [1, 0]:
        x = i
        dut.X.value = x
        await Timer(2, unit="ns")

        assert dut.Y.value == 1 - i, (
            f"Inverter result is incorrect: {dut.Y.value} != 0"
        )
    pass
    

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


