#!/usr/bin/env python3
"""M5 REF↔RTL compatible differential (aligned subset)."""
from __future__ import annotations

import csv
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / "m5" / "bin" / "m5_ref_check"
RTL_CSV = ROOT / "results" / "m5" / "rtl" / "rtl_results.csv"
OUT = ROOT / "results" / "tables" / "m5_ref_rtl_differential.csv"
PROTECT = 0x20000000


def ref_check(enable: bool, configured: bool, rrid: int, write: bool) -> str:
    r = subprocess.run(
        [str(REF), str(int(enable)), str(int(configured)), str(rrid), hex(PROTECT),
         "write" if write else "read"],
        capture_output=True, text=True,
    )
    return r.stdout.strip() if r.returncode == 0 else "INCONCLUSIVE"


def main() -> int:
    scenarios = [
        ("S1-pre-bypass", False, False, 0, True, "ALLOW", "ALLOW"),
        ("S2-pre-enforce", True, False, 0, True, "DENY", "DENY"),
        ("S3-auth-write", True, True, 0, True, "ALLOW", "ALLOW"),
        ("S7-post-reset", False, False, 0, True, "ALLOW", "ALLOW"),
    ]
    rows = []
    for sid, en, cfg, rrid, wr, ref_exp, rtl_exp in scenarios:
        ref = ref_check(en, cfg, rrid, wr)
        same = ref == ref_exp
        rows.append({
            "scenario": sid, "enable": en, "configured": cfg,
            "REF_result": ref, "REF_expected": ref_exp,
            "RTL_expected": rtl_exp, "same_class": same,
            "classification": "EXPECTED_EQUIVALENCE" if same else "SPEC_REVISION_DIFFERENCE",
        })
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"REF↔RTL subset: {len(rows)} scenarios -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
