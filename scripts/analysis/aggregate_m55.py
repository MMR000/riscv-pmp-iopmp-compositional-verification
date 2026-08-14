#!/usr/bin/env python3
"""Aggregate M5.5 diagnostic outputs into summary and root-cause table."""
from __future__ import annotations

import csv
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "results"
M55 = RESULTS / "m55"
TABLES = RESULTS / "tables"


def git_head() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip()
    except Exception:
        return "unknown"


def read_csv(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def main() -> None:
    M55.mkdir(parents=True, exist_ok=True)
    nsaid = read_csv(TABLES / "m55_nsaid_matrix.csv")
    asym = [r for r in nsaid if r.get("classification", "").strip() == "ASymmetric"]
    sym_deny_1 = next((r for r in nsaid if r.get("NSAID") == "1"), {})

    root = [
        {
            "finding": "W-channel forward during IOPMP verification",
            "classification": "RTL_IMPLEMENTATION_DEFECT",
            "location": "rv_iopmp_data_abstractor_axi.sv:129",
            "trigger": "Authorized write immediately before unauthorized write (same session)",
            "read_write_symmetry": "Read denies; write data can reach initiator without AW",
            "evidence": "results/m55/baseline/M55-WRITE-CE-BASELINE.txt",
        },
        {
            "finding": "Fresh-session NSAID=1 symmetric deny",
            "classification": "EXPECTED_RTL_BEHAVIOR",
            "location": "rv_iopmp_matching_logic.sv SETUP/ERROR",
            "trigger": "Reset between transactions, no prior initiator write",
            "read_write_symmetry": "Both DENY",
            "evidence": "results/tables/m55_nsaid_matrix.csv NSAID=1",
        },
    ]

    with (TABLES / "m55_root_cause.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(root[0].keys()))
        w.writeheader()
        w.writerows(root)

    summary = f"""# M5.5 Summary

## Git
- Branch: m55-write-path-investigation
- HEAD: {git_head()}
- Upstream RTL: zero-day-labs/riscv-iopmp @ a029581351aaf8a71831916aa8877895364e6e98

## Primary root cause
**RTL_IMPLEMENTATION_DEFECT** in `rv_iopmp_data_abstractor_axi`: the W beat is presented to
`axi_demux` while AW is still gated during IOPMP verification. After an authorized write routes
AW/W to the initiator, a subsequent denied write can still deliver **W to the initiator** using
the demux route FIFO from the prior transaction. Matching logic correctly returns `allow=0`.

## Original M5 anomaly reproduction
- Sequence: `install_policy(nsaid=0)` → authorized write → unauthorized write (NSAID=1)
- Observed: READ deny / WRITE allow (memory modified, BRESP OKAY)
- Baseline: `results/m55/baseline/M55-WRITE-CE-BASELINE.txt`
- Waveform: `results/m55/baseline/M55-WRITE-CE-BASELINE.vcd`

## Matching read control
- Unauthorized read (NSAID=1) **DENY** with SLVERR when probed after anomalous write
- With per-NSAID reset and no prior auth write in session: NSAID=1 READ/WRITE both **DENY**

## NSAID matrix
- Rows: {len(nsaid)}
- Asymmetric rows (stale-session sweep artifact): {len(asym)}
- Clean NSAID=1 (reset per row): READ={sym_deny_1.get('READ_result','?')} WRITE={sym_deny_1.get('WRITE_result','?')}

## EV-2 re-evaluation
**EV-2 CONFIRMED_WITH_IMPLEMENTATION_DEFECT** — reset/default enforcement findings stand; M1-03
write-ALLOW is a write-path implementation defect, not spec-compliant authorization.

## Paper impact
**ADDS_IMPLEMENTATION_CASE_STUDY** — conservative access-control defect on W-channel gating.

## Recommended next step
**B** — Formalize confirmed RTL defect (local patch in `patches/zero-day-iopmp/`).
"""
    (M55 / "m55_summary.md").write_text(summary)
    print(f"Wrote {M55 / 'm55_summary.md'}")


if __name__ == "__main__":
    main()
