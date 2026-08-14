"""M7 multi-requester checks on research RTL (single outstanding depth)."""

import csv
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from soc_test_lib import (
    ADDR_PROTECT,
    AUTH_RID,
    TEST_SECRET,
    UNAUTH_RID,
    WRITE_PATTERN,
    dma_write,
    peek_protected,
    reset_dut,
    seed_protected,
    setup_pmp_iopmp,
)

OUT = Path(os.environ.get("M7_MM_OUT", Path(__file__).resolve().parents[2] / "results/m7/multimaster"))
OUT.mkdir(parents=True, exist_ok=True)
ROWS: list[dict] = []


def record(check_id: str, status: str, classification: str, notes: str = "") -> None:
    ROWS.append({
        "check_id": check_id,
        "requesters": 1,
        "outstanding_depth": 1,
        "result": status,
        "classification": classification,
        "notes": notes,
    })


@cocotb.test()
async def m7_multimaster_checks(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)

    # M7-MR-01: requester ID affects authorization
    err_a, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after_a = await peek_protected(dut, ADDR_PROTECT)
    err_u, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN + 1, UNAUTH_RID)
    after_u = await peek_protected(dut, ADDR_PROTECT)
    mr01 = (not err_a) and err_u and (after_u != WRITE_PATTERN + 1)
    record("M7-MR-01", "PASS" if mr01 else "FAIL", "SIMULATION_EVIDENCE")

    # M7-MR-03: denied request cannot modify target
    before = await peek_protected(dut, ADDR_PROTECT)
    err_d, _ = await dma_write(dut, ADDR_PROTECT, 0xBAD0BAD0, UNAUTH_RID)
    after_d = await peek_protected(dut, ADDR_PROTECT)
    mr03 = err_d and (after_d == before)
    record("M7-MR-03", "PASS" if mr03 else "FAIL", "SIMULATION_EVIDENCE", f"err={err_d}")

    # M7-MR-04: one denial does not authorize another (sequential)
    await seed_protected(dut, TEST_SECRET)
    err1, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, UNAUTH_RID)
    err2, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await peek_protected(dut, ADDR_PROTECT)
    mr04 = err1 and (not err2) and (after == WRITE_PATTERN)
    record("M7-MR-04", "PASS" if mr04 else "FAIL", "SIMULATION_EVIDENCE")

    # Outstanding depth >1: UNSUPPORTED on research IOPMP
    for depth in (2, 4, 8):
        record(
            f"M7-MR-OD-{depth}",
            "UNSUPPORTED_BY_IMPLEMENTATION",
            "UNSUPPORTED_BY_IMPLEMENTATION",
            "research iopmp single pending slot",
        )

    csv_path = OUT / "m7_multimaster_raw.csv"
    if ROWS:
        with csv_path.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(ROWS[0].keys()))
            w.writeheader()
            w.writerows(ROWS)
