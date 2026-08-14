#!/usr/bin/env python3
"""Parse Yosys stat logs into m7_ppa.csv (synthesis-only)."""
from __future__ import annotations
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "results/m7/ppa/raw"
OUT = ROOT / "results/tables/m7_ppa.csv"
SUM = ROOT / "results/tables/m7_ppa_summary.csv"


def parse_stat(path: Path) -> dict:
    text = path.read_text(errors="replace")
    cells = re.search(r"Number of cells:\s*(\d+)", text)
    wires = re.search(r"Number of wire bits:\s*(\d+)", text)
    return {
        "total_cells": cells.group(1) if cells else "NOT_RUN",
        "wire_bits": wires.group(1) if wires else "NOT_RUN",
        "flow": "synthesis-only",
        "mapped_area": "NOT_RUN",
        "fmax": "NOT_RUN",
        "wns": "NOT_RUN",
    }


def main() -> int:
    rows = []
    for log in sorted(RAW.glob("yosys_*.log")):
        cfg = log.stem.replace("yosys_", "")
        m = parse_stat(log)
        m["config"] = cfg
        rows.append(m)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if rows:
        fields = list(rows[0].keys())
        with OUT.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)
        with SUM.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields + ["overhead_vs_J0_note"])
            w.writeheader()
            for r in rows:
                r2 = dict(r)
                r2["overhead_vs_J0_note"] = "raw cell counts only; no Liberty/OpenROAD"
                w.writerow(r2)
    (ROOT / "results/m7/ppa/summary.md").write_text(
        "# M7 PPA summary\n\n"
        "Common-target place-and-route: **TOOLCHAIN_LIMITATION** (OpenROAD/Liberty not available).\n"
        "Reported metrics are Yosys synthesis-only cell counts.\n"
        "Real Ibex SoC configs (J0–J4) require composed synthesis top — pending Ibex integration.\n"
    )
    print(f"Wrote {OUT}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
