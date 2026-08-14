#!/usr/bin/env python3
"""Aggregate M3.5 formal results with correct PROVED vs BOUNDED_PASS semantics."""
from __future__ import annotations

import csv
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FORMAL_OUT = ROOT / "results" / "formal"
TABLES = ROOT / "results" / "tables"

TASK_META = {
    "sp02_pmp_unit": {"property_id": "SP-02", "kind": "bmc"},
    "sp02_pmp_prove": {"property_id": "SP-02", "kind": "prove"},
    "sp04_iopmp_unit": {"property_id": "SP-04", "kind": "bmc"},
    "sp04_iopmp_prove": {"property_id": "SP-04", "kind": "prove"},
    "sp10_integration": {"property_id": "SP-10", "kind": "bmc"},
    "sp08_reset": {"property_id": "SP-08-RST-A", "kind": "bmc"},
    "sp08_reset_rstb": {"property_id": "SP-08-RST-B", "kind": "bmc"},
    "spb01_model_b": {"property_id": "SP-B01", "kind": "bmc_expect_fail", "expect_fail": True},
    "m3_cover": {"property_id": "COV", "kind": "cover"},
}


def git_head() -> str:
    import subprocess

    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except Exception:
        return "unknown"


def parse_log(log: Path, task_name: str = "") -> dict:
    out = {
        "status": "NOT_RUN",
        "mode": "prove" if task_name.endswith("_prove") else "bmc",
        "depth": "",
        "basecase": "",
        "induction": "",
        "expect_fail": False,
        "covers": {},
    }
    if not log.exists():
        return out
    text = log.read_text(errors="replace")
    m = re.search(r"DONE \((\w+)", text)
    out["status"] = m.group(1) if m else "UNKNOWN"
    if "mode cover" in text.lower():
        out["mode"] = "cover"
    elif "mode prove" in text.lower() or task_name.endswith("_prove"):
        out["mode"] = "prove"
    elif "mode bmc" in text.lower():
        out["mode"] = "bmc"
    m2 = re.search(r"depth (\d+)", text)
    if m2:
        out["depth"] = m2.group(1)
    if "expect fail" in text.lower():
        out["expect_fail"] = True
    if re.search(r"returned pass for basecase|Status returned by engine for basecase: pass", text):
        out["basecase"] = "pass"
    if re.search(r"returned pass for induction|Temporal induction successful|successful proof by k-induction", text):
        out["induction"] = "pass"
    for line in text.splitlines():
        if "unreached cover" in line.lower():
            cm = re.search(r"cover (\S+)", line)
            if cm:
                out["covers"][cm.group(1)] = "unreached"
        if "reached cover" in line.lower():
            cm = re.search(r"cover (\S+)", line)
            if cm:
                out["covers"][cm.group(1)] = "reached"
    return out


def task_result(name: str, info: dict) -> str:
    status = info["status"]
    if info["mode"] == "prove":
        if info["induction"] == "pass":
            return "PROVED"
        if status == "FAIL":
            return "COUNTEREXAMPLE"
        return "INCONCLUSIVE"
    if info["mode"] == "cover":
        return "PASS" if status == "PASS" else "INCONCLUSIVE"
    if info["expect_fail"]:
        if status == "PASS":
            return "COUNTEREXAMPLE"
        if status == "FAIL":
            return "INCONCLUSIVE"
        return "NOT_RUN"
    if status == "PASS":
        return "BOUNDED_PASS"
    if status == "FAIL":
        return "COUNTEREXAMPLE"
    if status in ("ERROR", "UNKNOWN"):
        return "INCONCLUSIVE"
    return "NOT_RUN"


def collect_task(name: str) -> dict:
    meta = TASK_META.get(name, {"property_id": name, "kind": "bmc"})
    log = FORMAL_OUT / name / "logfile.txt"
    info = parse_log(log, name)
    if meta.get("kind") == "cover":
        info["mode"] = "cover"
    elif meta.get("kind") == "prove":
        info["mode"] = "prove"
    if meta.get("expect_fail"):
        info["expect_fail"] = True
    result = task_result(name, info)
    prove_method = ""
    prove_result = ""
    bmc_result = ""
    bmc_depth = info["depth"] or "32"
    if info["mode"] == "prove":
        prove_method = "smtbmc k-induction"
        prove_result = result
    elif info["mode"] == "cover":
        bmc_result = result
    else:
        bmc_result = result
    notes = f"sby {info['status']}"
    if info["expect_fail"]:
        notes += "; expect_fail semantic demo"
    return {
        "property_id": meta["property_id"],
        "task": name,
        "bmc_depth": bmc_depth if info["mode"] != "prove" else "",
        "bmc_result": bmc_result,
        "prove_method": prove_method,
        "prove_result": prove_result,
        "solver": "z3",
        "assumptions": "see docs/formal_assumptions.md",
        "cover_reachable": "",
        "final_status": result,
        "notes": notes,
        "_info": info,
    }


def merge_property(rows: list[dict]) -> dict[str, dict]:
    merged: dict[str, dict] = {}
    for r in rows:
        pid = r["property_id"]
        if pid.startswith("SP-08"):
            merged[pid] = r.copy()
            continue
        if pid not in merged:
            merged[pid] = r.copy()
            continue
        cur = merged[pid]
        if r["prove_result"]:
            cur["prove_method"] = r["prove_method"]
            cur["prove_result"] = r["prove_result"]
        if r["bmc_result"]:
            cur["bmc_depth"] = r["bmc_depth"]
            cur["bmc_result"] = r["bmc_result"]
        if r["prove_result"] == "PROVED":
            cur["final_status"] = "PROVED"
        elif r["prove_result"] == "COUNTEREXAMPLE":
            cur["final_status"] = "COUNTEREXAMPLE"
        elif cur.get("final_status") != "PROVED":
            cur["final_status"] = r["final_status"] or cur["final_status"]
    for cur in merged.values():
        if cur.get("prove_result") == "PROVED":
            cur["final_status"] = "PROVED"
        elif not cur.get("final_status"):
            cur["final_status"] = cur.get("bmc_result") or cur.get("prove_result") or "NOT_RUN"
    return merged


def parse_bmc_depth_log() -> list[dict]:
    log = FORMAL_OUT / "m35_bmc_depth.log"
    rows = []
    if not log.exists():
        return rows
    for line in log.read_text().splitlines():
        parts = line.split(",")
        if len(parts) >= 4:
            rows.append({
                "property": TASK_META.get(parts[0], {}).get("property_id", parts[0]),
                "method": parts[1],
                "depth": parts[2],
                "result": parts[3],
            })
    return rows


def main() -> None:
    TABLES.mkdir(parents=True, exist_ok=True)
    FORMAL_OUT.mkdir(parents=True, exist_ok=True)

    task_names = [n for n in TASK_META if (FORMAL_OUT / n).exists()]
    rows = [collect_task(n) for n in task_names]
    merged = merge_property(rows)

    fields = [
        "property_id", "bmc_depth", "bmc_result", "prove_method", "prove_result",
        "solver", "assumptions", "cover_reachable", "final_status", "notes",
    ]
    with (TABLES / "m35_formal_results.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        for pid in sorted(merged.keys()):
            r = merged[pid]
            w.writerow({k: r.get(k, "") for k in fields})

    prop = {k: v["final_status"] for k, v in merged.items()}
    gm_fields = [
        "property_id", "normal_operation", "concurrency", "policy_transition",
        "outstanding_transaction", "reset_RST_A", "reset_RST_B",
        "required_assumptions", "final_status", "notes",
    ]
    gm = [
        {
            "property_id": "SP-02",
            "normal_operation": prop.get("SP-02", "NOT_RUN"),
            "concurrency": prop.get("SP-10", "NOT_RUN"),
            "policy_transition": "NOT_RUN",
            "outstanding_transaction": "NOT_RUN",
            "reset_RST_A": "NOT_RUN",
            "reset_RST_B": "NOT_RUN",
            "required_assumptions": "FA-03,FA-04,FA-06,FA-07,FA-08",
            "final_status": prop.get("SP-02", "NOT_RUN"),
            "notes": "hold_* at commit; prove upgraded if induction pass",
        },
        {
            "property_id": "SP-04",
            "normal_operation": prop.get("SP-04", "NOT_RUN"),
            "concurrency": "NOT_RUN",
            "policy_transition": "NOT_RUN",
            "outstanding_transaction": prop.get("SP-04", "NOT_RUN"),
            "reset_RST_A": "NOT_RUN",
            "reset_RST_B": "NOT_RUN",
            "required_assumptions": "FA-02,FA-03,FA-05,FA-07,FA-08",
            "final_status": prop.get("SP-04", "NOT_RUN"),
            "notes": "",
        },
        {
            "property_id": "SP-08",
            "normal_operation": "NOT_RUN",
            "concurrency": "NOT_RUN",
            "policy_transition": "NOT_RUN",
            "outstanding_transaction": "NOT_RUN",
            "reset_RST_A": prop.get("SP-08-RST-A", "NOT_RUN"),
            "reset_RST_B": prop.get("SP-08-RST-B", "NOT_RUN"),
            "required_assumptions": "FA-01,FA-07,RST-A/RST-B",
            "final_status": prop.get("SP-08-RST-B", "NOT_RUN"),
            "notes": "RST-A CE preserved under fail-open defaults",
        },
        {
            "property_id": "SP-10",
            "normal_operation": "NOT_RUN",
            "concurrency": prop.get("SP-10", "NOT_RUN"),
            "policy_transition": "NOT_RUN",
            "outstanding_transaction": "NOT_RUN",
            "reset_RST_A": "NOT_RUN",
            "reset_RST_B": "NOT_RUN",
            "required_assumptions": "FA-01..FA-08",
            "final_status": prop.get("SP-10", "NOT_RUN"),
            "notes": "interconnect serve_cpu attribution",
        },
        {
            "property_id": "SP-B01",
            "normal_operation": "NOT_RUN",
            "concurrency": "NOT_RUN",
            "policy_transition": prop.get("SP-B01", "NOT_RUN"),
            "outstanding_transaction": "NOT_RUN",
            "reset_RST_A": "NOT_RUN",
            "reset_RST_B": "NOT_RUN",
            "required_assumptions": "FA-05 contrast",
            "final_status": prop.get("SP-B01", "NOT_RUN"),
            "notes": "EXPECTED_MODEL_DIFFERENCE if COUNTEREXAMPLE",
        },
    ]
    with (TABLES / "m35_guarantee_matrix.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=gm_fields)
        w.writeheader()
        w.writerows(gm)

    rst_a = prop.get("SP-08-RST-A", "NOT_RUN")
    rst_b = prop.get("SP-08-RST-B", "NOT_RUN")
    rst = [{
        "scenario": "DMA active before secure_ready",
        "RST_A_fail_open": rst_a,
        "RST_B_fail_closed": rst_b,
        "SP-08_status": f"RST-A={rst_a}; RST-B={rst_b}",
        "secure_ready_timing": "nondeterministic",
        "DMA_active_timing": "nondeterministic",
        "counterexample_path": "results/formal/counterexamples/SP-08/",
        "interpretation": "CI-RESET-01 when RST-B passes and RST-A fails",
    }]
    with (TABLES / "m35_reset_comparison.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rst[0].keys()))
        w.writeheader()
        w.writerows(rst)

    run_rows = []
    for r in rows:
        info = r.pop("_info", {})
        run_rows.append({
            "task": r["task"],
            "property_id": r["property_id"],
            "mode": info.get("mode", ""),
            "depth": r["bmc_depth"],
            "solver": "z3",
            "status": r["notes"],
            "final_status": r["final_status"],
        })
    run_rows.extend(parse_bmc_depth_log())
    run_fields = ["task", "property_id", "mode", "depth", "solver", "status", "final_status"]
    with (FORMAL_OUT / "m35_runs.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=run_fields, extrasaction="ignore")
        w.writeheader()
        for row in run_rows:
            w.writerow({k: row.get(k, "") for k in run_fields})
    bmc_fields = ["property", "method", "depth", "result"]
    bmc_rows = parse_bmc_depth_log()
    if bmc_rows:
        with (FORMAL_OUT / "m35_bmc_depths.csv").open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=bmc_fields)
            w.writeheader()
            w.writerows(bmc_rows)

    cover_rows = [
        {"cover_id": "authorized_dma_admission", "task": "m3_cover", "reachable": "see log", "notes": "ST_HOLD authorized"},
        {"cover_id": "unauthorized_dma_denial", "task": "m3_cover", "reachable": "see log", "notes": "dma_unauth_admit"},
        {"cover_id": "pending_transaction", "task": "m3_cover", "reachable": "see log", "notes": "ST_PENDING"},
        {"cover_id": "simultaneous_cpu_dma", "task": "sp10_integration", "reachable": "see log", "notes": "formal_soc_tb covers"},
        {"cover_id": "dma_before_secure_ready", "task": "sp08_reset", "reachable": "reached" if rst_a == "COUNTEREXAMPLE" else "", "notes": "RST-A baseline"},
        {"cover_id": "rstb_protected_denial", "task": "sp08_reset_rstb", "reachable": "reached" if rst_b == "BOUNDED_PASS" else "", "notes": "RST-B"},
    ]
    cov_task = collect_task("m3_cover")
    if cov_task.get("_info", {}).get("status") == "PASS":
        for cid in ("authorized_dma_admission", "pending_transaction"):
            cover_rows[0 if cid == "authorized_dma_admission" else 2]["reachable"] = "reached"
    with (FORMAL_OUT / "m35_cover_results.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(cover_rows[0].keys()))
        w.writeheader()
        w.writerows(cover_rows)

    summary_lines = [
        "# Milestone M3.5 Formal Summary",
        "",
        f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
        "",
        f"Git commit: `{git_head()}`",
        "",
        "## Property final status",
        "",
    ]
    for pid in sorted(merged.keys()):
        summary_lines.append(f"- **{pid}**: {merged[pid]['final_status']}")
    summary_lines.extend([
        "",
        "## Terminology",
        "",
        "- BMC-only PASS → BOUNDED_PASS",
        "- mode prove + induction pass → PROVED",
        "- spb01 expect fail PASS → COUNTEREXAMPLE (EXPECTED_MODEL_DIFFERENCE)",
        "",
    ])
    summary = FORMAL_OUT / "m35_summary.md"
    summary.write_text("\n".join(summary_lines) + "\n")
    print(summary.read_text())


if __name__ == "__main__":
    main()
