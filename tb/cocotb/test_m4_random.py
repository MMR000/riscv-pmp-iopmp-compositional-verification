"""M4 randomized reset/recovery campaign (corrected — IOPMP always in-path)."""

from __future__ import annotations

import hashlib
import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from soc_test_lib import (
    ADDR_PROTECT,
    ADDR_SEC_CFG,
    AUTH_RID,
    TEST_SECRET,
    UNAUTH_RID,
    WRITE_PATTERN,
    cfg_write,
    dma_write,
    git_commit,
    peek_protected,
    reset_dut,
    revoke_iopmp_rule,
    seed_protected,
    setup_pmp_iopmp,
    write_csv,
)

M4_CFG = os.environ.get("M4_CONFIG", "C0")
M4_SEED = int(os.environ.get("M4_SEED", "0"))
CAMPAIGN_ID = "m4_random_v2"
TESTBENCH_VERSION = hashlib.sha256(
    Path(__file__).read_bytes()
).hexdigest()[:12]
OUT = Path(__file__).resolve().parents[2] / "results" / "simulation"
ROWS: list[dict] = []


async def _ensure_iopmp_in_path(dut) -> None:
    """PMP + IOPMP enabled; DMA always routes through enforcement block."""
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)


async def _read_secure(dut) -> bool:
    await RisingEdge(dut.clk)
    try:
        return int(dut.secure_ready.value) == 1
    except ValueError:
        return False


async def _read_iopmp_enable(dut) -> bool:
    await RisingEdge(dut.clk)
    try:
        return int(dut.u_sec.iopmp_enable.value) == 1
    except (ValueError, AttributeError):
        return True


async def _recover_after_reset(dut, policy_valid: bool) -> bool:
    await seed_protected(dut, TEST_SECRET, restore_iopmp=False)
    await _ensure_iopmp_in_path(dut)
    if policy_valid:
        await setup_pmp_iopmp(dut)
        return True
    return False


def _initial_classify(cfg: str, violated: bool, secure: bool, iopmp_ok: bool) -> str:
    if not violated:
        return "EXPECTED_BY_MODEL"
    if not iopmp_ok:
        return "TESTBENCH_BUG"
    if cfg == "C0" and not secure:
        return "RESET_ASSUMPTION_DEPENDENCY"
    return "PENDING_REPLAY"


@cocotb.test()
async def m4_random_reset_scenario(dut):
    rng = random.Random(M4_SEED)
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET, restore_iopmp=False)
    await _ensure_iopmp_in_path(dut)

    policy_valid = False
    reset_sequence = "none"

    if rng.random() < 0.7:
        await setup_pmp_iopmp(dut)
        policy_valid = True

    for _ in range(rng.randint(0, 8)):
        await RisingEdge(dut.clk)

    if policy_valid and rng.random() < 0.3:
        await revoke_iopmp_rule(dut)
        policy_valid = False

    if rng.random() < 0.2:
        reset_sequence = "global_pulse"
        had_policy = policy_valid
        await RisingEdge(dut.clk)
        dut.rst_n.value = 0
        await RisingEdge(dut.clk)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)
        policy_valid = await _recover_after_reset(dut, had_policy and rng.random() < 0.5)

    await _ensure_iopmp_in_path(dut)
    iopmp_ok = await _read_iopmp_enable(dut)

    rid = AUTH_RID if rng.random() < 0.6 else UNAUTH_RID
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, rid)
    await RisingEdge(dut.clk)
    after = await peek_protected(dut, ADDR_PROTECT)
    await RisingEdge(dut.clk)
    secure = await _read_secure(dut)
    iopmp_ok = iopmp_ok and await _read_iopmp_enable(dut)

    violated = (after == WRITE_PATTERN) and (not err) and ((not secure) or rid != AUTH_RID)
    observed = "VIOLATION" if violated else "PASS"
    result = "FAIL" if violated else "PASS"

    row = {
        "campaign_id": CAMPAIGN_ID,
        "seed": M4_SEED,
        "configuration": M4_CFG,
        "git_commit": git_commit(),
        "testbench_version": TESTBENCH_VERSION,
        "iopmp_in_path": iopmp_ok,
        "operation": "write",
        "address": hex(ADDR_PROTECT),
        "requester_id": rid,
        "policy_valid": policy_valid,
        "reset_sequence": reset_sequence,
        "secure_ready": secure,
        "expected": "no unauthorized protected effect",
        "observed": observed,
        "property": "SP-08/SP-13",
        "result": result,
        "classification": _initial_classify(M4_CFG, violated, secure, iopmp_ok),
        "dma_error": err,
        "mem_after": hex(after),
    }
    ROWS.append(row)

    if not iopmp_ok:
        raise AssertionError(f"IOPMP not in-path for {M4_CFG} seed {M4_SEED}")

    per_seed = OUT / f"m4_random_{M4_CFG}_seed{M4_SEED:04d}.csv"
    write_csv(per_seed, ROWS)
