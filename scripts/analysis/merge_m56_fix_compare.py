#!/usr/bin/env python3
"""Merge per-build M5.6 fix-comparison rows into one table."""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/m56"
TABLES = ROOT / "results/tables"


def read_row(path: Path, fix: str) -> dict | None:
    if not path.exists():
        return None
    with path.open(newline="") as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        if r.get("build_fix") == fix or r.get("configuration") == fix:
            return r
    return rows[-1] if rows else None


def main() -> None:
    merged = []
    for fix in ("original", "naive", "proper"):
        src = OUT / f"fix_compare_{fix}.csv"
        row = read_row(src, fix)
        if row:
            merged.append(row)
    if not merged:
        return
    out = TABLES / "m56_fix_comparison.csv"
    fields = list(merged[0].keys())
    with out.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(merged)


if __name__ == "__main__":
    main()
