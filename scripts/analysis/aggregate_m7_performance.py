#!/usr/bin/env python3
"""Build m7_performance.csv from available cycle measurements."""
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/tables/m7_performance.csv"
PERF = ROOT / "results/m7/performance"


def main() -> int:
    rows = []
    m4 = PERF / "m4_baseline_cycles.csv"
    if m4.exists():
        for r in csv.DictReader(m4.open()):
            rows.append({
                "metric": r.get("experiment", "m4"),
                "config": r.get("config", "C1"),
                "cycles": r.get("cycles", r.get("latency_cycles", "NOT_RUN")),
                "clock_mhz": "NOT_RECORDED",
                "source": str(m4),
                "classification": "SIMULATION_EVIDENCE",
            })
    if not rows:
        rows.append({
            "metric": "secure_ready_latency",
            "config": "M7-reset",
            "cycles": "see m7_reset_matrix",
            "clock_mhz": "NOT_RECORDED",
            "source": "results/tables/m7_reset_matrix.csv",
            "classification": "SIMULATION_EVIDENCE",
        })
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    (PERF / "summary.md").write_text("# M7 performance\n\nCycle-level metrics from simulation; no FPGA timing.\n")
    print(f"Wrote {OUT}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
