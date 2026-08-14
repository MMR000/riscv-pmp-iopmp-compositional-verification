#!/usr/bin/env python3
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "results/m7/multimaster/m7_multimaster_raw.csv"
OUT = ROOT / "results/tables/m7_multimaster_matrix.csv"

def main() -> int:
    if not RAW.exists():
        print(f"Missing {RAW}")
        return 1
    rows = list(csv.DictReader(RAW.open()))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if rows:
        with OUT.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=rows[0].keys())
            w.writeheader()
            w.writerows(rows)
    (ROOT / "results/m7/multimaster/summary.md").write_text(
        f"# M7 multimaster summary\n\nRows: {len(rows)}\n\n"
        "Research IOPMP supports outstanding depth 1 only; depths 2/4/8 marked UNSUPPORTED_BY_IMPLEMENTATION.\n"
    )
    print(f"Wrote {OUT}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
