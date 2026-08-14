#!/usr/bin/env python3
"""Run IBEX-PMP-01..08 on Vibex_simple_system and emit m7_ibex_pmp_matrix.csv."""
from __future__ import annotations

import argparse
import csv
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/tables/m7_ibex_pmp_matrix.csv"
LOG_DIR = ROOT / "results/m7/ibex/tests"
IBEX = ROOT / "third_party/ibex"

SPECS = {
    "IBEX-PMP-01": {"priv": "M", "op": "write", "addr": "0x00101100", "expected": "ALLOW", "mcause": ""},
    "IBEX-PMP-02": {"priv": "M", "op": "read", "addr": "0x00101100", "expected": "ALLOW", "mcause": ""},
    "IBEX-PMP-03": {"priv": "M", "op": "csr_setup", "addr": "pmpcfg", "expected": "ALLOW", "mcause": ""},
    "IBEX-PMP-04": {"priv": "U", "op": "load", "addr": "0x00180100", "expected": "LOAD_FAULT", "mcause": "5"},
    "IBEX-PMP-05": {"priv": "U", "op": "store", "addr": "0x00180100", "expected": "STORE_FAULT", "mcause": "7"},
    "IBEX-PMP-06": {"priv": "U", "op": "load", "addr": "0x00101100", "expected": "ALLOW", "mcause": ""},
    "IBEX-PMP-07": {"priv": "U", "op": "load_boundary", "addr": "prot_last", "expected": "LOAD_FAULT", "mcause": "5"},
    "IBEX-PMP-08": {"priv": "M", "op": "write_reconfig", "addr": "0x00180100", "expected": "ALLOW", "mcause": ""},
}


def parse_log(text: str) -> dict:
    out = {"result": "UNKNOWN", "mcause": "", "mepc": "", "mtval": "", "mem_after": ""}
    if "M7-RESULT: PASS" in text:
        out["result"] = "PASS"
    elif "M7-RESULT: FAIL" in text:
        out["result"] = "FAIL"
    if "M7-TRAP" in text:
        out["observed"] = "TRAP"
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
        out["mem_after"] = m.group(1)
    return out


def classify(tid: str, parsed: dict) -> tuple[str, str]:
    spec = SPECS[tid]
    exp = spec["expected"]
    if exp == "ALLOW":
        ok = parsed.get("result") == "PASS"
        return ("PASS" if ok else "FAIL", "ALLOW" if ok else parsed.get("result", "UNKNOWN"))
    if exp in ("LOAD_FAULT", "STORE_FAULT"):
        mcause = parsed.get("mcause", "")
        ok = parsed.get("observed") == "TRAP" and mcause == spec["mcause"]
        if tid == "IBEX-PMP-05" and parsed.get("mem_after") not in ("22222222", "0x22222222", ""):
            ok = False
        return ("PASS" if ok else "FAIL", f"mcause={mcause}" if mcause else "NO_TRAP")
    return ("FAIL", "UNCLASSIFIED")


def run_sim(sim: Path, elf: Path) -> tuple[str, int]:
    sim_dir = sim.parent
    log_file = sim_dir / "ibex_simple_system.log"
    if log_file.exists():
        log_file.unlink()
    proc = subprocess.run(
        [str(sim.resolve()), f"--meminit=ram,{elf.resolve()}"],
        capture_output=True,
        text=True,
        cwd=str(sim_dir),
    )
    sim_log = proc.stdout + proc.stderr
    if log_file.exists():
        sim_log += "\n--- ibex_simple_system.log ---\n"
        sim_log += log_file.read_text()
    return sim_log, proc.returncode


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", required=True)
    ap.add_argument("--gcc", default="riscv-none-elf-gcc")
    ap.add_argument("--arch", default="rv32imc_zicsr")
    args = ap.parse_args()
    sim = Path(args.sim)
    sw = ROOT / "m7/sw/ibex_pmp"
    commit = subprocess.check_output(["git", "-C", str(IBEX), "rev-parse", "HEAD"], text=True).strip()
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    rows = []
    for tid in SPECS:
        elf = sw / f"{tid}.elf"
        log_path = LOG_DIR / f"{tid}.log"
        if not elf.exists():
            rows.append({
                "test_id": tid, "ibex_commit": commit, "pmp_enable": "1", "pmp_regions": "8",
                "privilege": SPECS[tid]["priv"], "operation": SPECS[tid]["op"],
                "address": SPECS[tid]["addr"], "expected": SPECS[tid]["expected"],
                "observed": "NOT_BUILT", "mcause": "", "mepc": "", "mtval": "",
                "memory_before": "", "memory_after": "", "result": "NOT_RUN",
                "notes": "ELF missing",
            })
            continue
        log, exit_code = run_sim(sim, elf)
        log_path.write_text(log)
        parsed = parse_log(log)
        result, observed = classify(tid, parsed)
        rows.append({
            "test_id": tid,
            "ibex_commit": commit,
            "pmp_enable": "1",
            "pmp_regions": "8",
            "privilege": SPECS[tid]["priv"],
            "operation": SPECS[tid]["op"],
            "address": SPECS[tid]["addr"],
            "expected": SPECS[tid]["expected"],
            "observed": observed,
            "mcause": parsed.get("mcause", ""),
            "mepc": parsed.get("mepc", ""),
            "mtval": parsed.get("mtval", ""),
            "memory_before": "0x22222222" if tid == "IBEX-PMP-05" else "",
            "memory_after": parsed.get("mem_after", ""),
            "result": result,
            "notes": f"exit={exit_code}",
        })
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"Wrote {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
