#!/usr/bin/env python3
"""Merge per-configuration directed matrix CSVs into one table."""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIM = ROOT / "results" / "simulation"
TABLES = ROOT / "results" / "tables"
OUT = TABLES / "m4_directed_reset_matrix.csv"

fields = [
    "experiment_id", "scenario", "configuration", "reset_default", "admission_gate",
    "commit_epoch", "initial_state", "reset_sequence", "expected", "observed",
    "property_ids", "result", "classification", "waveform", "notes", "git_commit",
]

rows = []
for cfg in ("C0", "C1", "C2", "C3", "C4"):
    p = SIM / f"m4_directed_matrix_{cfg}.csv"
    if p.exists():
        with p.open(newline="") as f:
            rows.extend(csv.DictReader(f))

TABLES.mkdir(parents=True, exist_ok=True)
with OUT.open("w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
    w.writeheader()
    for r in rows:
        w.writerow({k: r.get(k, "") for k in fields})
print(f"Merged {len(rows)} rows -> {OUT}")
