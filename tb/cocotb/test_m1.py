"""Milestone M1 and baseline security experiments."""

import csv
import subprocess
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "results" / "simulation"
MATRIX = ROOT / "results" / "tables" / "security_matrix.csv"

ADDR_NORMAL   = 0x1000_0000
ADDR_PROTECT  = 0x2000_0000
ADDR_SEC_CFG  = 0x4000_0000

TEST_SECRET   = 0xDEADBEEF
WRITE_PATTERN = 0xCAFEBABE


def git_commit() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return "no-commit-yet"


async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.cpu_start.value = 0
    dut.dma_start.value = 0
    dut.cfg_write.value = 0
    dut.cfg_addr.value = 0
    dut.cfg_wdata.value = 0
    dut.prot_peek_addr.value = ADDR_PROTECT
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(2):
        await RisingEdge(dut.clk)


async def cfg_write(dut, addr, data):
    dut.cfg_write.value = 1
    dut.cfg_addr.value = addr
    dut.cfg_wdata.value = data
    await RisingEdge(dut.clk)
    dut.cfg_write.value = 0
    await RisingEdge(dut.clk)


async def seed_protected(dut, value=TEST_SECRET):
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 0)  # disable IOPMP
    dut.cpu_addr.value = ADDR_PROTECT
    dut.cpu_wdata.value = value
    dut.cpu_write.value = 1
    dut.cpu_privilege.value = 1
    dut.cpu_start.value = 1
    await RisingEdge(dut.clk)
    dut.cpu_start.value = 0
    while int(dut.cpu_done.value) == 0:
        await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def cpu_xact(dut, addr, write, wdata, privilege):
    dut.cpu_addr.value = addr
    dut.cpu_write.value = write
    dut.cpu_wdata.value = wdata
    dut.cpu_privilege.value = privilege
    dut.cpu_start.value = 1
    await RisingEdge(dut.clk)
    dut.cpu_start.value = 0
    while int(dut.cpu_done.value) == 0:
        await RisingEdge(dut.clk)
    await ReadOnly()
    await RisingEdge(dut.clk)
    return int(dut.cpu_error.value), int(dut.cpu_rdata.value)


async def dma_read(dut, addr, rid=0x02, length=4):
    dut.dma_src_addr.value = addr
    dut.dma_dst_addr.value = 0
    dut.dma_wdata.value = 0
    dut.dma_length.value = length
    dut.dma_requester_id.value = rid
    dut.dma_mode.value = 0
    dut.dma_start.value = 1
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    while int(dut.dma_done.value) == 0:
        await RisingEdge(dut.clk)
    await ReadOnly()
    await RisingEdge(dut.clk)
    return int(dut.dma_error.value), int(dut.dma_rdata.value)


async def dma_write(dut, addr, wdata, rid=0x02, length=4):
    dut.dma_src_addr.value = 0
    dut.dma_dst_addr.value = addr
    dut.dma_wdata.value = wdata
    dut.dma_length.value = length
    dut.dma_requester_id.value = rid
    dut.dma_mode.value = 1
    dut.dma_start.value = 1
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    while int(dut.dma_done.value) == 0:
        await RisingEdge(dut.clk)
    await ReadOnly()
    await RisingEdge(dut.clk)
    return int(dut.dma_error.value), int(dut.dma_rdata.value)


async def setup_pmp_only(dut):
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)  # PMP on
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 0)  # IOPMP off


async def setup_pmp_iopmp(dut, authorized_rid=0x01):
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    base = ADDR_SEC_CFG + 0x100
    await cfg_write(dut, base + 0x0, ADDR_PROTECT)
    await cfg_write(dut, base + 0x4, ADDR_PROTECT + 0xFFFF)
    await cfg_write(dut, base + 0x8, (1 << 10) | (1 << 9) | (1 << 8) | authorized_rid)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)


def record(rows, **row):
    row.setdefault("git_commit", git_commit())
    row.setdefault("seed", "directed")
    rows.append(row)


def write_matrix(rows):
    MATRIX.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "experiment_id", "configuration", "cpu_authorized", "dma_authorized",
        "requester_id", "operation", "address", "length", "policy_transition",
        "reset_sequence", "expected", "observed", "security_property",
        "result", "seed", "git_commit", "notes",
    ]
    with MATRIX.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fieldnames})


def write_m1_results(rows):
    RESULTS.mkdir(parents=True, exist_ok=True)
    out = RESULTS / "m1_results.csv"
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    summary = RESULTS / "m1_summary.md"
    passed = sum(1 for r in rows if r["result"] == "PASS")
    failed = sum(1 for r in rows if r["result"] == "FAIL")
    summary.write_text(
        "# Milestone M1 Summary\n\n"
        f"Date (UTC): generated by simulation\n"
        f"Git commit: `{git_commit()}`\n\n"
        f"Total experiments: {len(rows)}\n"
        f"PASS: {passed}\n"
        f"FAIL: {failed}\n\n"
        "## Results\n\n"
        + "\n".join(
            f"- **{r['experiment_id']}** ({r['configuration']}): "
            f"expected `{r['expected']}`, observed `{r['observed']}` → **{r['result']}**"
            for r in rows
        )
        + "\n"
    )


@cocotb.test()
async def test_m1_experiments(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    rows = []

    await reset_dut(dut)
    await seed_protected(dut, TEST_SECRET)
    before = int(dut.prot_mem_word0.value)

    # --- PMP-only configuration ---
    await setup_pmp_only(dut)

    err, _ = await cpu_xact(dut, ADDR_PROTECT, 0, 0, 0)
    obs = "BLOCKED" if err else "ALLOW"
    record(rows, experiment_id="A1", configuration="PMP-only",
           cpu_authorized=0, dma_authorized="N/A", requester_id="N/A",
           operation="cpu_read", address=hex(ADDR_PROTECT), length=4,
           expected="BLOCKED", observed=obs, security_property="SP-01",
           result="PASS" if obs == "BLOCKED" else "FAIL",
           notes="Untrusted CPU read protected SRAM")

    err, _ = await cpu_xact(dut, ADDR_PROTECT, 1, WRITE_PATTERN, 0)
    after = int(dut.prot_mem_word0.value)
    mem_unchanged = after == before
    obs = "BLOCKED" if err and mem_unchanged else "ALLOW"
    record(rows, experiment_id="A2", configuration="PMP-only",
           cpu_authorized=0, dma_authorized="N/A", requester_id="N/A",
           operation="cpu_write", address=hex(ADDR_PROTECT), length=4,
           expected="BLOCKED", observed=obs, security_property="SP-02",
           result="PASS" if obs == "BLOCKED" else "FAIL",
           notes="Untrusted CPU write protected SRAM")

    err, rdata = await dma_read(dut, ADDR_PROTECT, rid=0x02)
    obs = "BLOCKED" if err else "REACHES_MEMORY"
    record(rows, experiment_id="A3", configuration="PMP-only",
           cpu_authorized="N/A", dma_authorized=0, requester_id="0x02",
           operation="dma_read", address=hex(ADDR_PROTECT), length=4,
           expected="REACHES_MEMORY", observed=obs,
           security_property="SP-03-baseline",
           result="PASS" if obs == "REACHES_MEMORY" else "FAIL",
           notes="PMP-only system-level coverage limitation")

    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, rid=0x02)
    after_dma = int(dut.prot_mem_word0.value)
    obs = "BLOCKED" if err else "REACHES_MEMORY"
    record(rows, experiment_id="A4", configuration="PMP-only",
           cpu_authorized="N/A", dma_authorized=0, requester_id="0x02",
           operation="dma_write", address=hex(ADDR_PROTECT), length=4,
           expected="REACHES_MEMORY", observed=obs,
           security_property="SP-04-baseline",
           result="PASS" if obs == "REACHES_MEMORY" and after_dma == WRITE_PATTERN else "FAIL",
           notes="PMP-only system-level coverage limitation")

    # Restore protected memory for IOPMP tests
    await seed_protected(dut, TEST_SECRET)
    before = int(dut.prot_mem_word0.value)

    # --- PMP + IOPMP configuration ---
    await setup_pmp_iopmp(dut, authorized_rid=0x01)

    err, _ = await cpu_xact(dut, ADDR_PROTECT, 0, 0, 0)
    obs = "BLOCKED" if err else "ALLOW"
    record(rows, experiment_id="M1-CPU", configuration="PMP+IOPMP",
           cpu_authorized=0, dma_authorized="N/A", requester_id="N/A",
           operation="cpu_read", address=hex(ADDR_PROTECT), length=4,
           expected="BLOCKED", observed=obs, security_property="SP-01",
           result="PASS" if obs == "BLOCKED" else "FAIL",
           notes="M1 untrusted CPU must remain blocked")

    err, _ = await dma_read(dut, ADDR_PROTECT, rid=0x02)
    obs = "BLOCKED" if err else "ALLOW"
    record(rows, experiment_id="B2", configuration="PMP+IOPMP",
           cpu_authorized="N/A", dma_authorized=0, requester_id="0x02",
           operation="dma_read", address=hex(ADDR_PROTECT), length=4,
           expected="BLOCKED", observed=obs, security_property="SP-03",
           result="PASS" if obs == "BLOCKED" else "FAIL",
           notes="Unauthorized DMA read")

    err, _ = await dma_write(dut, ADDR_PROTECT, WRITE_PATTERN, rid=0x02)
    after = int(dut.prot_mem_word0.value)
    obs = "BLOCKED" if err and after == before else "ALLOW"
    record(rows, experiment_id="B4", configuration="PMP+IOPMP",
           cpu_authorized="N/A", dma_authorized=0, requester_id="0x02",
           operation="dma_write", address=hex(ADDR_PROTECT), length=4,
           expected="BLOCKED", observed=obs, security_property="SP-04",
           result="PASS" if obs == "BLOCKED" else "FAIL",
           notes="Unauthorized DMA write; M1 requirement")

    err, rdata = await dma_read(dut, ADDR_PROTECT, rid=0x01)
    obs = "ALLOW" if not err else "BLOCKED"
    record(rows, experiment_id="B1", configuration="PMP+IOPMP",
           cpu_authorized="N/A", dma_authorized=1, requester_id="0x01",
           operation="dma_read", address=hex(ADDR_PROTECT), length=4,
           expected="ALLOW", observed=obs, security_property="SP-03",
           result="PASS" if obs == "ALLOW" and rdata == TEST_SECRET else "FAIL",
           notes="Authorized DMA read")

    write_val = 0x12345678
    err, _ = await dma_write(dut, ADDR_PROTECT, write_val, rid=0x01)
    after = int(dut.prot_mem_word0.value)
    obs = "ALLOW" if not err and after == write_val else "BLOCKED"
    record(rows, experiment_id="B3", configuration="PMP+IOPMP",
           cpu_authorized="N/A", dma_authorized=1, requester_id="0x01",
           operation="dma_write", address=hex(ADDR_PROTECT), length=4,
           expected="ALLOW", observed=obs, security_property="SP-04",
           result="PASS" if obs == "ALLOW" else "FAIL",
           notes="Authorized DMA write")

    write_matrix(rows)
    write_m1_results(rows)

    failures = [r for r in rows if r["result"] == "FAIL"]
    assert not failures, f"M1 failures: {failures}"
