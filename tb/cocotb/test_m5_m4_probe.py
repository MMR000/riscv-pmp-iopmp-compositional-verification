"""M5 single-transaction M4-IOPMP probe for differential testing."""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from soc_test_lib import (
    ADDR_PROTECT,
    AUTH_RID,
    WRITE_PATTERN,
    cfg_write,
    dma_write,
    reset_dut,
    seed_protected,
    setup_pmp_iopmp,
)

M4_CFG = os.environ.get("M4_CONFIG", "C1")
RRID = int(os.environ.get("M5_RRID", str(AUTH_RID)))
ADDR = int(os.environ.get("M5_ADDR", str(ADDR_PROTECT)), 0)
IS_WRITE = os.environ.get("M5_OP", "write") == "write"
CONFIGURED = os.environ.get("M5_CONFIGURED", "1") == "1"
IOPMP_ENABLE = os.environ.get("M5_IOPMP_ENABLE", "1") == "1"


@cocotb.test()
async def m5_m4_probe(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)
    await seed_protected(dut, 0xDEADBEEF, restore_iopmp=False)
    await cfg_write(dut, 0x4000_0000 + 0x0, 1)
    await cfg_write(dut, 0x4000_0000 + 0x4, 1 if IOPMP_ENABLE else 0)
    if CONFIGURED:
        await setup_pmp_iopmp(dut, authorized_rid=RRID if RRID <= 0xFF else AUTH_RID)
    rid = RRID if RRID <= 0xFF else AUTH_RID
    if IS_WRITE:
        err, _ = await dma_write(dut, ADDR, WRITE_PATTERN, rid)
    else:
        from soc_test_lib import dma_read
        err, _ = await dma_read(dut, ADDR, rid)
    result = "DENY" if err else "ALLOW"
    path = os.environ.get("M5_M4_PROBE_OUT", "/tmp/m5_m4_probe.txt")
    with open(path, "w") as f:
        f.write(f"{result}\n")
    assert True
