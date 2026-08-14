#!/usr/bin/env python3
"""Aggregate M5.6 campaign outputs into summary."""
from __future__ import annotations

import csv
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "results"
M56 = RESULTS / "m56"
TABLES = RESULTS / "tables"


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "unknown"


def read_csv(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def count_pass(rows: list[dict], col: str = "result") -> tuple[int, int]:
    if not rows:
        return 0, 0
    p = sum(1 for r in rows if r.get(col, "").upper() == "PASS")
    return p, len(rows)


def main() -> None:
    commit = git_head()
    wr = read_csv(TABLES / "m56_write_regression.csv")
    rr = read_csv(TABLES / "m56_read_regression.csv")
    rt = read_csv(TABLES / "m56_route_freshness.csv")
    rnd = read_csv(M56 / "random" / "all_runs.csv")
    wp, tw = count_pass(wr)
    rp, tr = count_pass(rr)
    fails = [r for r in rnd if r.get("deadlock") == "1" or r.get("observed") not in ("ALLOW", "DENY", "")]
    fail_path = M56 / "random" / "failing_seeds.csv"
    if rnd:
        with fail_path.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rnd[0].keys()))
            w.writeheader()
            w.writerows(fails)

    summary = f"""# M5.6 Summary

- Branch: m56-write-path-fix-formal
- HEAD: {commit}
- M5.5 commit: ff46d11
- M5.5 tag: checkpoint-m55-write-defect

## Write regression
- Rows: {tw}, PASS: {wp}

## Read regression
- Rows: {tr}, PASS: {rp}

## Stale-route sequences
- Rows: {len(rt)}

## Random campaign
- Runs: {len(rnd)}
- Failures: {len(fails)}

## Evidence index
- Write regression: results/tables/m56_write_regression.csv
- Read regression: results/tables/m56_read_regression.csv
- Timing: results/tables/m56_axi_timing_matrix.csv
- Route freshness: results/tables/m56_route_freshness.csv
- Fix comparison: results/tables/m56_fix_comparison.csv
- Latency: results/tables/m56_latency.csv
- Before CE: results/m56/before_fix/M56-BEFORE-CE.txt
- Patch: patches/iopmp/m56_write_path_transaction_binding.patch
- Formal: results/formal/m56_summary.md
"""
    (M56 / "m56_summary.md").write_text(summary)
    print(summary)


if __name__ == "__main__":
    main()
