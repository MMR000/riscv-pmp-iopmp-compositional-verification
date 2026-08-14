#!/usr/bin/env python3
"""Validate corrected M4 random campaign CSV."""
from __future__ import annotations

import csv
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNS = ROOT / "results" / "simulation" / "m4_random_reset_runs.csv"
CONFIGS = ("C0", "C1", "C2", "C3", "C4")
EXPECTED = 200


def main() -> int:
    if not RUNS.exists():
        print(f"MISSING {RUNS}", file=sys.stderr)
        return 1
    with RUNS.open(newline="") as f:
        rows = list(csv.DictReader(f))
    if len(rows) != 1000:
        print(f"FAIL row count {len(rows)} != 1000", file=sys.stderr)
        return 1
    by_cfg = Counter(r["configuration"] for r in rows)
    for cfg in CONFIGS:
        if by_cfg[cfg] != EXPECTED:
            print(f"FAIL {cfg} count {by_cfg[cfg]} != {EXPECTED}", file=sys.stderr)
            return 1
    pairs = {(r["configuration"], r["seed"]) for r in rows}
    if len(pairs) != 1000:
        print(f"FAIL duplicate (configuration, seed) pairs", file=sys.stderr)
        return 1
    campaign = {r.get("campaign_id", "") for r in rows}
    if "m4_random_v2" not in campaign:
        print("FAIL campaign_id != m4_random_v2", file=sys.stderr)
        return 1
    bypass = [r for r in rows if str(r.get("iopmp_in_path", "")).lower() not in ("true", "1")]
    if bypass:
        print(f"FAIL {len(bypass)} runs with IOPMP not in-path", file=sys.stderr)
        return 1
    print("PASS validate_m4_random: 1000 rows, 200/config, no duplicates, IOPMP in-path")
    return 0


if __name__ == "__main__":
    sys.exit(main())
