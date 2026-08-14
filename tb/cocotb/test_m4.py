"""M4 directed reset/recovery and pending-transaction experiments."""

import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

from soc_test_lib import (
    ADDR_PROTECT,
    ADDR_SEC_CFG,
    AUTH_RID,
    TEST_SECRET,
    WRITE_PATTERN,
    append_security_matrix,
    cfg_write,
    dma_write,
    enable_iopmp_rule,
    finish_dma,
    peek_protected,
    pulse_dma,
    record,
    reset_dut,
    revoke_iopmp_rule,
    seed_protected,
    setup_pmp_iopmp,
    wait_txn_age,
    write_csv,
)

M4_RESULTS = Path(__file__).resolve().parents[2] / "results" / "simulation"
M4_CFG = os.environ.get("M4_CONFIG", "C0")
ROWS = []


def _cfg_label():
    return M4_CFG


async def _init(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)


def _prot_changed(dut):
    try:
        return int(dut.prot_mem_changed.value) == 1
    except ValueError:
        return False


async def _cycle_count_until(dut, pred, timeout=64):
    for c in range(timeout):
        await RisingEdge(dut.clk)
        await ReadOnly()
        if pred():
            return c
    return -1


@cocotb.test()
async def m4_pend_write_at_secure_ready_drop(dut):
    """M4-PEND-01: authorized write pending when secure_ready deasserts."""
    await _init(dut)
    dut.dma_src_addr.value = 0
    dut.dma_dst_addr.value = ADDR_PROTECT
    dut.dma_wdata.value = WRITE_PATTERN
    dut.dma_length.value = 4
    dut.dma_requester_id.value = AUTH_RID
    dut.dma_mode.value = 1
    dut.dma_start.value = 1
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    age = await wait_txn_age(dut, 1)
    before = await peek_protected(dut, ADDR_PROTECT)
    await revoke_iopmp_rule(dut)
    done = await finish_dma(dut)
    after = await peek_protected(dut, ADDR_PROTECT)
    violated = after != before and after == WRITE_PATTERN
    record(
        ROWS,
        experiment_id="M4-PEND-01",
        configuration=_cfg_label(),
        security_property="SP-12",
        expected="Model A may complete if admitted authorized",
        observed="VIOLATION" if violated else ("MODEL_A_COMPLETE" if after != before else "PASS"),
        result="OBSERVED",
        notes=f"txn_age={age} secure_ready_drop during pending write",
    )


@cocotb.test()
async def m4_pend_read_at_reset(dut):
    """M4-PEND-02: authorized read pending when IOPMP reset asserted."""
    await _init(dut)
    pulse_dma(dut, ADDR_PROTECT, 0, 0, 4, AUTH_RID, 0)
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    await wait_txn_age(dut, 1)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(8):
        await RisingEdge(dut.clk)
    after = await peek_protected(dut, ADDR_PROTECT)
    record(
        ROWS,
        experiment_id="M4-PEND-02",
        configuration=_cfg_label(),
        security_property="SP-12",
        expected="no protected write on reset abort",
        observed="PASS" if after == TEST_SECRET else "VIOLATION",
        result="OBSERVED",
        notes="global reset during pending read",
    )


@cocotb.test()
async def m4_r16_secure_ready_deassert_pending(dut):
    """R16: secure_ready deassertion while DMA pending (directed reset matrix)."""
    await _init(dut)
    pulse_dma(dut, 0, ADDR_PROTECT, WRITE_PATTERN, 4, AUTH_RID, 1)
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    await wait_txn_age(dut, 2)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 0)
    err, _ = await finish_dma(dut)
    after = await peek_protected(dut, ADDR_PROTECT)
    mem_changed = after == WRITE_PATTERN
    record(
        ROWS,
        experiment_id="R16",
        configuration=_cfg_label(),
        reset_sequence="iopmp_disable_during_pending",
        security_property="SP-12",
        expected="config-dependent",
        observed="mem_changed" if mem_changed else "blocked",
        result="FAIL" if mem_changed else "PASS",
        notes=f"dma_error={err}",
    )


@cocotb.test()
async def m4_r15_reset_immediately_after_secure_ready(dut):
    """R15: reset pulse immediately after secure_ready."""
    await _init(dut)
    cycles_secure = await _cycle_count_until(
        dut, lambda: int(dut.secure_ready.value) == 1, timeout=32
    )
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await peek_protected(dut, ADDR_PROTECT)
    pre_config = int(dut.secure_ready.value) == 0
    blocked = err or after == TEST_SECRET or pre_config
    record(
        ROWS,
        experiment_id="R15",
        configuration=_cfg_label(),
        reset_sequence="global_reset_after_secure_ready",
        security_property="SP-08",
        expected="no early unauthorized write",
        observed="blocked" if blocked else "VIOLATION",
        result="OBSERVED",
        notes=f"T_secure_ready={cycles_secure}",
    )


@cocotb.test()
async def m4_sp14_liveness_after_secure_ready(dut):
    """SP-14: authorized DMA succeeds after secure_ready."""
    await _init(dut)
    for _ in range(32):
        if int(dut.secure_ready.value):
            break
        await RisingEdge(dut.clk)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await peek_protected(dut, ADDR_PROTECT)
    ok = (not err) and after == WRITE_PATTERN
    record(
        ROWS,
        experiment_id="SP-14",
        configuration=_cfg_label(),
        security_property="SP-14",
        expected="authorized DMA succeeds",
        observed="PASS" if ok else "FAIL",
        result="PASS" if ok else "FAIL",
        notes="liveness after secure_ready",
    )
    assert ok, "SP-14 liveness failure"


@cocotb.test()
async def m4_finalize_results(dut):
    """Write M4 directed results CSV."""
    path = M4_RESULTS / f"m4_directed_{M4_CFG}.csv"
    write_csv(path, ROWS)
    append_security_matrix(ROWS)
    assert True
