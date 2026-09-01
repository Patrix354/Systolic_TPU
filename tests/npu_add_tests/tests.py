import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer
from cocotb.clock import Clock

# Fixed point operations
from QFormat import QFormat, FixedQ

# Random generator
import random

period_ns = 10
M_bits = 8
N_bits = 8
fmt = QFormat(N_bits, M_bits)

async def reset_seq(dut):
    dut.i_rstn.value = 0
    dut.i_a.value = 0
    dut.i_b.value = 0

    Clock(dut.i_clk, period_ns, unit='ns').start()
    for i in range(0, 2):
        await RisingEdge(dut.i_clk)

    dut.i_rstn.value = 1

    await RisingEdge(dut.i_clk)

async def test_two_numbers(dut, a_in, b_in):
    # Creating 2 fixedpoint numbers 
    a = fmt.from_float(a_in, saturate=False)
    b = fmt.from_float(b_in, saturate=False)

    # Counting sum and writing result as a fixed point
    c = a + b

    # Assigning values
    dut.i_a.value = a.uraw()
    dut.i_b.value = b.uraw()
    dut.i_valid.value = 1
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0
    
    for i in range(0,2):
        await RisingEdge(dut.i_clk)

    # Assertion
    assert dut.o_y.value == c.uraw(), (
        f"Addition isn't correct. a = {a.to_float()}, b = {b.to_float()}, c = {c.to_float()}"
    )

    await RisingEdge(dut.i_clk)

@cocotb.test()
async def pos_pos_result_pos(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, 2, 1.5)
    pass

@cocotb.test()
async def neg_pos_result_pos(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, -1.5, 1.5)
    pass

@cocotb.test()
async def neg_pos_result_neg(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, -2, 1.5)
    pass

@cocotb.test()
async def neg_neg_result_neg(dut):
    await reset_seq(dut)
    await test_two_numbers(dut, -2, -1.5)
    pass

@cocotb.test()
async def randomised_test(dut):
    await reset_seq(dut)

    for i in range(0, 100):
        # Generating random bit sequence 
        # (2 bits shorter because module has equal sized inputs and output. Unused bits will be removed during synthesis)
        a = fmt.from_raw(random.getrandbits(N_bits + M_bits - 2)).to_float()
        b = fmt.from_raw(random.getrandbits(N_bits + M_bits - 2)).to_float()
    
        await test_two_numbers(dut, a, b)
    pass

@cocotb.test()
async def randomised_test_range_minus_2_2(dut):
    await reset_seq(dut)

    for i in range(0, 100):
        # Generating random bit sequence 
        # (2 bits shorter because module has equal sized inputs and output. Unused bits will be removed during synthesis)
        a = random.uniform(-2, 2)
        b = random.uniform(-2, 2)
    
        await test_two_numbers(dut, a, b)
    pass

@cocotb.test()
async def dummy_test(dut):
    """ Basic test """
    pass


