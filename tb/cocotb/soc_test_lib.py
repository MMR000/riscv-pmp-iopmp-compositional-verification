"""Shared cocotb helpers for M1/M2 security experiments."""

import csv
import subprocess
from pathlib import Path

from cocotb.triggers import RisingEdge, ReadOnly

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "results" / "simulation"
MATRIX = ROOT / "results" / "tables" / "security_matrix.csv"

ADDR_NORMAL = 0x1000_0000
ADDR_PROTECT = 0x2000_0000
ADDR_PROTECT_LIMIT = 0x2000_FFFF
ADDR_SEC_CFG = 0x4000_0000

TEST_SECRET = 0xDEADBEEF
WRITE_PATTERN = 0xCAFEBABE
AUTH_RID = 0x01
UNAUTH_RID = 0x02


def git_commit() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return "no-commit-yet"


async def reset_dut(dut):
    await RisingEdge(dut.clk)
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
    await RisingEdge(dut.clk)
    dut.cfg_write.value = 1
    dut.cfg_addr.value = addr
    dut.cfg_wdata.value = data
    await RisingEdge(dut.clk)
    dut.cfg_write.value = 0
    await RisingEdge(dut.clk)


async def peek_protected(dut, addr):
    await RisingEdge(dut.clk)
    dut.prot_peek_addr.value = addr
    await RisingEdge(dut.clk)
    await ReadOnly()
    try:
        return int(dut.prot_mem_word0.value)
    except ValueError:
        return 0


async def safe_peek_after(dut, addr):
    """Peek protected memory after exiting ReadOnly phase."""
    await RisingEdge(dut.clk)
    return await peek_protected(dut, addr)


async def seed_protected(dut, value=TEST_SECRET, restore_iopmp=True):
    await RisingEdge(dut.clk)
    was_iopmp = 0  # restore via restore_iopmp flag
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 0)
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
    if restore_iopmp:
        await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)


async def setup_pmp_only(dut):
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 0)


async def setup_pmp_iopmp(dut, authorized_rid=AUTH_RID):
    await cfg_write(dut, ADDR_SEC_CFG + 0x0, 1)
    base = ADDR_SEC_CFG + 0x100
    await cfg_write(dut, base + 0x0, ADDR_PROTECT)
    await cfg_write(dut, base + 0x4, ADDR_PROTECT + 0xFFFF)
    await cfg_write(dut, base + 0x8, (1 << 10) | (1 << 9) | (1 << 8) | authorized_rid)
    await cfg_write(dut, ADDR_SEC_CFG + 0x4, 1)


async def revoke_iopmp_rule(dut):
    base = ADDR_SEC_CFG + 0x100
    await cfg_write(dut, base + 0x8, 0)


async def enable_iopmp_rule(dut, rid=AUTH_RID):
    base = ADDR_SEC_CFG + 0x100
    await cfg_write(dut, base + 0x8, (1 << 10) | (1 << 9) | (1 << 8) | rid)


async def set_rule_rid(dut, rid):
    base = ADDR_SEC_CFG + 0x100
    await cfg_write(dut, base + 0x8, (1 << 10) | (1 << 9) | (1 << 8) | rid)


def pulse_cpu(dut, addr, write, wdata, privilege):
    dut.cpu_addr.value = addr
    dut.cpu_write.value = write
    dut.cpu_wdata.value = wdata
    dut.cpu_privilege.value = privilege
    dut.cpu_start.value = 1


def pulse_dma(dut, src, dst, wdata, length, rid, mode):
    dut.dma_src_addr.value = src
    dut.dma_dst_addr.value = dst
    dut.dma_wdata.value = wdata
    dut.dma_length.value = length
    dut.dma_requester_id.value = rid
    dut.dma_mode.value = mode
    dut.dma_start.value = 1


async def finish_cpu(dut):
    await RisingEdge(dut.clk)
    dut.cpu_start.value = 0
    while int(dut.cpu_done.value) == 0:
        await RisingEdge(dut.clk)
    await ReadOnly()
    await RisingEdge(dut.clk)
    return int(dut.cpu_error.value), int(dut.cpu_rdata.value)


async def finish_dma(dut):
    await RisingEdge(dut.clk)
    dut.dma_start.value = 0
    while int(dut.dma_done.value) == 0:
        await RisingEdge(dut.clk)
    await ReadOnly()
    await RisingEdge(dut.clk)
    err = int(dut.dma_error.value)
    try:
        rdata = int(dut.dma_rdata.value)
    except ValueError:
        rdata = 0
    return err, rdata


async def cpu_xact(dut, addr, write, wdata, privilege):
    await RisingEdge(dut.clk)
    pulse_cpu(dut, addr, write, wdata, privilege)
    return await finish_cpu(dut)


async def dma_read(dut, addr, rid=UNAUTH_RID, length=4):
    await RisingEdge(dut.clk)
    pulse_dma(dut, addr, 0, 0, length, rid, 0)
    return await finish_dma(dut)


async def dma_write(dut, addr, wdata, rid=UNAUTH_RID, length=4):
    await RisingEdge(dut.clk)
    pulse_dma(dut, 0, addr, wdata, length, rid, 1)
    return await finish_dma(dut)


async def wait_both_done(dut, timeout=256):
    cpu_done = dma_done = False
    for _ in range(timeout):
        await ReadOnly()
        if int(dut.cpu_done.value):
            cpu_done = True
        if int(dut.dma_done.value):
            dma_done = True
        if cpu_done and dma_done:
            await RisingEdge(dut.clk)
            return True
        await RisingEdge(dut.clk)
    return False


async def wait_dma_done(dut, timeout=128):
    for _ in range(timeout):
        if int(dut.dma_done.value):
            return True
        await RisingEdge(dut.clk)
    return False


async def wait_txn_age(dut, min_age):
    for _ in range(32):
        await RisingEdge(dut.clk)
        await ReadOnly()
        if int(dut.iopmp_txn_valid.value) and int(dut.iopmp_txn_age.value) >= min_age:
            return int(dut.iopmp_txn_age.value)
    return -1


def record(rows, **row):
    row.setdefault("git_commit", git_commit())
    row.setdefault("seed", "directed")
    rows.append(row)


def write_csv(path, rows, fieldnames=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        return
    if fieldnames is None:
        fieldnames = list(rows[0].keys())
    with path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fieldnames})


def append_security_matrix(rows, existing_path=MATRIX):
    fieldnames = [
        "experiment_id", "configuration", "cpu_authorized", "dma_authorized",
        "requester_id", "operation", "address", "length", "policy_transition",
        "reset_sequence", "expected", "observed", "security_property",
        "result", "seed", "git_commit", "notes",
    ]
    existing = []
    if existing_path.exists():
        with existing_path.open(newline="") as f:
            existing = list(csv.DictReader(f))
    write_csv(existing_path, existing + rows, fieldnames)
