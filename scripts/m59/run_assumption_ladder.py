#!/usr/bin/env python3
"""Run M59 assumption ladder and record results."""
from __future__ import annotations

import csv
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/tables/m59_assumption_ladder.csv"
RUN = ROOT / "scripts/run/run_m59_formal.sh"


def status(task_dir: Path) -> str:
    for name in ("PASS", "FAIL", "ERROR", "UNKNOWN"):
        if (task_dir / name).exists():
            return name
    s = task_dir / "status"
    return s.read_text().strip() if s.exists() else "UNKNOWN"


def main() -> int:
    rows = []
    for env in range(6):
        for variant in ("original", "proper"):
            env_var = {"M59_ENV_LEVEL": str(env), "M59_VARIANT": variant, "M59_DEPTH": "64"}
            subprocess.run(["bash", str(RUN)], env={**dict(subprocess.os.environ), **env_var}, check=False)
            task = ROOT / f"results/formal/m59/m59_{variant}_env{env}_bmc64"
            st = status(task)
            ce = ""
            if (task / "engine_0/logfile.txt").exists():
                for ln in (task / "engine_0/logfile.txt").read_text().splitlines():
                    if "Checking assertions in step" in ln:
                        ce = ln.strip()
            fix0 = "EXPECTED_PRE_FIX_COUNTEREXAMPLE" if variant == "original" and st == "FAIL" else st
            fix2 = st
            interp = ""
            if variant == "proper" and st == "FAIL" and env == 0:
                interp = "M5.8 anyinit baseline"
            elif variant == "proper" and st == "PASS":
                interp = "CE eliminated under env constraints"
            elif variant == "original" and st != "FAIL":
                interp = "WARNING: FIX-0 no longer detected"
            rows.append({
                "environment_level": f"ENV-{env}",
                "assumptions": f"M59_ENV_LEVEL={env}",
                "fix0_result": fix0 if variant == "original" else "",
                "fix2_result": fix2 if variant == "proper" else "",
                "fix0_ce_depth": ce if variant == "original" else "",
                "fix2_ce_depth": ce if variant == "proper" else "",
                "interpretation": interp,
            })
    # merge original/proper rows per env
    merged = {}
    for r in rows:
        k = r["environment_level"]
        if k not in merged:
            merged[k] = r
        else:
            merged[k]["fix0_result"] = r["fix0_result"] or merged[k]["fix0_result"]
            merged[k]["fix2_result"] = r["fix2_result"] or merged[k]["fix2_result"]
            merged[k]["fix0_ce_depth"] = r["fix0_ce_depth"] or merged[k]["fix0_ce_depth"]
            merged[k]["fix2_ce_depth"] = r["fix2_ce_depth"] or merged[k]["fix2_ce_depth"]
            if r["interpretation"]:
                merged[k]["interpretation"] = r["interpretation"]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(next(iter(merged.values())).keys()))
        w.writeheader()
        for k in sorted(merged.keys()):
            w.writerow(merged[k])
    print(f"Wrote {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
