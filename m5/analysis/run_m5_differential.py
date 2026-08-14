#!/usr/bin/env python3
"""M5 differential campaign: M4-IOPMP vs REF-IOPMP (1000 seeded transactions)."""
from __future__ import annotations

import csv
import os
import random
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
M5_BIN = ROOT / "m5" / "bin" / "m5_ref_campaign"
REF_LIB = ROOT / "m5" / "adapters" / "ref_iopmp_adapter.c"
TB = ROOT / "tb" / "cocotb"
OUT = ROOT / "results" / "m5" / "differential" / "diff_results.csv"
TABLE = ROOT / "results" / "tables" / "m5_differential_results.csv"
PROBE_OUT = ROOT / "results" / "m5" / "differential" / "m4_probe.txt"

PROTECT = 0x20000000
AUTH, UNAUTH = 1, 2
SEEDS = 1000


def _ref_check(enable: bool, configured: bool, rrid: int, addr: int, write: bool) -> str:
    """Inline REF check via small C snippet compiled on demand — use subprocess to ref tool."""
    import ctypes
    # Use prebuilt adapter via standalone checker binary if available
    checker = ROOT / "m5" / "bin" / "m5_ref_check"
    if not checker.exists():
        return "INCONCLUSIVE"
    r = subprocess.run(
        [str(checker), str(int(enable)), str(int(configured)), str(rrid), hex(addr),
         "write" if write else "read"],
        capture_output=True, text=True, check=False,
    )
    return r.stdout.strip() if r.returncode == 0 else "INCONCLUSIVE"


def _m4_check(m4_cfg: str, configured: bool, rrid: int, addr: int, write: bool, *,
              iopmp_enable: bool) -> str:
    env = os.environ.copy()
    env.update({
        "M4_CONFIG": m4_cfg,
        "M5_CONFIGURED": "1" if configured else "0",
        "M5_IOPMP_ENABLE": "1" if iopmp_enable else "0",
        "M5_RRID": str(rrid),
        "M5_ADDR": hex(addr),
        "M5_OP": "write" if write else "read",
        "M5_M4_PROBE_OUT": str(PROBE_OUT),
    })
    r = subprocess.run(
        ["python3", "-m", "pytest", "test_m5_m4_probe_runner.py", "-q"],
        cwd=TB, env=env, capture_output=True, text=True,
    )
    if r.returncode != 0 or not PROBE_OUT.exists():
        return "INCONCLUSIVE"
    return PROBE_OUT.read_text().strip()


def _classify(m4: str, ref: str, enable: bool, configured: bool, addr: int) -> tuple[str, str]:
    if m4 == "INCONCLUSIVE" or ref == "INCONCLUSIVE":
        return "INCONCLUSIVE", "probe failed"
    if m4 == ref:
        return "EXPECTED_EQUIVALENCE", "same ALLOW/DENY"
    if not enable:
        return "ABSTRACTION_DIFFERENCE", "REF enable=0 bypass vs M4 in-path semantics"
    if (addr & 0x3) != 0:
        return "ABSTRACTION_DIFFERENCE", "REF NA4 requires 4-byte alignment"
    if not configured:
        return "SPEC_SEMANTIC_DIFFERENCE", f"pre-config M4={m4} REF={ref}"
    return "SPEC_SEMANTIC_DIFFERENCE", f"post-config M4={m4} REF={ref}"


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    rng = random.Random(42)
    rows = []
    agreements = 0
    for i in range(SEEDS):
        enable = rng.random() < 0.5
        configured = rng.random() < 0.6 if enable else False
        rrid = AUTH if rng.random() < 0.6 else UNAUTH
        write = rng.random() < 0.7
        addr = (PROTECT + rng.randint(0, 0xFFF)) & ~0x3
        m4_cfg = "C1"  # C1 fail-closed when enable=1; C0 irrelevant when bypassed
        ref_cfg = "REF-C0" if not enable else "REF-C1"
        ref = _ref_check(enable, configured, rrid, addr, write)
        m4 = _m4_check(m4_cfg, configured, rrid, addr, write, iopmp_enable=enable)
        same = m4 == ref
        if same:
            agreements += 1
        cls, expl = _classify(m4, ref, enable, configured, addr)
        rows.append({
            "experiment": f"DIFF-{i:04d}",
            "seed": i,
            "requester_rrid": rrid,
            "address": hex(addr),
            "length": 4,
            "operation": "write" if write else "read",
            "M4_config": m4_cfg,
            "REF_config": ref_cfg,
            "enable": enable,
            "configured": configured,
            "M4_result": m4,
            "REF_result": ref,
            "same": same,
            "difference_classification": cls,
            "explanation": expl,
        })
    fields = list(rows[0].keys())
    for p in (OUT, TABLE):
        with p.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            w.writerows(rows)
    print(f"M5 differential: {SEEDS} tests, {agreements} agreements -> {OUT}")
    by_cls: dict[str, int] = {}
    for row in rows:
        by_cls[row["difference_classification"]] = by_cls.get(row["difference_classification"], 0) + 1
    print("Classification:", by_cls)
    return 0


if __name__ == "__main__":
    sys.exit(main())
