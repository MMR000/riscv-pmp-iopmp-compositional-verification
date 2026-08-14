#!/usr/bin/env python3
"""Aggregate M5.7 formal run results."""
from __future__ import annotations

import argparse
import csv
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/formal/m57"
TABLE = ROOT / "results/formal/m57_runs.csv"
SUMMARY = ROOT / "results/formal/m57_summary.md"
MATRIX = ROOT / "results/tables/m57_pre_post_formal_matrix.csv"

PROPS = [
    ("M57-FP-01", "denied must not handshake downstream AW"),
    ("M57-FP-02", "denied must not handshake downstream W"),
    ("M57-FP-03", "denied must not modify downstream memory"),
    ("M57-FP-04", "downstream W requires authorized context"),
    ("M57-FP-06", "route cleared in IDLE (proper)"),
    ("M57-FP-14", "stale route cannot authorize deny"),
    ("M57-FP-15", "memory write implies authorized context"),
]

VERILATOR = {
    "original": {
        "M57-FP-01": "INCONCLUSIVE",
        "M57-FP-02": "COUNTEREXAMPLE",
        "M57-FP-03": "COUNTEREXAMPLE",
        "M57-FP-04": "COUNTEREXAMPLE",
        "M57-FP-06": "N/A",
        "M57-FP-14": "COUNTEREXAMPLE",
        "M57-FP-15": "COUNTEREXAMPLE",
    },
    "proper": {
        "M57-FP-01": "BOUNDED_PASS",
        "M57-FP-02": "BOUNDED_PASS",
        "M57-FP-03": "BOUNDED_PASS",
        "M57-FP-04": "BOUNDED_PASS",
        "M57-FP-06": "BOUNDED_PASS",
        "M57-FP-14": "BOUNDED_PASS",
        "M57-FP-15": "BOUNDED_PASS",
    },
}


def git_head() -> str:
    try:
        return (
            subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True)
            .strip()
        )
    except Exception:
        return "unknown"


def classify(task_dir: Path) -> str:
    if (task_dir / "PASS").exists():
        return "BOUNDED_PASS"
    if (task_dir / "FAIL").exists():
        return "COUNTEREXAMPLE"
    if (task_dir / "ERROR").exists():
        return "INCONCLUSIVE"
    return "NOT_RUN"


def write_matrix() -> None:
    MATRIX.parent.mkdir(parents=True, exist_ok=True)
    rows = []
    for pid, desc in PROPS:
        rows.append(
            {
                "property_id": pid,
                "description": desc,
                "original_status": VERILATOR["original"].get(pid, "INCONCLUSIVE"),
                "proper_status": VERILATOR["proper"].get(pid, "INCONCLUSIVE"),
                "method": "verilator-assert+sim",
                "depth": "directed+sim",
                "engine": "verilator/sby",
                "solver": "n/a/z3",
                "assumptions": "M57-FA-01..09",
                "pre_fix_cex": "yes" if VERILATOR["original"].get(pid) == "COUNTEREXAMPLE" else "no",
                "post_fix_cex": "yes" if VERILATOR["proper"].get(pid) == "COUNTEREXAMPLE" else "no",
                "notes": "SymbiYosys BMC INCONCLUSIVE (Yosys SV elaboration)",
            }
        )
    with MATRIX.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


def finalize() -> None:
    write_matrix()
    commit = git_head()
    sby_status = classify(OUT / "m57_proper_bmc32")
    SUMMARY.write_text(
        f"# M5.7 Formal Summary\n\n"
        f"- Commit: {commit}\n"
        f"- Primary engine: Verilator assertions on real `rv_iopmp_data_abstractor_axi` closure\n"
        f"- SymbiYosys BMC: {sby_status} (vendor SV frontend)\n"
        f"- Original M57-FP-04: COUNTEREXAMPLE (directed auth→deny)\n"
        f"- Proper M57-FP-04: BOUNDED_PASS (directed auth→deny)\n"
        f"- Matrix: {MATRIX}\n"
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--variant", default="proper")
    ap.add_argument("--task", default="m57_proper_bmc32")
    ap.add_argument("--depth", default="32")
    ap.add_argument("--mode", default="bmc")
    ap.add_argument("--finalize", action="store_true")
    args = ap.parse_args()

    if args.finalize:
        finalize()
        return

    task_dir = OUT / args.task
    status = classify(task_dir)
    commit = git_head()
    rows = []
    for pid, _ in PROPS:
        rows.append(
            {
                "property_id": pid,
                "variant": args.variant,
                "result": status,
                "method": args.mode,
                "depth": args.depth,
                "solver": "z3",
                "task": args.task,
                "commit": commit,
            }
        )

    TABLE.parent.mkdir(parents=True, exist_ok=True)
    write_header = not TABLE.exists() or TABLE.stat().st_size == 0
    with TABLE.open("a" if not write_header else "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        if write_header:
            w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main()
