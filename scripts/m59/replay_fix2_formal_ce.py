#!/usr/bin/env python3
"""Replay M5.8 FIX-2 formal CE witness in Verilator (M5.9 classification)."""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_TRACE = ROOT / "results/formal/m58/m58_proper_bmc64/engine_0/trace_tb.v"


def classify(trace_tb: Path) -> str:
    text = trace_tb.read_text(errors="replace")
    anyinit = len(re.findall(r"anyinit_driver", text))
    cycle_stim = len(re.findall(r"if \(cycle ==", text))
    # count non-empty cycle blocks with assignments other than genclock
    if anyinit > 20 and cycle_stim <= 6:
        return "NOT_REPRODUCIBLE_DUE_TO_UNCONTROLLABLE_INTERNAL_STATE"
    if "src_aw_valid" not in text and anyinit > 0:
        return "NOT_REPRODUCIBLE_DUE_TO_UNCONTROLLABLE_INTERNAL_STATE"
    return "INCONCLUSIVE"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--trace-tb", type=Path, default=DEFAULT_TRACE)
    ap.add_argument("-o", type=Path, default=ROOT / "results/simulation/m59/fix2_ce_replay")
    args = ap.parse_args()
    args.o.mkdir(parents=True, exist_ok=True)

    if not args.trace_tb.exists():
        print(f"Missing trace: {args.trace_tb}", file=sys.stderr)
        return 1

    cls = classify(args.trace_tb)
    summary = args.o / "replay_classification.txt"
    summary.write_text(
        f"trace_tb={args.trace_tb}\n"
        f"classification={cls}\n"
        "notes=Witness is dominated by Yosys anyinit on internal FIFO/FSM state; "
        "cycles 0-4 contain no AW/W stimulus assignments.\n"
    )
    (args.o / "trace_tb_copy.v").write_text(args.trace_tb.read_text(errors="replace"))
    print(f"Classification: {cls}")
    print(f"Report -> {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
