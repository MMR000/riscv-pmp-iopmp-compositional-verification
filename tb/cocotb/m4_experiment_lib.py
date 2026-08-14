"""M4 directed reset experiment library (R1–R16)."""

from __future__ import annotations

import os
from dataclasses import dataclass, field

from cocotb.triggers import RisingEdge

from soc_test_lib import (
    ADDR_PROTECT,
    ADDR_SEC_CFG,
    AUTH_RID,
    TEST_SECRET,
    UNAUTH_RID,
    WRITE_PATTERN,
    cfg_write,
    dma_read,
    dma_write,
    finish_dma,
    peek_protected,
    pulse_dma,
    reset_dut,
    revoke_iopmp_rule,
    seed_protected,
    setup_pmp_iopmp,
    setup_pmp_only,
    wait_txn_age,
)

M4_CFG = os.environ.get("M4_CONFIG", "C0")

CONFIG_META = {
    "C0": ("fail-open", "no", "no"),
    "C1": ("fail-closed", "no", "no"),
    "C2": ("fail-open", "yes", "no"),
    "C3": ("fail-open", "yes", "epoch"),
    "C4": ("fail-closed", "yes", "no"),
}


@dataclass
class ExpResult:
    experiment_id: str
    scenario: str
    configuration: str = M4_CFG
    initial_state: str = ""
    reset_sequence: str = ""
    expected: str = ""
    observed: str = ""
    property_ids: str = ""
    result: str = "OBSERVED"
    classification: str = ""
    waveform: str = ""
    notes: str = ""
    reset_default: str = field(init=False)
    admission_gate: str = field(init=False)
    commit_epoch: str = field(init=False)

    def __post_init__(self):
        rd, ag, ce = CONFIG_META.get(self.configuration, ("", "", ""))
        self.reset_default = rd
        self.admission_gate = ag
        self.commit_epoch = ce

    def as_row(self) -> dict:
        return {
            "experiment_id": self.experiment_id,
            "scenario": self.scenario,
            "configuration": self.configuration,
            "reset_default": self.reset_default,
            "admission_gate": self.admission_gate,
            "commit_epoch": self.commit_epoch,
            "initial_state": self.initial_state,
            "reset_sequence": self.reset_sequence,
            "expected": self.expected,
            "observed": self.observed,
            "property_ids": self.property_ids,
            "result": self.result,
            "classification": self.classification,
            "waveform": self.waveform,
            "notes": self.notes,
        }


async def _secure(dut) -> bool:
    await RisingEdge(dut.clk)
    try:
        return int(dut.secure_ready.value) == 1
    except ValueError:
        return False


async def _prot_val(dut, addr=ADDR_PROTECT) -> int:
    val = await peek_protected(dut, addr)
    await RisingEdge(dut.clk)
    return val


async def run_r01(dut) -> ExpResult:
    """R1: DMA active before security enforcement configured."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET, restore_iopmp=False)
    # IOPMP block powered/enabled but no valid rule / secure_ready yet.
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await _prot_val(dut)
    violated = (after == WRITE_PATTERN) and (not err) and (not await _secure(dut))
    obs = "VIOLATION" if violated else ("blocked" if after == TEST_SECRET else "other")
    cls = "RESET_ASSUMPTION_DEPENDENCY" if violated and M4_CFG == "C0" else (
        "EXPECTED_BY_MODEL" if not violated else "GENUINE_PROPERTY_COUNTEREXAMPLE"
    )
    return ExpResult(
        "R1", "DMA recovers before IOPMP/security configured",
        initial_state="post_reset_iopmp_enabled_unconfigured", reset_sequence="none",
        expected="no protected write before secure_ready",
        observed=obs, property_ids="SP-08,SP-13",
        result="FAIL" if violated else "PASS", classification=cls,
        notes=f"dma_error={err}; iopmp enabled, rule invalid",
    )


async def run_r02(dut) -> ExpResult:
    """R2: IOPMP/security ready before DMA."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await _prot_val(dut)
    ok = (not err) and after == WRITE_PATTERN
    return ExpResult(
        "R2", "IOPMP recovers before DMA",
        reset_sequence="config_then_dma",
        expected="authorized DMA succeeds after secure_ready",
        observed="PASS" if ok else "FAIL", property_ids="SP-14",
        result="PASS" if ok else "FAIL", classification="EXPECTED_BY_MODEL",
    )


async def run_r03(dut) -> ExpResult:
    """R3: Security configuration completes last."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET, restore_iopmp=False)
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)
    err1, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    await setup_pmp_iopmp(dut)
    err2, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN + 1, AUTH_RID)
    after = await _prot_val(dut)
    pre_viol = after == WRITE_PATTERN and err1 == 0
    return ExpResult(
        "R3", "Security configuration recovers last",
        reset_sequence="pmp_iopmp_on_rule_delayed",
        expected="pre-ready blocked; post-ready allowed",
        observed=f"pre={'VIOLATION' if pre_viol else 'blocked'};post={'ok' if after == WRITE_PATTERN + 1 else 'fail'}",
        property_ids="SP-08,SP-13,SP-14",
        result="FAIL" if pre_viol else "PASS",
        classification="RESET_ASSUMPTION_DEPENDENCY" if pre_viol and M4_CFG == "C0" else "EXPECTED_BY_MODEL",
        notes=f"err_pre={err1} err_post={err2}",
    )


async def run_r04(dut) -> ExpResult:
    """R4: DMA operational last."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    for _ in range(4):
        await RisingEdge(dut.clk)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    ok = (not err) and await _secure(dut)
    return ExpResult(
        "R4", "DMA recovers last", reset_sequence="secure_ready_then_dma",
        expected="liveness once secure_ready stable",
        observed="PASS" if ok else "FAIL", property_ids="SP-14",
        result="PASS" if ok else "FAIL",
    )


async def run_r05(dut) -> ExpResult:
    """R5: CPU activity during reset recovery (DMA path configured)."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    dut.cpu_addr.value = ADDR_PROTECT
    dut.cpu_wdata.value = WRITE_PATTERN
    dut.cpu_write.value = 1
    dut.cpu_privilege.value = 0
    dut.cpu_start.value = 1
    await RisingEdge(dut.clk)
    dut.cpu_start.value = 0
    while int(dut.cpu_done.value) == 0:
        await RisingEdge(dut.clk)
    err, _ = await dma_write(dut, ADDR_PROTECT, 0xA5A5A5A5, AUTH_RID)
    after = await _prot_val(dut)
    cpu_blocked = after != WRITE_PATTERN
    return ExpResult(
        "R5", "CPU-only reset recovery stress",
        reset_sequence="unprivileged_cpu_then_dma",
        expected="unauth CPU blocked; DMA unaffected",
        observed=f"cpu_blocked={cpu_blocked} dma_err={err}",
        property_ids="SP-02,SP-14", result="PASS" if cpu_blocked else "FAIL",
        notes="single global rst_n model; CPU transaction not reset-isolated",
    )


async def run_r06(dut) -> ExpResult:
    """R6: Reset during DMA request (pending cleared)."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    pulse_dma(dut, 0, ADDR_PROTECT, WRITE_PATTERN, 4, AUTH_RID, 1)
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    await wait_txn_age(dut, 1)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(16):
        await RisingEdge(dut.clk)
    after = await _prot_val(dut)
    return ExpResult(
        "R6", "DMA-only reset (global rst during DMA)",
        reset_sequence="global_reset_during_pending",
        expected="pending cleared; no orphan commit",
        observed="PASS" if after == TEST_SECRET else "VIOLATION",
        property_ids="SP-12", result="PASS" if after == TEST_SECRET else "FAIL",
    )


async def run_r07(dut) -> ExpResult:
    """R7: IOPMP logical reset via disable."""
    if M4_CFG in ("C1", "C4"):
        return ExpResult(
            "R7", "IOPMP-only reset (iopmp_enable=0)",
            reset_sequence="iopmp_disable",
            expected="N/A when enable=0 bypasses IOPMP block",
            observed="N/A", property_ids="SP-08,SP-13",
            result="N/A", classification="EXPECTED_MODEL_DIFFERENCE",
            notes="fail-closed applies inside enabled IOPMP; enable=0 bypass documented",
        )
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 0)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await _prot_val(dut)
    violated = after == WRITE_PATTERN and M4_CFG in ("C0", "C2", "C3")
    return ExpResult(
        "R7", "IOPMP-only reset (iopmp_enable=0)",
        reset_sequence="iopmp_disable",
        expected="fail-open may bypass; fail-closed denies",
        observed="VIOLATION" if violated else "blocked",
        property_ids="SP-08,SP-13",
        result="FAIL" if violated else "PASS",
        classification="RESET_ASSUMPTION_DEPENDENCY" if violated else "EXPECTED_BY_MODEL",
        notes=f"err={err}",
    )


async def run_r08(dut) -> ExpResult:
    """R8: Security-config invalidation."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    await revoke_iopmp_rule(dut)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await _prot_val(dut)
    blocked = after == TEST_SECRET or err
    return ExpResult(
        "R8", "Security-config-only invalidation",
        reset_sequence="rule0_valid_clear",
        expected="protected DMA denied without valid rule",
        observed="blocked" if blocked else "VIOLATION",
        property_ids="SP-11,SP-13", result="PASS" if blocked else "FAIL",
    )


async def run_r09(dut) -> ExpResult:
    """R9: Reset during authorized DMA."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    pulse_dma(dut, 0, ADDR_PROTECT, WRITE_PATTERN, 4, AUTH_RID, 1)
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    await wait_txn_age(dut, 1)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await setup_pmp_iopmp(dut)
    after = await _prot_val(dut)
    return ExpResult(
        "R9", "Reset during authorized DMA",
        reset_sequence="reset_mid_transaction_reconfig",
        expected="no orphan unauthorized commit",
        observed="PASS" if after == TEST_SECRET else "mem_changed",
        property_ids="SP-12", result="PASS" if after == TEST_SECRET else "FAIL",
    )


async def run_r10(dut) -> ExpResult:
    """R10: Reset during denied DMA."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    err1, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, UNAUTH_RID)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await setup_pmp_iopmp(dut)
    err2, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, UNAUTH_RID)
    after = await _prot_val(dut)
    return ExpResult(
        "R10", "Reset during denied DMA",
        reset_sequence="deny_then_reset",
        expected="denied cannot become accepted via reset",
        observed="PASS" if after == TEST_SECRET else "VIOLATION",
        property_ids="SP-11,SP-13", result="PASS" if after == TEST_SECRET else "FAIL",
        notes=f"err_pre={err1} err_post={err2}",
    )


async def run_r11(dut) -> ExpResult:
    """R11: Reset during pending DMA write."""
    res = await run_r06(dut)
    res.experiment_id = "R11"
    res.scenario = "Reset during pending DMA write"
    return res


async def run_r12(dut) -> ExpResult:
    """R12: ALLOW→DENY during pending (Model A)."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    pulse_dma(dut, 0, ADDR_PROTECT, WRITE_PATTERN, 4, AUTH_RID, 1)
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    await wait_txn_age(dut, 2)
    await revoke_iopmp_rule(dut)
    err, _ = await finish_dma(dut)
    after = await _prot_val(dut)
    completed = after == WRITE_PATTERN
    return ExpResult(
        "R12", "Reset/policy ALLOW→DENY during pending",
        reset_sequence="revoke_during_pending",
        expected="Model A may complete authorized pending txn",
        observed="MODEL_A_COMPLETE" if completed else "blocked",
        property_ids="SP-12A",
        result="OBSERVED",
        classification="EXPECTED_MODEL_DIFFERENCE" if completed else "EXPECTED_BY_MODEL",
        notes=f"err={err}",
    )


async def run_r13(dut) -> ExpResult:
    """R13: Repeated reset pulses."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET, restore_iopmp=False)
    for _ in range(2):
        await RisingEdge(dut.clk)
        dut.rst_n.value = 0
        await RisingEdge(dut.clk)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await _prot_val(dut)
    violated = (after == WRITE_PATTERN) and (not err) and (not await _secure(dut))
    return ExpResult(
        "R13", "Repeated reset pulses",
        reset_sequence="double_reset",
        expected="no permissive window",
        observed="VIOLATION" if violated else "blocked",
        property_ids="SP-08,SP-13",
        result="FAIL" if violated else "PASS",
        classification="RESET_ASSUMPTION_DEPENDENCY" if violated and M4_CFG == "C0" else (
            "EXPECTED_BY_MODEL" if not violated else "GENUINE_PROPERTY_COUNTEREXAMPLE"
        ),
        notes=f"err={err}; iopmp enabled post-reset",
    )


async def run_r14(dut) -> ExpResult:
    """R14: Warm reset — config invalidation without hardware reset."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    await revoke_iopmp_rule(dut)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await _prot_val(dut)
    violated = after == WRITE_PATTERN
    return ExpResult(
        "R14", "Warm reset (config loss; sec/iopmp domains stay powered)",
        reset_sequence="rule_invalidation_no_rst_n",
        expected="protected access blocked",
        observed="VIOLATION" if violated else "blocked",
        property_ids="SP-13", result="FAIL" if violated else "PASS",
        classification="EXPECTED_BY_MODEL" if not violated else "GENUINE_PROPERTY_COUNTEREXAMPLE",
        notes="domains: rule0_valid cleared; iopmp_enable remains set",
    )


async def run_r15(dut) -> ExpResult:
    """R15: Reset immediately after secure_ready."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    for _ in range(32):
        if await _secure(dut):
            break
        await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, AUTH_RID)
    after = await _prot_val(dut)
    blocked = after == TEST_SECRET or err or not await _secure(dut)
    return ExpResult(
        "R15", "Reset immediately after secure_ready",
        reset_sequence="reset_after_secure_ready",
        expected="no early unauthorized write",
        observed="blocked" if blocked else "VIOLATION",
        property_ids="SP-08", result="PASS" if blocked else "FAIL",
    )


async def run_r16(dut) -> ExpResult:
    """R16: secure_ready deasserts with pending DMA."""
    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    await setup_pmp_iopmp(dut)
    pulse_dma(dut, 0, ADDR_PROTECT, WRITE_PATTERN, 4, AUTH_RID, 1)
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    await wait_txn_age(dut, 2)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 0)
    err, _ = await finish_dma(dut)
    after = await _prot_val(dut)
    mem_changed = after == WRITE_PATTERN
    return ExpResult(
        "R16", "secure_ready deasserts with pending DMA",
        reset_sequence="iopmp_disable_during_pending",
        expected="config-dependent (Model A vs epoch)",
        observed="mem_changed" if mem_changed else "blocked",
        property_ids="SP-12A,SP-12B",
        result="OBSERVED",
        classification="EXPECTED_MODEL_DIFFERENCE" if mem_changed else "EXPECTED_BY_MODEL",
        notes=f"err={err} cfg={M4_CFG}",
    )


EXPERIMENTS = {
    "R01": run_r01, "R02": run_r02, "R03": run_r03, "R04": run_r04,
    "R05": run_r05, "R06": run_r06, "R07": run_r07, "R08": run_r08,
    "R09": run_r09, "R10": run_r10, "R11": run_r11, "R12": run_r12,
    "R13": run_r13, "R14": run_r14, "R15": run_r15, "R16": run_r16,
}

WAVEFORM_SCENARIOS = {
    ("C0", "R01"), ("C1", "R01"), ("C0", "R03"), ("C1", "R03"), ("C2", "R03"),
    ("C1", "R09"), ("C1", "R11"), ("C0", "R16"), ("C1", "R16"), ("C3", "R16"),
}
