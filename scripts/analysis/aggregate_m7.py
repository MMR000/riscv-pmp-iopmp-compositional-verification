#!/usr/bin/env python3
"""Aggregate M7 artifacts into final guarantee and realcore matrices."""
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "results/tables"


def copy_matrix(src: Path, dst: Path) -> int:
    if not src.exists():
        return 0
    rows = list(csv.DictReader(src.open()))
    if not rows:
        return 0
    dst.parent.mkdir(parents=True, exist_ok=True)
    with dst.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)
    return len(rows)


def main() -> int:
    # Preserve M5.10 — copy, do not overwrite source
    m510 = TABLES / "m510_guarantee_matrix.csv"
    final = TABLES / "m7_final_guarantee_matrix.csv"
    if m510.exists():
        text = m510.read_text()
        final.write_text(text)

    ibex_res = ROOT / "results/m7/ibex/ibex_pmp_results.csv"
    realcore = TABLES / "m7_realcore_security_matrix.csv"
    if ibex_res.exists():
        copy_matrix(ibex_res, realcore)
    else:
        realcore.write_text(
            "test_id,status,classification,notes\n"
            "IBEX-PMP-ALL,NOT_RUN,TOOLCHAIN_LIMITATION,"
            "Ibex Verilator build blocked by UNOPTFLAT-as-error; see results/m7/ibex/build.log\n"
        )

    print(f"Wrote {final} and {realcore}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
