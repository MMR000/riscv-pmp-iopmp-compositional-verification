#!/usr/bin/env python3
"""M7 Phase B randomized composition campaign.

Samples the directed compositional scenario space (IBEX-COMP-01..08) with
reproducible seeds. PMP configuration is fixed (not randomized).

Each seed maps to exactly one directed ELF and is replayable by re-running
that ELF (or this script with --seeds SEED).

Classification: SIMULATION_EVIDENCE over a closed scenario set.
Campaign size is recorded explicitly.
"""
from __future__ import annotations

import argparse
import csv
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results/tables/m7_ibex_composed_random.csv"
LOG_DIR = ROOT / "results/m7/ibex_composed/random"
IBEX = ROOT / "third_party/ibex"

# Import directed parser/classifier
import sys

sys.path.insert(0, str(ROOT / "scripts/analysis"))
from run_m7_ibex_composed_tests import SPECS, classify, parse_log, run_sim  # noqa: E402


def scenario_for_seed(seed: int) -> str:
    idx = (seed % 8) + 1
    return f"IBEX-COMP-0{idx}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", required=True)
    ap.add_argument("--num-seeds", type=int, default=100)
    ap.add_argument("--seeds", type=int, nargs="*", default=None,
                    help="Explicit seed list (overrides --num-seeds)")
    args = ap.parse_args()
    sim = Path(args.sim)
    sw = ROOT / "m7/sw/ibex_composed"
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True, cwd=str(ROOT)).strip()
    ibex_commit = subprocess.check_output(
        ["git", "-C", str(IBEX), "rev-parse", "HEAD"], text=True
    ).strip()

    seeds = args.seeds if args.seeds is not None else list(range(args.num_seeds))
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    rows = []
    n_pass = 0
    n_fail = 0
    t0 = time.time()
    for seed in seeds:
        tid = scenario_for_seed(seed)
        elf = sw / f"{tid}.elf"
        log_path = LOG_DIR / f"seed_{seed:04d}_{tid}.log"
        if not elf.exists():
            rows.append({
                "seed": seed, "test_id": tid, "project_commit": commit,
                "ibex_commit": ibex_commit, "result": "NOT_RUN",
                "classification": "INCONCLUSIVE", "replay_cmd": "",
                "notes": "ELF missing",
            })
            n_fail += 1
            continue
        log, rc = run_sim(sim, elf)
        log_path.write_text(log)
        parsed = parse_log(log)
        cpu_obs, dma_obs, mem_obs, result = classify(tid, parsed)
        if result == "PASS":
            n_pass += 1
        else:
            n_fail += 1
        rows.append({
            "seed": seed,
            "test_id": tid,
            "project_commit": commit,
            "ibex_commit": ibex_commit,
            "cpu_observed": cpu_obs,
            "dma_observed": dma_obs,
            "memory_after": mem_obs,
            "expected_memory": SPECS[tid]["mem_exp"],
            "result": result,
            "classification": "SIMULATION_EVIDENCE" if result == "PASS" else "TEST_SOFTWARE_BUG",
            "replay_cmd": f"{sim} --meminit=ram,{elf}",
            "notes": f"exit={rc}; scenario_space=COMP-01..08",
        })
        print(f"seed={seed:4d} {tid}: {result}")
    elapsed = time.time() - t0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    summary = (
        f"seeds={len(seeds)} pass={n_pass} fail={n_fail} "
        f"runtime_sec={elapsed:.2f} campaign=scenario_space_COMP01_08\n"
    )
    (LOG_DIR / "summary.txt").write_text(summary)
    print(summary.strip())
    print(f"Wrote {OUT}")
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
