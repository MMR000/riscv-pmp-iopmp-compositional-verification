#!/usr/bin/env python3
"""Build results/tables/m7_formal_matrix.csv from M7 formal runs."""
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/tables/m7_formal_matrix.csv"
FORMAL = ROOT / "results/m7/formal"


def read_status(task_dir: Path) -> str:
    st = task_dir / "status"
    if st.exists():
        return st.read_text().strip().splitlines()[-1] if st.read_text().strip() else "UNKNOWN"
    return "NOT_RUN"


def main() -> int:
    rows = [
        {
            "property_id": "SP-06",
            "rtl_commit": "research-iopmp",
            "harness": "formal/harness/formal_iopmp_tb.v",
            "engine": "sby/smtbmc/z3",
            "mode": "prove",
            "bound": "32",
            "raw_tool_status": read_status(FORMAL / "sp06_sp09_prove"),
            "scientific_classification": "BOUNDED_EVIDENCE",
            "notes": "bundled with SP-04 unit harness; standalone SP-06 row",
        },
        {
            "property_id": "SP-09",
            "rtl_commit": "research-iopmp",
            "harness": "formal/harness/formal_iopmp_tb.v",
            "engine": "sby/smtbmc/z3",
            "mode": "unit_bmc",
            "bound": "32",
            "raw_tool_status": read_status(FORMAL / "sp06_sp09_unit"),
            "scientific_classification": "SIMULATION_EVIDENCE",
            "notes": "M3 unit proof at depth 32; M7 reproduction attempt",
        },
        {
            "property_id": "M57-FP-04-FIX2",
            "rtl_commit": "zero-day-labs+FIX-2",
            "harness": "formal_m57_fullrtl_write_path_tb.sv ENV-4",
            "engine": "sby/smtbmc/z3",
            "mode": "bmc",
            "bound": "512",
            "raw_tool_status": "see results/formal/m59/m59_proper_env4_bmc512/status",
            "scientific_classification": "BOUNDED_EVIDENCE",
            "notes": "PDR raw FAIL unchanged; Yices TOOLCHAIN_LIMITATION",
        },
    ]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    (FORMAL / "summary.md").write_text("# M7 formal summary\n\nSee results/tables/m7_formal_matrix.csv\n")
    print(f"Wrote {OUT}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
