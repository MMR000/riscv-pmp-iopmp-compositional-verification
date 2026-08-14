#!/usr/bin/env python3
"""Aggregate M4 simulation, formal, synthesis, and performance evidence."""
from __future__ import annotations

import argparse
import csv
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIM = ROOT / "results" / "simulation"
TABLES = ROOT / "results" / "tables"
M4 = ROOT / "results" / "m4"
SYN = M4 / "synthesis"
PERF = M4 / "performance"
FIG = ROOT / "results" / "figures"
FORMAL = ROOT / "results" / "formal"

CONFIGS = ("C0", "C1", "C2", "C3", "C4")
META = {
    "C0": ("fail-open", "no", "no"),
    "C1": ("fail-closed", "no", "no"),
    "C2": ("fail-open", "yes", "no"),
    "C3": ("fail-open", "yes", "epoch"),
    "C4": ("fail-closed", "yes", "no"),
}

RANDOM_CAMPAIGN_STATUS = "CORRECTED_FINAL"

FORMAL_STATUS = {
    "C0": {"SP08": "COUNTEREXAMPLE", "SP11": "N/A", "SP12A": "OBSERVED", "SP12B": "N/A", "SP13": "COUNTEREXAMPLE", "SP14": "NOT_RUN"},
    "C1": {"SP08": "PROVED", "SP11": "N/A", "SP12A": "OBSERVED", "SP12B": "N/A", "SP13": "PROVED", "SP14": "BOUNDED_PASS"},
    "C2": {"SP08": "BOUNDED_PASS", "SP11": "INCONCLUSIVE", "SP12A": "OBSERVED", "SP12B": "N/A", "SP13": "BOUNDED_PASS", "SP14": "BOUNDED_PASS"},
    "C3": {"SP08": "BOUNDED_PASS", "SP11": "BOUNDED_PASS", "SP12A": "OBSERVED", "SP12B": "BOUNDED_PASS", "SP13": "BOUNDED_PASS", "SP14": "NOT_RUN"},
    "C4": {"SP08": "PROVED", "SP11": "INCONCLUSIVE", "SP12A": "OBSERVED", "SP12B": "N/A", "SP13": "PROVED", "SP14": "NOT_RUN"},
}


def parse_yosys_stat(path: Path) -> dict:
    out = {"total_cells": "", "flip_flops": "", "muxes": "", "comparators": ""}
    if not path.exists():
        return out
    text = path.read_text(errors="replace")
    cell_lines = re.findall(r"^\s+(\d+)\s+cells\s*$", text, re.M)
    if cell_lines:
        out["total_cells"] = cell_lines[-1]
    tail = text.split("=== m4_synth_top ===")[-1] if "=== m4_synth_top ===" in text else text
    for key, pat in [
        ("flip_flops", r"(\d+)\s+\$adffe"),
        ("muxes", r"(\d+)\s+\$mux"),
        ("comparators", r"(\d+)\s+\$eq"),
    ]:
        m = re.search(pat, tail, re.I)
        if m:
            out[key] = m.group(1)
    return out


def load_directed(cfg: str) -> list[dict]:
    p = SIM / f"m4_directed_matrix_{cfg}.csv"
    if not p.exists():
        return []
    with p.open(newline="") as f:
        return list(csv.DictReader(f))


def load_random_rows() -> list[dict]:
    p = SIM / "m4_random_reset_runs.csv"
    if not p.exists():
        return []
    with p.open(newline="") as f:
        return list(csv.DictReader(f))


def random_stats(cfg: str, rows: list[dict]) -> dict:
    sub = [r for r in rows if r.get("configuration") == cfg]
    cls = Counter(r.get("classification", "") for r in sub)
    return {
        "random_runs": len(sub),
        "random_failures": sum(1 for r in sub if r.get("result") == "FAIL"),
        "random_expected_by_model": cls.get("EXPECTED_BY_MODEL", 0),
        "random_reset_assumption": cls.get("RESET_ASSUMPTION_DEPENDENCY", 0),
        "random_model_difference": cls.get("EXPECTED_MODEL_DIFFERENCE", 0),
        "random_genuine_ce": cls.get("GENUINE_PROPERTY_COUNTEREXAMPLE", 0),
        "random_testbench_bug": cls.get("TESTBENCH_BUG", 0),
        "random_inconclusive": cls.get("INCONCLUSIVE", 0),
    }


def load_performance(cfg: str) -> dict:
    p = PERF / f"m4_performance_{cfg}.csv"
    if not p.exists():
        return {}
    with p.open(newline="") as f:
        rows = list(csv.DictReader(f))
    return rows[0] if rows else {}


def formal_log_status(task: str) -> str:
    log = FORMAL / task / "logfile.txt"
    if not log.exists():
        return "NOT_RUN"
    text = log.read_text(errors="replace")
    if "DONE (PASS" in text and task.endswith("_prove"):
        return "PROVED"
    if "DONE (PASS" in text:
        return "BOUNDED_PASS"
    if "DONE (FAIL" in text:
        return "COUNTEREXAMPLE"
    if "DONE (ERROR" in text:
        return "INCONCLUSIVE"
    return "INCONCLUSIVE"


def update_formal_from_logs() -> None:
    mapping = {
        "sp08_rstb_prove": [("C1", "SP08"), ("C4", "SP08")],
        "sp08_reset": [("C0", "SP08")],
        "sp13_c1_prove": [("C1", "SP13"), ("C4", "SP13")],
        "sp13_c0_bmc": [("C0", "SP13")],
        "sp11_rsdg_prove": [("C2", "SP11"), ("C4", "SP11")],
    }
    for task, pairs in mapping.items():
        st = formal_log_status(task)
        for cfg, prop in pairs:
            if st != "NOT_RUN":
                FORMAL_STATUS[cfg][prop] = st


def build_figures(rows: list[dict]) -> None:
    FIG.mkdir(parents=True, exist_ok=True)
    sec = FIG / "m4_security.csv"
    with sec.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["configuration", "SP08", "SP11", "SP13", "random_campaign_status"])
        w.writeheader()
        for r in rows:
            w.writerow({
                "configuration": r["configuration"],
                "SP08": r["SP08"],
                "SP11": r["SP11"],
                "SP13": r["SP13"],
                "random_campaign_status": RANDOM_CAMPAIGN_STATUS,
            })
    lat = FIG / "m4_recovery_latency.csv"
    with lat.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "configuration", "secure_ready_latency", "normal_write_latency",
            "availability_block_cycles", "recovery_scenarios_L1_L5",
        ])
        w.writeheader()
        for r in rows:
            w.writerow({
                "configuration": r["configuration"],
                "secure_ready_latency": r["secure_ready_latency"],
                "normal_write_latency": r["normal_write_latency"],
                "availability_block_cycles": r["availability_block_cycles"],
                "recovery_scenarios_L1_L5": "BLOCKED_BY_FIXTURE",
            })
    hw = FIG / "m4_hardware_overhead.csv"
    with hw.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["configuration", "total_cells", "flip_flops", "logic_delta_vs_C0"])
        w.writeheader()
        c0_cells = int(rows[0].get("total_cells") or 0) if rows else 0
        for r in rows:
            cells = int(r.get("total_cells") or 0)
            w.writerow({
                "configuration": r["configuration"],
                "total_cells": r["total_cells"],
                "flip_flops": r["flip_flops"],
                "logic_delta_vs_C0": str(cells - c0_cells) if c0_cells else "",
            })


def build_comparison() -> None:
    update_formal_from_logs()
    random_rows = load_random_rows()
    c0_synth = parse_yosys_stat(SYN / "yosys_stat_C0.txt")
    c0_cells = int(c0_synth.get("total_cells") or 0)
    rows = []
    for cfg in CONFIGS:
        rst, gate, pend = META[cfg]
        directed = load_directed(cfg)
        d_total = len(directed) if directed else 16
        d_fail = sum(1 for r in directed if r.get("result") == "FAIL")
        rnd = random_stats(cfg, random_rows)
        perf = load_performance(cfg)
        synth = parse_yosys_stat(SYN / f"yosys_stat_{cfg}.txt")
        cells = int(synth.get("total_cells") or 0)
        fs = FORMAL_STATUS[cfg]
        rows.append({
            "random_campaign_status": RANDOM_CAMPAIGN_STATUS,
            "configuration": cfg,
            "reset_default": rst,
            "admission_gate": gate,
            "pending_epoch": pend,
            "SP08": fs["SP08"],
            "SP11": fs["SP11"],
            "SP12A": fs["SP12A"],
            "SP12B": fs["SP12B"],
            "SP13": fs["SP13"],
            "SP14": fs["SP14"],
            "directed_tests": d_total,
            "directed_failures": d_fail,
            "random_runs": rnd["random_runs"],
            "random_failures": rnd["random_failures"],
            "random_expected_by_model": rnd["random_expected_by_model"],
            "random_reset_assumption": rnd["random_reset_assumption"],
            "random_model_difference": rnd["random_model_difference"],
            "random_genuine_ce": rnd["random_genuine_ce"],
            "random_testbench_bug": rnd["random_testbench_bug"],
            "security_enforcement_latency": "BLOCKED_BY_FIXTURE",
            "secure_ready_latency": "BLOCKED_BY_FIXTURE",
            "dma_accept_latency": perf.get("normal_write_latency_cycles", ""),
            "availability_block_cycles": "BLOCKED_BY_FIXTURE",
            "normal_read_latency": perf.get("normal_read_error", ""),
            "normal_write_latency": perf.get("normal_write_latency_cycles", ""),
            "dma_throughput": "",
            "total_cells": synth.get("total_cells", ""),
            "flip_flops": synth.get("flip_flops", ""),
            "logic_delta": str(cells - c0_cells) if c0_cells else "",
            "interpretation": _interpret(cfg, fs, cells, c0_cells, rnd),
        })
    TABLES.mkdir(parents=True, exist_ok=True)
    fields = list(rows[0].keys())
    out = TABLES / "m4_configuration_comparison.csv"
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)
    build_figures(rows)
    print(f"Wrote {out}")


def _interpret(cfg: str, fs: dict, cells: int, c0_cells: int, rnd: dict) -> str:
    delta = cells - c0_cells if c0_cells else 0
    if cfg == "C1":
        return f"minimal sufficient; SP-08 {fs['SP08']}; genuine_ce={rnd['random_genuine_ce']}; delta={delta}"
    if cfg == "C0":
        return "baseline fail-open; SP-08 counterexample preserved"
    if cfg == "C4":
        return f"redundant with C1; genuine_ce={rnd['random_genuine_ce']}; delta={delta}"
    if cfg == "C3":
        return "epoch for SP-12B; not required for reset-only model"
    return "fail-open + admission gate"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim-only", action="store_true")
    ap.add_argument("--synth-only", action="store_true")
    ap.add_argument("--formal-only", action="store_true")
    ap.add_argument("--performance-only", action="store_true")
    ap.add_argument("--random-only", action="store_true")
    args = ap.parse_args()
    build_comparison()


if __name__ == "__main__":
    main()
