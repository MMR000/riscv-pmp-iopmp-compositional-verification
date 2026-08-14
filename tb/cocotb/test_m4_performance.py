"""M4B normal-operation DMA performance measurement."""

import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

from soc_test_lib import (
    ADDR_PROTECT,
    AUTH_RID,
    TEST_SECRET,
    WRITE_PATTERN,
    dma_read,
    dma_write,
    git_commit,
    reset_dut,
    seed_protected,
    setup_pmp_iopmp,
    write_csv,
)

M4_CFG = os.environ.get("M4_CONFIG", "C0")
OUT = Path(__file__).resolve().parents[2] / "results" / "m4" / "performance"


async def _cycles_for(coro, dut):
    start = 0
    # approximate cycle count via clk edges during op
    count = 0
    async def counter():
        nonlocal count
        while True:
            await RisingEdge(dut.clk)
            count += 1
    from cocotb import start_soon
    start_soon(Clock(dut.clk, 10, unit="ns").start())
    t = start_soon(counter())
    await coro
    t.kill()
    return count


@cocotb.test()
async def m4_performance_normal_dma(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    wr_start = 0
    for i in range(128):
        await RisingEdge(dut.clk)
        wr_start = i
        if int(dut.secure_ready.value):
            break
    await RisingEdge(dut.clk)
    c0 = 0
    for c in range(64):
        await RisingEdge(dut.clk)
        c0 = c
        dut.dma_src_addr.value = 0
        dut.dma_dst_addr.value = ADDR_PROTECT
        dut.dma_wdata.value = WRITE_PATTERN
        dut.dma_length.value = 4
        dut.dma_requester_id.value = AUTH_RID
        dut.dma_mode.value = 1
        dut.dma_start.value = 1
        await RisingEdge(dut.clk)
        dut.dma_start.value = 0
        break
    while int(dut.dma_done.value) == 0:
        await RisingEdge(dut.clk)
        c0 += 1
    await RisingEdge(dut.clk)
    write_lat = c0
    await RisingEdge(dut.clk)
    err_r, _ = await dma_read(dut, ADDR_PROTECT, AUTH_RID)
    row = {
        "configuration": M4_CFG,
        "git_commit": git_commit(),
        "normal_write_latency_cycles": write_lat,
        "normal_read_error": err_r,
        "secure_ready_cycles_after_reset": wr_start,
        "notes": "single transaction sample",
    }
    OUT.mkdir(parents=True, exist_ok=True)
    write_csv(OUT / f"m4_performance_{M4_CFG}.csv", [row])
    assert write_lat > 0
