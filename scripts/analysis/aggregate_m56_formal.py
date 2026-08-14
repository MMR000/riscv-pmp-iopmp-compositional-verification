#!/usr/bin/env python3
"""Summarize M5.6 formal run results."""
from __future__ import annotations

import csv
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FORMAL = ROOT / "results/formal"
RUN_DIR = FORMAL / "m56_write_path"
TABLE = FORMAL / "m56_runs.csv"
SUMMARY = FORMAL / "m56_summary.md"

PROPS = [
    ("F-WP-01", "deny_no_dst_aw"),
    ("F-WP-02", "deny_no_dst_w"),
    ("F-WP-03", "deny_no_mem"),
    ("F-WP-04", "dst_w_requires_auth"),
    ("F-WP-05", "route_clear_idle"),
    ("F-WP-06", "no_stale_route"),
    ("F-WP-07", "reset_clear"),
    ("F-WP-08", "cover_auth_write"),
    ("F-WP-09", "cover_deny_complete"),
]


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "unknown"


def classify_run() -> str:
    if (RUN_DIR / "PASS").exists():
        return "BOUNDED_PASS"
    if (RUN_DIR / "FAIL").exists():
        return "COUNTEREXAMPLE"
    if (RUN_DIR / "ERROR").exists():
        return "INCONCLUSIVE"
    return "NOT_RUN"


def main() -> None:
    status = classify_run()
    commit = git_head()
    rows = []
    for pid, _ in PROPS:
        rows.append(
            {
                "property_id": pid,
                "result": status if status != "NOT_RUN" else "NOT_RUN",
                "method": "bmc",
                "depth": "32",
                "solver": "z3",
                "assumptions": "M56-FA-01",
                "commit": commit,
            }
        )
    TABLE.parent.mkdir(parents=True, exist_ok=True)
    with TABLE.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    SUMMARY.write_text(
        f"""# M5.6 Formal Summary

- Harness: `formal/harness/formal_m56_write_path_tb.sv` (abstract transaction-binding model)
- Task: `formal/tasks/m56_write_path.sby`
- Aggregate status: **{status}**
- Depth: 32
- Solver: z3
- Commit: {commit}

See `results/formal/m56_runs.csv` for per-property rows.
"""
    )


if __name__ == "__main__":
    main()
