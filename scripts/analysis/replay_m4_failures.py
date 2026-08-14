#!/usr/bin/env python3
"""Replay and reclassify M4 random campaign failures."""
from __future__ import annotations

import csv
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIM = ROOT / "results" / "simulation"
RUNS = SIM / "m4_random_reset_runs.csv"
FAILS = SIM / "m4_failing_seeds.csv"
TB = ROOT / "tb" / "cocotb"

ALLOWED = {
    "EXPECTED_BY_MODEL",
    "RESET_ASSUMPTION_DEPENDENCY",
    "EXPECTED_MODEL_DIFFERENCE",
    "IMPLEMENTATION_BUG",
    "TESTBENCH_BUG",
    "GENUINE_PROPERTY_COUNTEREXAMPLE",
    "INCONCLUSIVE",
}


def _replay(cfg: str, seed: str) -> dict | None:
    env = {"M4_CONFIG": cfg, "M4_SEED": seed}
    r = subprocess.run(
        ["python3", "-m", "pytest", "test_m4_random_runner.py", "-q"],
        cwd=TB,
        env={**dict(__import__("os").environ), **env},
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        return None
    p = SIM / f"m4_random_{cfg}_seed{int(seed):04d}.csv"
    if not p.exists():
        return None
    with p.open(newline="") as f:
        rows = list(csv.DictReader(f))
    return rows[-1] if rows else None


def _classify(row: dict, replay: dict | None) -> str:
    src = replay or row
    if src.get("result") == "PASS":
        return "EXPECTED_BY_MODEL"
    if str(src.get("iopmp_in_path", "")).lower() not in ("true", "1"):
        return "TESTBENCH_BUG"
    cfg = src["configuration"]
    secure = str(src.get("secure_ready", "")).lower() in ("true", "1")
    err = int(src.get("dma_error", 0) or 0)
    policy = str(src.get("policy_valid", "")).lower() in ("true", "1")
    if replay is None:
        return "INCONCLUSIVE"
    if cfg == "C0" and not secure and err == 0:
        return "RESET_ASSUMPTION_DEPENDENCY"
    if not secure and err == 1:
        return "EXPECTED_BY_MODEL"
    if not policy and err == 1:
        return "EXPECTED_BY_MODEL"
    if cfg in ("C1", "C4") and not secure and err == 0:
        return "GENUINE_PROPERTY_COUNTEREXAMPLE"
    if cfg in ("C2", "C3") and not secure and err == 0:
        return "GENUINE_PROPERTY_COUNTEREXAMPLE"
    if err == 1:
        return "EXPECTED_BY_MODEL"
    return "INCONCLUSIVE"


def main() -> int:
    if not RUNS.exists():
        print(f"MISSING {RUNS}", file=sys.stderr)
        return 1
    with RUNS.open(newline="") as f:
        rows = list(csv.DictReader(f))
    fail_rows = [r for r in rows if r.get("result") == "FAIL"]
    replayed = 0
    for r in rows:
        if r.get("result") != "FAIL":
            r["classification"] = "EXPECTED_BY_MODEL"
            continue
        rep = _replay(r["configuration"], r["seed"])
        if rep:
            replayed += 1
        r["classification"] = _classify(r, rep)
        if r["classification"] not in ALLOWED:
            r["classification"] = "INCONCLUSIVE"
    fields = list(rows[0].keys())
    with RUNS.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)
    with FAILS.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["seed", "configuration", "classification", "property", "notes"])
        w.writeheader()
        for r in fail_rows:
            w.writerow({
                "seed": r["seed"],
                "configuration": r["configuration"],
                "classification": r["classification"],
                "property": r.get("property", ""),
                "notes": f"replay={'ok' if r['classification'] != 'INCONCLUSIVE' else 'fail'}",
            })
    counts = Counter(r["classification"] for r in rows)
    per_cfg = Counter((r["configuration"], r["classification"]) for r in rows)
    print(f"Replayed {replayed}/{len(fail_rows)} failures")
    print("Classifications:", dict(counts))
    for cfg in ("C0", "C1", "C2", "C3", "C4"):
        c = Counter(cl for (cf, cl) in per_cfg if cf == cfg)
        print(f"  {cfg}: {dict(c)}")
    genuine_c1 = sum(1 for r in rows if r["configuration"] == "C1" and r["classification"] == "GENUINE_PROPERTY_COUNTEREXAMPLE")
    print(f"C1 genuine counterexamples: {genuine_c1}")
    if genuine_c1:
        print("STOP: C1 has genuine counterexamples", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
