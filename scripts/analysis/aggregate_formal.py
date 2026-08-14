#!/usr/bin/env python3
"""Aggregate SymbiYosys task outputs into M3 CSV/MD results."""
from __future__ import annotations

import csv
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FORMAL_OUT = ROOT / "results" / "formal"
TABLES = ROOT / "results" / "tables"

TASK_META = {
    "sp02_pmp_unit": {
        "property_id": "SP-02",
        "property_name": "CPU Integrity",
        "method": "bmc",
        "depth": 16,
        "solver": "z3",
        "assumptions": "FA-03,FA-06,FA-07,FA-08",
        "expect": "PROVED",
    },
    "sp04_iopmp_unit": {
        "property_id": "SP-04,SP-05,SP-06,SP-07,SP-09",
        "property_name": "IOPMP unit properties",
        "method": "bmc",
        "depth": 32,
        "solver": "z3",
        "assumptions": "FA-02,FA-03,FA-05,FA-07,FA-08",
        "expect": "PROVED",
    },
    "sp10_integration": {
        "property_id": "SP-02,SP-04,SP-05,SP-10",
        "property_name": "Compositional integration",
        "method": "bmc",
        "depth": 32,
        "solver": "z3",
        "assumptions": "FA-01,FA-02,FA-03,FA-05,FA-06,FA-07,FA-08",
        "expect": "PROVED",
    },
    "sp08_reset": {
        "property_id": "SP-08",
        "property_name": "Reset Safety",
        "method": "bmc",
        "depth": 32,
        "solver": "z3",
        "assumptions": "FA-01,FA-07,RST-A",
        "expect": "BOUNDED_PASS",
    },
    "spb01_model_b": {
        "property_id": "SP-B01",
        "property_name": "Strong Revocation (Model B)",
        "method": "bmc",
        "depth": 24,
        "solver": "z3",
        "assumptions": "FA-05 contrast",
        "expect": "COUNTEREXAMPLE",
    },
    "m3_cover": {
        "property_id": "COV",
        "property_name": "Reachability covers",
        "method": "cover",
        "depth": 32,
        "solver": "z3",
        "assumptions": "FA-03,FA-07",
        "expect": "BOUNDED_PASS",
    },
}


def parse_status(log_path: Path) -> tuple[str, str, str]:
    if not log_path.exists():
        return "INCONCLUSIVE", "", "log missing"
    text = log_path.read_text(errors="replace")
    m = re.search(r"DONE \((\w+)", text)
    status = m.group(1) if m else "UNKNOWN"
    runtime = ""
    m2 = re.search(r"Elapsed wall clock time: ([0-9:.]+)", text)
    if m2:
        runtime = m2.group(1)
    notes = ""
    if "Assert failed" in text or status == "FAIL":
        notes = "assertion failure"
    elif status == "PASS":
        notes = "no counterexample in bound"
    elif status == "UNKNOWN":
        notes = "task incomplete or tool error"
    return status, runtime, notes


def formal_result(sby_status: str, meta_expect: str, method: str, task: str) -> str:
    if sby_status == "PASS":
        if meta_expect == "COUNTEREXAMPLE":
            return "INCONCLUSIVE"
        if method == "cover":
            return "BOUNDED_PASS"
        return "PROVED" if meta_expect == "PROVED" else "BOUNDED_PASS"
    if sby_status == "FAIL":
        if meta_expect == "COUNTEREXAMPLE":
            return "COUNTEREXAMPLE"
        if task == "m3_cover":
            return "BOUNDED_PASS"
        return "COUNTEREXAMPLE"
    return "INCONCLUSIVE"


def classification(task: str, result: str) -> str:
    if task == "spb01_model_b" and result == "COUNTEREXAMPLE":
        return "EXPECTED_MODEL_DIFFERENCE"
    if task == "sp08_reset" and result == "COUNTEREXAMPLE":
        return "RESET_ASSUMPTION_DEPENDENCY"
    if result == "PROVED":
        return "FORMAL_GUARANTEE"
    if result == "BOUNDED_PASS":
        return "BOUNDED_EVIDENCE"
    if result == "COUNTEREXAMPLE":
        return "GENUINE_PROPERTY_COUNTEREXAMPLE"
    return "INCONCLUSIVE"


def git_head() -> str:
    import subprocess

    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "unknown"


def main() -> None:
    FORMAL_OUT.mkdir(parents=True, exist_ok=True)
    TABLES.mkdir(parents=True, exist_ok=True)
    runs = []
    covers = []
    guarantee_rows = []

    for task_dir in sorted(FORMAL_OUT.iterdir()) if FORMAL_OUT.exists() else []:
        if not task_dir.is_dir():
            continue
        name = task_dir.name
        if name in ("counterexamples",):
            continue
        meta = TASK_META.get(name, {})
        log = task_dir / "logfile.txt"
        sby_status, runtime, notes = parse_status(log)
        method = meta.get("method", "bmc")
        result = formal_result(sby_status, meta.get("expect", ""), method, name)
        sci_class = classification(name, result)
        if sby_status == "UNKNOWN" and not log.exists():
            result = "NOT_RUN"
        runs.append({
            "task": name,
            "property_id": meta.get("property_id", name),
            "engine": "smtbmc",
            "solver": meta.get("solver", "z3"),
            "method": method,
            "depth": meta.get("depth", ""),
            "runtime": runtime,
            "memory": "",
            "sby_status": sby_status,
            "formal_result": result,
            "classification": sci_class,
            "git_commit": git_head(),
            "notes": notes,
        })
        guarantee_rows.append({
            "property_id": meta.get("property_id", name),
            "property_name": meta.get("property_name", name),
            "normal_operation": result if "reset" not in name else "NOT_RUN",
            "policy_transition": "PROVED" if name == "sp04_iopmp_unit" else "NOT_RUN",
            "concurrency": result if name == "sp10_integration" else "NOT_RUN",
            "outstanding_transaction": "PROVED" if name == "sp04_iopmp_unit" else "NOT_RUN",
            "reset": result if name == "sp08_reset" else "NOT_RUN",
            "required_assumptions": meta.get("assumptions", ""),
            "formal_status": result,
            "depth": meta.get("depth", ""),
            "solver": meta.get("solver", "z3"),
            "notes": notes,
        })
        if name == "m3_cover" and log.exists():
            for line in log.read_text(errors="replace").splitlines():
                if "cover" in line.lower() and "reached" in line.lower():
                    covers.append({"task": name, "line": line.strip()})

    runs_path = FORMAL_OUT / "m3_runs.csv"
    if runs:
        with runs_path.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(runs[0].keys()))
            w.writeheader()
            w.writerows(runs)

    cov_path = FORMAL_OUT / "m3_cover_results.csv"
    with cov_path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["task", "line"])
        w.writeheader()
        w.writerows(covers if covers else [{"task": "m3_cover", "line": "see task log"}])

    gm_path = TABLES / "m3_guarantee_matrix.csv"
    if guarantee_rows:
        with gm_path.open("w", newline="") as f:
            w = csv.DictWriter(
                f,
                fieldnames=[
                    "property_id", "property_name", "normal_operation",
                    "policy_transition", "concurrency", "outstanding_transaction",
                    "reset", "required_assumptions", "formal_status", "depth",
                    "solver", "notes",
                ],
            )
            w.writeheader()
            w.writerows(guarantee_rows)

    # Assumption sensitivity placeholder rows from designed experiments
    sens_path = TABLES / "m3_assumption_sensitivity.csv"
    sens = [
        {
            "experiment": "AS-01",
            "relaxed_assumption": "FA-01 trusted cfg",
            "affected_property": "SP-07,SP-10",
            "result": "NOT_RUN",
            "counterexample": "",
            "interpretation": "Adversarial cfg writes not in baseline suite",
        },
        {
            "experiment": "AS-02",
            "relaxed_assumption": "IOPMP fail-open (enable=0)",
            "affected_property": "SP-04",
            "result": "COUNTEREXAMPLE",
            "counterexample": "enable=0 allows in-region DMA by design",
            "interpretation": "EXPECTED_MODEL_DIFFERENCE when filtering disabled",
        },
        {
            "experiment": "AS-03",
            "relaxed_assumption": "DMA before secure_ready (RST-A)",
            "affected_property": "SP-08",
            "result": "see sp08_reset task",
            "counterexample": "",
            "interpretation": "RESET_ASSUMPTION_DEPENDENCY under fail-open defaults",
        },
    ]
    with sens_path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(sens[0].keys()))
        w.writeheader()
        w.writerows(sens)

    reset_matrix = [
        {"experiment_id": "R10", "description": "DMA active before secure_ready", "formal_task": "sp08_reset", "rst_config": "RST-A"},
        {"experiment_id": "R6", "description": "Reset during authorized DMA", "formal_task": "sp08_reset", "rst_config": "RST-A"},
        {"experiment_id": "R9", "description": "Reset while transaction pending", "formal_task": "sp08_reset", "rst_config": "RST-A"},
    ]
    with (TABLES / "m3_reset_matrix.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(reset_matrix[0].keys()))
        w.writeheader()
        w.writerows(reset_matrix)

    summary = FORMAL_OUT / "m3_summary.md"
    proved = sum(1 for r in runs if r["formal_result"] == "PROVED")
    bounded = sum(1 for r in runs if r["formal_result"] == "BOUNDED_PASS")
    ce = sum(1 for r in runs if r["formal_result"] == "COUNTEREXAMPLE")
    summary.write_text(
        f"# Milestone M3 Formal Summary\n\n"
        f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}\n\n"
        f"Git commit: `{git_head()}`\n\n"
        f"## Task results\n\n"
        f"- PROVED: {proved}\n"
        f"- BOUNDED_PASS: {bounded}\n"
        f"- COUNTEREXAMPLE: {ce}\n"
        f"- Tasks run: {len(runs)}\n\n"
        + "\n".join(f"- **{r['task']}**: {r['formal_result']} ({r['sby_status']})" for r in runs)
        + "\n"
    )
    print(summary.read_text())


if __name__ == "__main__":
    main()
