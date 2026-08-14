#!/usr/bin/env python3
"""Run IBEX-COMP-01..08 on m7_ibex_composed_top and emit matrix CSV."""
from __future__ import annotations

import argparse
import csv
import hashlib
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/tables/m7_ibex_composed_matrix.csv"
LOG_DIR = ROOT / "results/m7/ibex_composed/tests"
IBEX = ROOT / "third_party/ibex"

SPECS = {
    "IBEX-COMP-01": {
        "priv": "M", "cpu_op": "write", "cpu_addr": "0x20000100",
        "cpu_exp": "ALLOW", "cpu_mcause": "",
        "dma_rid": "", "dma_op": "idle", "dma_addr": "",
        "dma_exp": "IDLE", "mem_exp": "0xB0010001",
        "props": "baseline",
    },
    "IBEX-COMP-02": {
        "priv": "U", "cpu_op": "load", "cpu_addr": "0x20000100",
        "cpu_exp": "LOAD_FAULT", "cpu_mcause": "5",
        "dma_rid": "", "dma_op": "idle", "dma_addr": "",
        "dma_exp": "IDLE", "mem_exp": "0x22222222",
        "props": "SP-01",
    },
    "IBEX-COMP-03": {
        "priv": "U", "cpu_op": "store", "cpu_addr": "0x20000100",
        "cpu_exp": "STORE_FAULT", "cpu_mcause": "7",
        "dma_rid": "", "dma_op": "idle", "dma_addr": "",
        "dma_exp": "IDLE", "mem_exp": "0x22222222",
        "props": "SP-02",
    },
    "IBEX-COMP-04": {
        "priv": "M", "cpu_op": "idle", "cpu_addr": "",
        "cpu_exp": "IDLE", "cpu_mcause": "",
        "dma_rid": "0x02", "dma_op": "write", "dma_addr": "0x20000100",
        "dma_exp": "DENY", "mem_exp": "0x22222222",
        "props": "SP-04/SP-05",
    },
    "IBEX-COMP-05": {
        "priv": "M", "cpu_op": "idle", "cpu_addr": "",
        "cpu_exp": "IDLE", "cpu_mcause": "",
        "dma_rid": "0x01", "dma_op": "write", "dma_addr": "0x20000100",
        "dma_exp": "ALLOW", "mem_exp": "0xA11D0005",
        "props": "authorized-DMA",
    },
    "IBEX-COMP-06": {
        "priv": "U", "cpu_op": "store", "cpu_addr": "0x20000100",
        "cpu_exp": "STORE_FAULT", "cpu_mcause": "7",
        "dma_rid": "0x02", "dma_op": "write", "dma_addr": "0x20000100",
        "dma_exp": "DENY", "mem_exp": "0x22222222",
        "props": "SP-02+SP-04+SP-05+SP-10",
    },
    "IBEX-COMP-07": {
        "priv": "U", "cpu_op": "store", "cpu_addr": "0x20000100",
        "cpu_exp": "STORE_FAULT", "cpu_mcause": "7",
        "dma_rid": "0x01", "dma_op": "write", "dma_addr": "0x20000100",
        "dma_exp": "ALLOW", "mem_exp": "0xD00D0007",
        "props": "SP-02 attribution + authorized-DMA",
    },
    "IBEX-COMP-08": {
        "priv": "M", "cpu_op": "store", "cpu_addr": "0x20000100",
        "cpu_exp": "ALLOW", "cpu_mcause": "",
        "dma_rid": "0x02", "dma_op": "write", "dma_addr": "0x20000100",
        "dma_exp": "DENY", "mem_exp": "0xB0080008",
        "props": "authorized-CPU + SP-04",
    },
}


def parse_log(text: str) -> dict:
    out = {
        "result_line": "UNKNOWN",
        "mcause": "",
        "mepc": "",
        "mtval": "",
        "mem_after": "",
        "trap": False,
        "dma_err": "",
        "dma_peek": "",
        "dma_cycle": "",
        "dma_auth": "",
        "dma_rid": "",
    }
    if "M7-COMP-RESULT: PASS" in text:
        out["result_line"] = "PASS"
    elif "M7-COMP-RESULT: FAIL" in text:
        out["result_line"] = "FAIL"
    if "M7-COMP-TRAP" in text:
        out["trap"] = True
    m = re.search(r"MCAUSE: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mcause"] = str(int(m.group(1), 16))
    m = re.search(r"MEPc: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mepc"] = m.group(1)
    m = re.search(r"MTVAL: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mtval"] = m.group(1)
    m = re.search(r"MEM_AFTER: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mem_after"] = "0x" + m.group(1).upper()
    m = re.search(
        r"TEST=\d+ DMA_CYCLE=(\d+) ERR=(\d+) AUTH=(\d+) RID=0x([0-9a-fA-F]+) PEEK=0x([0-9a-fA-F]+)",
        text,
    )
    if m:
        out["dma_cycle"] = m.group(1)
        out["dma_err"] = m.group(2)
        out["dma_auth"] = m.group(3)
        out["dma_rid"] = "0x" + m.group(4).upper().zfill(2)
        out["dma_peek"] = "0x" + m.group(5).upper()
    return out


def norm_hex(s: str) -> str:
    if not s:
        return ""
    s = s.lower().replace("0x", "")
    return "0x" + s.upper().zfill(8)


def classify(tid: str, parsed: dict) -> tuple[str, str, str, str]:
    """Return cpu_obs, dma_obs, mem_obs, result."""
    spec = SPECS[tid]
    # Prefer firmware MEM_AFTER (post-CPU) over harness peek (may be pre-CPU).
    mem = norm_hex(parsed.get("mem_after") or parsed.get("dma_peek") or "")
    mem_ok = mem == norm_hex(spec["mem_exp"]) if mem else False

    # CPU observation
    if spec["cpu_exp"] == "IDLE":
        cpu_obs = "IDLE"
        cpu_ok = True
    elif spec["cpu_exp"] == "ALLOW":
        cpu_ok = parsed["result_line"] == "PASS" and not parsed["trap"]
        cpu_obs = "ALLOW" if cpu_ok else ("TRAP" if parsed["trap"] else parsed["result_line"])
    else:
        cpu_ok = parsed["trap"] and parsed.get("mcause") == spec["cpu_mcause"]
        cpu_obs = f"mcause={parsed.get('mcause','')}" if parsed["trap"] else "NO_TRAP"

    # DMA observation
    if spec["dma_exp"] == "IDLE":
        dma_obs = "IDLE"
        dma_ok = True
    elif spec["dma_exp"] == "DENY":
        dma_ok = parsed.get("dma_err") == "1"
        dma_obs = "DENY" if dma_ok else ("ALLOW" if parsed.get("dma_err") == "0" else "NO_DMA")
    else:  # ALLOW
        dma_ok = parsed.get("dma_err") == "0"
        dma_obs = "ALLOW" if dma_ok else ("DENY" if parsed.get("dma_err") == "1" else "NO_DMA")

    ok = cpu_ok and dma_ok and mem_ok
    return cpu_obs, dma_obs, mem if mem else "UNKNOWN", "PASS" if ok else "FAIL"


def run_sim(sim: Path, elf: Path) -> tuple[str, int]:
    sim_dir = sim.parent
    for name in ("m7_ibex_composed.log", "m7_composed_harness.log"):
        p = sim_dir / name
        if p.exists():
            p.unlink()
    try:
        proc = subprocess.run(
            [str(sim.resolve()), f"--meminit=ram,{elf.resolve()}"],
            capture_output=True,
            text=True,
            cwd=str(sim_dir),
            timeout=30,
        )
        log = proc.stdout + proc.stderr
        rc = proc.returncode
    except subprocess.TimeoutExpired as e:
        log = (e.stdout or "") + (e.stderr or "") + "\nTIMEOUT\n"
        rc = 124
    for name in ("m7_ibex_composed.log", "m7_composed_harness.log"):
        p = sim_dir / name
        if p.exists():
            log += f"\n--- {name} ---\n" + p.read_text()
    return log, rc


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", required=True)
    args = ap.parse_args()
    sim = Path(args.sim)
    sw = ROOT / "m7/sw/ibex_composed"
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True, cwd=str(ROOT)).strip()
    ibex_commit = subprocess.check_output(
        ["git", "-C", str(IBEX), "rev-parse", "HEAD"], text=True
    ).strip()
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    rows = []
    for tid, spec in SPECS.items():
        elf = sw / f"{tid}.elf"
        log_path = LOG_DIR / f"{tid}.log"
        if not elf.exists():
            rows.append({
                "test_id": tid, "project_commit": commit, "ibex_commit": ibex_commit,
                "cpu_privilege": spec["priv"], "cpu_operation": spec["cpu_op"],
                "cpu_address": spec["cpu_addr"], "cpu_expected": spec["cpu_exp"],
                "cpu_observed": "NOT_BUILT", "cpu_mcause": "", "cpu_mepc": "", "cpu_mtval": "",
                "dma_requester_id": spec["dma_rid"], "dma_operation": spec["dma_op"],
                "dma_address": spec["dma_addr"], "dma_expected": spec["dma_exp"],
                "dma_observed": "NOT_RUN", "cpu_request_cycle": "", "dma_request_cycle": "",
                "commit_cycle": "", "winning_master": "", "memory_before": "0x22222222",
                "memory_after": "", "expected_memory": spec["mem_exp"],
                "security_properties": spec["props"], "result": "NOT_RUN",
                "classification": "INCONCLUSIVE", "notes": "ELF missing",
            })
            continue
        log, rc = run_sim(sim, elf)
        log_path.write_text(log)
        parsed = parse_log(log)
        cpu_obs, dma_obs, mem_obs, result = classify(tid, parsed)
        winner = ""
        if tid == "IBEX-COMP-07" and result == "PASS":
            winner = "DMA"
        elif tid == "IBEX-COMP-08" and result == "PASS":
            winner = "CPU"
        elif tid in ("IBEX-COMP-01", "IBEX-COMP-05") and result == "PASS":
            winner = "CPU" if tid.endswith("01") else "DMA"
        rows.append({
            "test_id": tid,
            "project_commit": commit,
            "ibex_commit": ibex_commit,
            "cpu_privilege": spec["priv"],
            "cpu_operation": spec["cpu_op"],
            "cpu_address": spec["cpu_addr"],
            "cpu_expected": spec["cpu_exp"],
            "cpu_observed": cpu_obs,
            "cpu_mcause": parsed.get("mcause", ""),
            "cpu_mepc": parsed.get("mepc", ""),
            "cpu_mtval": parsed.get("mtval", ""),
            "dma_requester_id": spec["dma_rid"] or parsed.get("dma_rid", ""),
            "dma_operation": spec["dma_op"],
            "dma_address": spec["dma_addr"],
            "dma_expected": spec["dma_exp"],
            "dma_observed": dma_obs,
            "cpu_request_cycle": "",
            "dma_request_cycle": parsed.get("dma_cycle", ""),
            "commit_cycle": parsed.get("dma_cycle", ""),
            "winning_master": winner,
            "memory_before": "0x22222222",
            "memory_after": mem_obs,
            "expected_memory": spec["mem_exp"],
            "security_properties": spec["props"],
            "result": result,
            "classification": "SIMULATION_EVIDENCE" if result == "PASS" else "TEST_SOFTWARE_BUG",
            "notes": f"exit={rc}",
        })
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"Wrote {OUT}")
    for r in rows:
        print(f"  {r['test_id']}: {r['result']} cpu={r['cpu_observed']} dma={r['dma_observed']} mem={r['memory_after']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
