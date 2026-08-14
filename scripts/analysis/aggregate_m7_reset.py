#!/usr/bin/env python3
"""Aggregate M7 reset raw CSV into results/tables/m7_reset_matrix.csv."""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "results/m7/reset/m7_reset_raw.csv"
OUT = ROOT / "results/tables/m7_reset_matrix.csv"


def main() -> int:
    rows: list[dict] = []
    raw_dir = ROOT / "results/m7/reset"
    for raw in sorted(raw_dir.glob("m7_reset_raw_*.csv")):
        rows.extend(csv.DictReader(raw.open()))
    if not rows and (raw_dir / "m7_reset_raw.csv").exists():
        rows = list(csv.DictReader((raw_dir / "m7_reset_raw.csv").open()))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if rows:
        with OUT.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=rows[0].keys())
            w.writeheader()
            w.writerows(rows)
    print(f"Wrote {OUT} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
