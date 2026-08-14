"""M7 multi-domain reset experiments with latency metrics."""

from __future__ import annotations

import os
import random
from dataclasses import dataclass, field

from cocotb.triggers import RisingEdge

from m4_experiment_lib import CONFIG_META, ExpResult, run_r01, run_r02
from soc_test_lib import (
    ADDR_PROTECT,
    ADDR_SEC_CFG,
    AUTH_RID,
    TEST_SECRET,
    WRITE_PATTERN,
    cfg_write,
    dma_write,
    peek_protected,
    reset_dut,
    seed_protected,
    setup_pmp_iopmp,
)

M7_CFG = os.environ.get("M7_RESET_CONFIG", "C0")


@dataclass
class M7ResetResult:
    seq_id: str
    model: str
    reset_sequence: str
    classification: str
    unsafe_reachable: str
    t_reset_assert: int = 0
    t_secure_ready: int = -1
    t_dma_enable: int = -1
    t_first_dma_accept: int = -1
    protection_init_latency: int = -1
    secure_ready_latency: int = -1
    notes: str = ""

    def as_row(self) -> dict:
        return {
            "seq_id": self.seq_id,
            "model": self.model,
            "configuration": M7_CFG,
            "reset_sequence": self.reset_sequence,
            "classification": self.classification,
            "unsafe_reachable": self.unsafe_reachable,
            "t_reset_assert": self.t_reset_assert,
            "t_secure_ready": self.t_secure_ready,
            "t_dma_enable": self.t_dma_enable,
            "t_first_dma_accept": self.t_first_dma_accept,
            "protection_init_latency": self.protection_init_latency,
            "secure_ready_latency": self.secure_ready_latency,
            "notes": self.notes,
        }


async def _cycles(dut, n: int) -> None:
    for _ in range(n):
        await RisingEdge(dut.clk)


async def _all_reset(dut) -> None:
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    dut.cpu_rst_n.value = 0
    dut.dma_rst_n.value = 0
    dut.iopmp_rst_n.value = 0
    dut.sec_rst_n.value = 0
    dut.ic_rst_n.value = 0
    dut.mem_rst_n.value = 0
    await RisingEdge(dut.clk)


async def _release(dut, **domains) -> None:
    await RisingEdge(dut.clk)
    for k, v in domains.items():
        getattr(dut, k).value = v
    await RisingEdge(dut.clk)


async def run_rst_a_r1(dut) -> M7ResetResult:
    """RST-A style: DMA before secure_ready (R1)."""
    await _all_reset(dut)
    await _release(dut, rst_n=1, mem_rst_n=1, cpu_rst_n=1, ic_rst_n=1, dma_rst_n=1, iopmp_rst_n=1, sec_rst_n=1)
    await seed_protected(dut, TEST_SECRET, restore_iopmp=False)
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await peek_protected(dut, ADDR_PROTECT)
    violated = (after == WRITE_PATTERN) and (not err)
    cls = "RESET_ASSUMPTION_DEPENDENCY" if violated and M7_CFG == "C0" else (
        "EXPECTED_BY_MODEL" if not violated else "INCONCLUSIVE"
    )
    return M7ResetResult(
        "R1", "RST-A" if M7_CFG == "C0" else "RST-B",
        "dma_active_before_secure_ready",
        cls, "YES" if violated else "NO",
        notes=f"dma_error={err}; cfg={M7_CFG}",
    )


async def run_rst_b_r2(dut) -> M7ResetResult:
    r = await run_r02(dut)
    return M7ResetResult(
        "R2", "RST-B" if M7_CFG == "C1" else "RST-A",
        r.reset_sequence, r.classification or "EXPECTED_BY_MODEL",
        "NO" if r.result == "PASS" else "YES",
        notes=r.observed,
    )


async def run_staggered_release(dut, seq_id: str, delays: dict) -> M7ResetResult:
    await _all_reset(dut)
    await _release(dut, rst_n=1, mem_rst_n=1)
    t_assert = 0
    order = ["sec_rst_n", "iopmp_rst_n", "ic_rst_n", "cpu_rst_n", "dma_rst_n"]
    t = 0
    for dom in order:
        d = delays.get(dom, 0)
        await _cycles(dut, d)
        t += d
        await _release(dut, **{dom: 1})
    await seed_protected(dut, TEST_SECRET, restore_iopmp=False)
    await setup_pmp_iopmp(dut)
    t_secure = t
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await peek_protected(dut, ADDR_PROTECT)
    violated = (after == WRITE_PATTERN) and (not err) and (M7_CFG == "C0")
    return M7ResetResult(
        seq_id, "RST-A" if M7_CFG == "C0" else "RST-B",
        f"staggered_{delays}",
        "RESET_ASSUMPTION_DEPENDENCY" if violated else "EXPECTED_BY_MODEL",
        "YES" if violated else "NO",
        t_reset_assert=t_assert,
        t_secure_ready=t_secure,
        secure_ready_latency=t_secure,
        notes=f"delays={delays}; dma_err={err}",
    )


async def run_randomized_order(dut, seed: int) -> M7ResetResult:
    await reset_dut(dut)
    dut.cpu_rst_n.value = 0
    dut.dma_rst_n.value = 0
    dut.iopmp_rst_n.value = 0
    dut.sec_rst_n.value = 0
    dut.ic_rst_n.value = 0
    dut.mem_rst_n.value = 0
    await RisingEdge(dut.clk)
    rng = random.Random(seed)
    order = ["sec_rst_n", "iopmp_rst_n", "ic_rst_n", "cpu_rst_n", "dma_rst_n"]
    rng.shuffle(order)
    delays = {dom: rng.randint(0, 4) for dom in order}
    res = await run_staggered_release(dut, f"R16-seed{seed}", delays)
    res.notes += f"; seed={seed}; order={order}"
    return res


EXPERIMENTS = {
    "R1": run_rst_a_r1,
    "R2": run_rst_b_r2,
    "R10": lambda d: run_staggered_release(d, "R10", {"iopmp_rst_n": 0, "dma_rst_n": 1}),
    "R11": lambda d: run_staggered_release(d, "R11", {"dma_rst_n": 0, "iopmp_rst_n": 1}),
}
