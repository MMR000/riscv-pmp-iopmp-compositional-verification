#!/usr/bin/env python3
"""Aggregate M5.8 formal run results."""
from __future__ import annotations

import argparse
import csv
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/formal/m58"
MATRIX = ROOT / "results/tables/m58_formal_matrix.csv"


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "unknown"


def classify(task_dir: Path) -> str:
    if (task_dir / "PASS").exists():
        return "BOUNDED_PASS" if "bmc" in task_dir.name else "FORMAL_PROOF"
    if (task_dir / "FAIL").exists():
        return "COUNTEREXAMPLE"
    if (task_dir / "ERROR").exists():
        return "TOOL_ERROR"
    return "INCONCLUSIVE"


def runtime_sec(task_dir: Path) -> str:
    p = task_dir / "runtime_sec.txt"
    return p.read_text().strip() if p.exists() else ""


def append_matrix(row: dict) -> None:
    MATRIX.parent.mkdir(parents=True, exist_ok=True)
    write_header = not MATRIX.exists() or MATRIX.stat().st_size == 0
    with MATRIX.open("a" if not write_header else "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(row.keys()))
        if write_header:
            w.writeheader()
        w.writerows([row])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--variant", default="proper")
    ap.add_argument("--mode", default="bmc")
    ap.add_argument("--depth", default="32")
    ap.add_argument("--task", default="m58_proper_bmc32")
    ap.add_argument("--engine", default="smtbmc z3")
    ap.add_argument("--finalize", action="store_true")
    args = ap.parse_args()

    if args.finalize:
        return

    task_dir = OUT / args.task
    status = classify(task_dir)
    if args.variant == "original" and status == "COUNTEREXAMPLE":
        status = "EXPECTED_PRE_FIX_COUNTEREXAMPLE"

    cex = ""
    if (OUT / "counterexamples/M57-FP-04_FIX0/trace.vcd").exists():
        cex = str(OUT / "counterexamples/M57-FP-04_FIX0/trace.vcd")

    append_matrix(
        {
            "property": "M57-FP-04",
            "variant": args.variant,
            "frontend": "read_slang/yosys-0.68",
            "engine": args.engine.split()[0],
            "method": args.mode,
            "depth": args.depth,
            "result": status,
            "runtime": runtime_sec(task_dir),
            "memory": "",
            "assumptions": "M58-FA-01..04",
            "counterexample_path": cex,
            "notes": args.task,
        }
    )


if __name__ == "__main__":
    main()
