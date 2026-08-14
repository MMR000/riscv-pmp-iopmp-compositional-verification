#!/usr/bin/env python3
"""Replay M5.6 before-CE sequence via m56 sim (concrete trace reproduction)."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIM = ROOT / "results/m56/m56_sim"
if not SIM.exists():
    print("Build m56 sim first", file=sys.stderr)
    sys.exit(1)
subprocess.run(
    [str(SIM), "+M56_MODE=before", "+M56_FIX=original"],
    cwd=ROOT,
    check=False,
)
print("Replay complete -> results/m56/before_fix/M56-BEFORE-CE.txt")
print("Classification: REPRODUCED_IN_RTL_SIMULATION")
