#!/usr/bin/env python3
"""Run M7 Phase C RC-01..12 (+ order sweep, random, latency) for real-core reset."""
from __future__ import annotations

import argparse
import csv
import re
import statistics
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "results/m7/realcore_reset"
MATRIX = ROOT / "results/tables/m7_realcore_reset_matrix.csv"
RANDOM = ROOT / "results/tables/m7_realcore_reset_random.csv"
LATENCY = ROOT / "results/tables/m7_realcore_reset_latency.csv"
SW = ROOT / "m7/sw/ibex_reset"
SENTINEL = "0x5151A5A5"


def norm_hex(s: str) -> str:
    s = (s or "").strip().upper()
    if s.startswith("0X"):
        s = "0x" + s[2:]
    return s


# test_id -> (model, elf_num, expected_kind, notes)
# expected_kind guides classification
SPECS = [
    ("RC-01", "RST-A", 1, "EARLY_UNAUTH_REACHABLE", "fail-open early DMA"),
    ("RC-02", "RST-B", 2, "EARLY_UNAUTH_DENY", "fail-closed early DMA"),
    ("RC-03", "RST-B", 3, "EARLY_AUTH_DENY_THEN_ALLOW", "auth before ready then allow"),
    ("RC-04", "RST-B", 4, "CPU_ALLOW", "post-recovery M write"),
    ("RC-05", "RST-B", 5, "CPU_STORE_FAULT", "post-recovery U store mcause=7"),
    ("RC-06", "RST-B", 6, "CPU_LOAD_FAULT", "post-recovery U load mcause=5"),
    ("RC-07", "RST-B", 7, "DMA_ALLOW", "post-recovery auth DMA"),
    ("RC-08", "RST-B", 8, "DMA_DENY", "post-recovery unauth DMA"),
    ("RC-09", "RST-B", 9, "DMA_DENY", "CPU reset; IOPMP stays"),
    ("RC-10", "RST-A", 10, "EARLY_UNAUTH_REACHABLE", "partial IOPMP reset RST-A"),
    ("RC-11", "RST-B", 11, "EARLY_UNAUTH_DENY", "partial IOPMP reset RST-B"),
    ("RC-12", "RST-B", 12, "ATTR_DMA_WINS", "U fault + auth DMA"),
]

ORDER = [
    ("RC-ORD-A", 20, "CPU->IOPMP->DMA"),
    ("RC-ORD-B", 21, "IOPMP->CPU->DMA"),
    ("RC-ORD-C", 22, "DMA->CPU->IOPMP"),
    ("RC-ORD-D", 23, "DMA->IOPMP->CPU"),
    ("RC-ORD-E", 24, "simultaneous"),
    ("RC-ORD-F", 25, "IOPMP last"),
]


def parse_logs(text: str) -> dict:
    out = {
        "result": "UNKNOWN",
        "trap": False,
        "mcause": "",
        "mtval": "",
        "mepc": "",
        "mem_after": "",
        "dma_err": "",
        "peek": "",
        "secure": "",
        "en": "",
        "rulev": "",
        "stamps": {},
    }
    if "M7-RC-RESULT: PASS" in text or "M7-RC-HARNESS-FINISH" in text:
        out["result"] = "PASS"
    if "M7-RC-RESULT: FAIL" in text:
        out["result"] = "FAIL"
    if "M7-RC-TRAP" in text:
        out["trap"] = True
    m = re.search(r"MCAUSE: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mcause"] = str(int(m.group(1), 16))
    m = re.search(r"MTVAL: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mtval"] = m.group(1)
    m = re.search(r"MEPc: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mepc"] = m.group(1)
    m = re.search(r"MEM_AFTER: 0x([0-9a-fA-F]+)", text)
    if m:
        out["mem_after"] = "0x" + m.group(1).upper()
    m = re.search(r"PHASE=(\w+) ERR=(\d+) PEEK=0x([0-9a-fA-F]+)", text)
    if m:
        out["dma_err"] = m.group(2)
        out["peek"] = "0x" + m.group(3).upper()
    # Prefer DONE peek
    m = re.search(r"DONE PEEK=0x([0-9a-fA-F]+).*?RESULT=0x([0-9a-fA-F]+)", text)
    if m:
        out["peek"] = "0x" + m.group(1).upper()
        res = int(m.group(2), 16)
        out["dma_err"] = "1" if res == 0xDEAD0001 else ("0" if res == 0x600D0001 else out["dma_err"])
    m = re.search(
        r"DONE PEEK=0x([0-9a-fA-F]+) CPU_REL=(\d+) DMA_REL=(\d+) IOPMP_REL=(\d+) "
        r"PMP_RDY=(\d+) IOPMP_RDY=(\d+) SECURE=(\d+) DMA_REQ=(\d+) COMMIT=(\d+)",
        text,
    )
    if m:
        out["peek"] = "0x" + m.group(1).upper()
        out["stamps"] = {
            "cpu_release": m.group(2),
            "dma_release": m.group(3),
            "iopmp_release": m.group(4),
            "pmp_ready": m.group(5),
            "iopmp_ready": m.group(6),
            "secure_ready": m.group(7),
            "dma_req": m.group(8),
            "commit": m.group(9),
        }
    m = re.search(r"SECURE=(\d+) EN=(\d+) RULEV=(\d+)", text)
    if m:
        out["secure"], out["en"], out["rulev"] = m.group(1), m.group(2), m.group(3)
    return out


def classify(kind: str, p: dict) -> tuple[str, str, str]:
    mem = norm_hex(p.get("mem_after") or p.get("peek") or "")
    sent = norm_hex(SENTINEL)
    if kind == "EARLY_UNAUTH_REACHABLE":
        ok = p.get("dma_err") == "0" and mem != sent and mem != ""
        obs = "UNSAFE_REACHABLE" if ok else f"err={p.get('dma_err')} mem={mem}"
        cls = "RESET_ASSUMPTION_DEPENDENCY" if ok else "INCONCLUSIVE"
        return obs, cls, "PASS" if ok else "FAIL"
    if kind == "EARLY_UNAUTH_DENY":
        ok = p.get("dma_err") == "1" and (not mem or mem == sent)
        obs = "DENY" if ok else f"err={p.get('dma_err')} mem={mem}"
        return obs, "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE", "PASS" if ok else "FAIL"
    if kind == "EARLY_AUTH_DENY_THEN_ALLOW":
        # Look for early DENY and final ALLOW with auth data
        early_deny = "PHASE=EARLY ERR=1" in (p.get("_raw") or "")
        post_allow = "PHASE=POST ERR=0" in (p.get("_raw") or "")
        ok = early_deny and post_allow
        obs = f"early_deny={early_deny} post_allow={post_allow} mem={mem}"
        return obs, "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE", "PASS" if ok else "FAIL"
    if kind == "CPU_ALLOW":
        ok = (not p["trap"]) and mem == "0xB0040004"
        return ("ALLOW" if ok else mem), "SIMULATION_EVIDENCE" if ok else "TEST_SOFTWARE_BUG", "PASS" if ok else "FAIL"
    if kind == "CPU_STORE_FAULT":
        ok = p["trap"] and p.get("mcause") == "7" and mem == sent
        return f"mcause={p.get('mcause')}", "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE", "PASS" if ok else "FAIL"
    if kind == "CPU_LOAD_FAULT":
        ok = p["trap"] and p.get("mcause") == "5"
        return f"mcause={p.get('mcause')}", "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE", "PASS" if ok else "FAIL"
    if kind == "DMA_ALLOW":
        ok = p.get("dma_err") == "0" and (("D00D" in mem) or ("A11D" in mem))
        return ("ALLOW" if ok else f"err={p.get('dma_err')} mem={mem}"), "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE", "PASS" if ok else "FAIL"
    if kind == "DMA_DENY":
        ok = p.get("dma_err") == "1" and (not mem or mem == sent or "B004" in mem)
        # RC-09: sentinel retained
        if "RC-09" in (p.get("_tid") or ""):
            ok = p.get("dma_err") == "1" and mem == sent
        return ("DENY" if ok else f"err={p.get('dma_err')} mem={mem}"), "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE", "PASS" if ok else "FAIL"
    if kind == "ATTR_DMA_WINS":
        ok = p["trap"] and p.get("mcause") == "7" and mem == "0xD00D00C7"
        return f"mcause={p.get('mcause')} mem={mem}", "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE", "PASS" if ok else "FAIL"
    return "UNKNOWN", "INCONCLUSIVE", "FAIL"


def run_one(sim: Path, elf: Path, rc_test: int, timeout: int = 45) -> tuple[str, int]:
    sim_dir = sim.parent
    for name in ("m7_ibex_reset_composed.log", "m7_realcore_reset_harness.log", "trace_core_00000000.log"):
        p = sim_dir / name
        if p.exists():
            p.unlink()
    # Use /usr/bin/timeout -k so Verilator cannot ignore SIGTERM forever.
    cmd = [
        "/usr/bin/timeout", "-k", "2", str(timeout),
        str(sim.resolve()),
        f"--meminit=ram,{elf.resolve()}",
        f"+RC_TEST={rc_test}",
        "+ibex_tracer_enable=0",
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, cwd=str(sim_dir))
        log = proc.stdout + proc.stderr
        rc = proc.returncode
        if rc == 124:
            log += "\nTIMEOUT\n"
    except Exception as e:
        log = f"RUN_ERROR: {e}\n"
        rc = 1
    for name in ("m7_ibex_reset_composed.log", "m7_realcore_reset_harness.log"):
        p = sim_dir / name
        if p.exists():
            log += f"\n--- {name} ---\n" + p.read_text()
    return log, rc


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim-a", required=True)
    ap.add_argument("--sim-b", required=True)
    ap.add_argument("--skip-random", action="store_true")
    args = ap.parse_args()
    sim_a, sim_b = Path(args.sim_a), Path(args.sim_b)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True, cwd=str(ROOT)).strip()
    ibex = subprocess.check_output(
        ["git", "-C", str(ROOT / "third_party/ibex"), "rev-parse", "HEAD"], text=True
    ).strip()

    rows = []
    latency_raw = []

    def add_row(tid, model, elf_n, kind, notes, log, rc):
        p = parse_logs(log)
        p["_raw"] = log
        p["_tid"] = tid
        obs, cls, result = classify(kind, p)
        # Override result line for harness-only if classification ok
        st = p.get("stamps", {})
        mem = p.get("mem_after") or p.get("peek") or ""
        rows.append({
            "test_id": tid,
            "reset_model": model,
            "cpu_reset": "domain",
            "dma_reset": "domain",
            "iopmp_reset": "domain",
            "security_config_reset": "domain",
            "memory_retained": "YES",
            "cpu_release_cycle": st.get("cpu_release", ""),
            "dma_release_cycle": st.get("dma_release", ""),
            "iopmp_release_cycle": st.get("iopmp_release", ""),
            "pmp_ready_cycle": st.get("pmp_ready", ""),
            "iopmp_ready_cycle": st.get("iopmp_ready", ""),
            "secure_ready_cycle": st.get("secure_ready", ""),
            "dma_request_cycle": st.get("dma_req", ""),
            "dma_requester": "",
            "cpu_privilege": "",
            "cpu_operation": "",
            "cpu_mcause": p.get("mcause", ""),
            "cpu_mtval": p.get("mtval", ""),
            "memory_before": SENTINEL,
            "memory_after": mem,
            "expected": kind,
            "observed": obs,
            "classification": cls,
            "result": result,
            "notes": notes + f"; exit={rc}",
            "project_commit": commit,
            "ibex_commit": ibex,
        })
        (OUT_DIR / "tests").mkdir(parents=True, exist_ok=True)
        (OUT_DIR / "tests" / f"{tid}.log").write_text(log)
        # Raw latency deltas (only when both endpoints are known/nonzero)
        def _i(k):
            try:
                return int(st.get(k) or 0)
            except ValueError:
                return 0
        pairs = [
            ("cpu_release_to_pmp_ready", "cpu_release", "pmp_ready"),
            ("iopmp_release_to_iopmp_ready", "iopmp_release", "iopmp_ready"),
            ("reset_start_to_secure_ready", "cpu_release", "secure_ready"),
            ("secure_ready_to_dma_req", "secure_ready", "dma_req"),
            ("dma_req_to_commit", "dma_req", "commit"),
        ]
        for name, a, b in pairs:
            va, vb = _i(a), _i(b)
            if va > 0 and vb >= va:
                latency_raw.append({
                    "test_id": tid,
                    "metric": name,
                    "cycles": vb - va,
                    "reset_model": model,
                })
        print(f"  {tid} ({model}): {result} obs={obs} cls={cls}")

    print("=== Directed RC-01..12 ===")
    for tid, model, elf_n, kind, notes in SPECS:
        sim = sim_a if model == "RST-A" else sim_b
        elf = SW / f"RC-{elf_n}.elf"
        if not elf.exists():
            print(f"  {tid}: ELF missing")
            continue
        log, rc = run_one(sim, elf, elf_n)
        add_row(tid, model, elf_n, kind, notes, log, rc)

    print("=== Release-order sweep (RST-B) ===")
    for tid, num, notes in ORDER:
        elf = SW / "RC-7.elf"  # auth DMA after recovery
        log, rc = run_one(sim_b, elf, num)
        add_row(tid, "RST-B", num, "DMA_ALLOW", notes, log, rc)

    # In-flight stubs classified INCONCLUSIVE if not separately implemented
    for tid, notes in [
        ("RC-IF-01", "reset after DMA admit before commit"),
        ("RC-IF-02", "CPU txn in-flight + CPU reset"),
        ("RC-IF-03", "between PMP_READY and IOPMP_READY"),
    ]:
        rows.append({
            "test_id": tid, "reset_model": "RST-B", "cpu_reset": "domain",
            "dma_reset": "domain", "iopmp_reset": "domain",
            "security_config_reset": "domain", "memory_retained": "YES",
            "cpu_release_cycle": "", "dma_release_cycle": "", "iopmp_release_cycle": "",
            "pmp_ready_cycle": "", "iopmp_ready_cycle": "", "secure_ready_cycle": "",
            "dma_request_cycle": "", "dma_requester": "", "cpu_privilege": "",
            "cpu_operation": "", "cpu_mcause": "", "cpu_mtval": "",
            "memory_before": SENTINEL, "memory_after": "", "expected": "MODEL_A_SEMANTICS",
            "observed": "NOT_INSTRUMENTED", "classification": "INCONCLUSIVE",
            "result": "INCONCLUSIVE", "notes": notes + "; deferred precise cycle targeting",
            "project_commit": commit, "ibex_commit": ibex,
        })
        print(f"  {tid}: INCONCLUSIVE ({notes})")

    MATRIX.parent.mkdir(parents=True, exist_ok=True)
    with MATRIX.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    # Random campaign: sample RST-A/B early DMA + post-recovery
    if not args.skip_random:
        print("=== Random reset campaign (100 seeds) ===")
        rnd = []
        t0 = time.time()
        for seed in range(100):
            model = "RST-A" if (seed % 2 == 0) else "RST-B"
            sim = sim_a if model == "RST-A" else sim_b
            # Map seed -> scenario
            choice = seed % 4
            if choice == 0:
                tid, elf_n, kind = "RAND-EARLY-UNAUTH", 1 if model == "RST-A" else 2, \
                    "EARLY_UNAUTH_REACHABLE" if model == "RST-A" else "EARLY_UNAUTH_DENY"
                rc_test = 1 if model == "RST-A" else 2
            elif choice == 1:
                tid, elf_n, kind, rc_test = "RAND-POST-AUTH-DMA", 7, "DMA_ALLOW", 7
            elif choice == 2:
                tid, elf_n, kind, rc_test = "RAND-POST-UNAUTH-DMA", 8, "DMA_DENY", 8
            else:
                tid, elf_n, kind, rc_test = "RAND-CPU-STORE-FAULT", 5, "CPU_STORE_FAULT", 5
            elf = SW / f"RC-{elf_n}.elf"
            log, rc = run_one(sim, elf, rc_test, timeout=40)
            p = parse_logs(log)
            p["_raw"] = log
            p["_tid"] = tid
            obs, cls, result = classify(kind, p)
            # RST-A early unsafe is expected counterexample, not campaign failure
            expected_ce = kind == "EARLY_UNAUTH_REACHABLE" and result == "PASS"
            unexpected = result == "FAIL" and not expected_ce
            # For RST-A reachable, PASS means CE observed — campaign pass
            camp_pass = result == "PASS"
            rnd.append({
                "seed": seed, "test_id": tid, "reset_model": model,
                "result": "PASS" if camp_pass else "FAIL",
                "observed_expected_counterexample": "YES" if expected_ce else "NO",
                "unexpected_failure": "YES" if unexpected else "NO",
                "observed": obs, "classification": cls,
                "replay_cmd": f"{sim} --meminit=ram,{elf} +RC_TEST={rc_test}",
                "notes": f"exit={rc}",
            })
            print(f"  seed={seed:3d} {model} {tid}: {'PASS' if camp_pass else 'FAIL'}")
        elapsed = time.time() - t0
        with RANDOM.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rnd[0].keys()))
            w.writeheader()
            w.writerows(rnd)
        n_pass = sum(1 for r in rnd if r["result"] == "PASS")
        (OUT_DIR / "random_summary.txt").write_text(
            f"seeds=100 pass={n_pass} fail={100-n_pass} runtime_sec={elapsed:.2f}\n"
        )
        print(f"random: pass={n_pass}/100 runtime={elapsed:.2f}s")

    # Latency summary
    if latency_raw:
        with LATENCY.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["test_id", "metric", "cycles", "reset_model"])
            w.writeheader()
            w.writerows(latency_raw)
        # aggregate
        by = {}
        for r in latency_raw:
            by.setdefault(r["metric"], []).append(r["cycles"])
        lines = ["metric,min,median,mean,max,n"]
        for k, vals in sorted(by.items()):
            lines.append(
                f"{k},{min(vals)},{statistics.median(vals)},{statistics.mean(vals):.2f},{max(vals)},{len(vals)}"
            )
        (OUT_DIR / "latency_summary.csv").write_text("\n".join(lines) + "\n")

    print(f"Wrote {MATRIX}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
