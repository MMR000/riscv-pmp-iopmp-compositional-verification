#!/usr/bin/env python3
"""M7 Phase D.2: cycle-level performance from mcycle (CPU) and event logs (DMA).

CPU metrics use Phase A Ibex PMP firmware + mcycle CSR, not the C.5 ORD harness.
DMA metrics use C.5 event landmarks. Distinct endpoints are never collapsed.
"""
from __future__ import annotations

import argparse
import csv
import random
import re
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SW_PMP = ROOT / "m7/sw/ibex_pmp"
SW_RST = ROOT / "m7/sw/ibex_reset"
OUT = ROOT / "results/m7/performance"
TABLE = ROOT / "results/tables/m7_realcore_performance.csv"
THRU = ROOT / "results/tables/m7_dma_throughput.csv"
RAW = OUT / "raw_samples.csv"
SIM_IBEX = ROOT / "third_party/ibex/build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system"
SIM_RSTB = ROOT / "results/m7/realcore_reset_c5/rstb/sim-verilator/Vm7_ibex_c5_composed_top"
SIM_COMP = ROOT / "results/m7/realcore_composed/rstb/sim-verilator/Vm7_ibex_composed_top"


def stats(vals: list[int]) -> dict:
    if not vals:
        return {"n": 0, "min": "", "median": "", "mean": "", "p95": "", "max": ""}
    s = sorted(vals)
    p95 = s[int(0.95 * (len(s) - 1))]
    return {
        "n": len(s),
        "min": min(s),
        "median": statistics.median(s),
        "mean": round(statistics.mean(s), 2),
        "p95": p95,
        "max": max(s),
    }


def run_cmd(cmd: list[str], cwd: Path, timeout: int = 60) -> str:
    proc = subprocess.run(
        ["/usr/bin/timeout", "-k", "2", str(timeout), *cmd],
        capture_output=True, text=True, cwd=str(cwd),
    )
    return proc.stdout + proc.stderr


def run_ibex(sim: Path, elf: Path) -> str:
    d = sim.parent
    logf = d / "ibex_simple_system.log"
    if logf.exists():
        logf.unlink()
    log = run_cmd([str(sim.resolve()), f"--meminit=ram,{elf.resolve()}"], d, timeout=30)
    if logf.exists():
        log += "\n--- ibex_simple_system.log ---\n" + logf.read_text()
    return log


def run_c5(sim: Path, elf: Path, plus: list[str], timeout: int = 45) -> str:
    d = sim.parent
    for n in ("m7_c5_events.log", "m7_c5_harness.log", "m7_ibex_c5_composed.log",
              "trace_core_00000000.log"):
        p = d / n
        if p.exists():
            p.unlink()
    log = run_cmd(
        [str(sim.resolve()), f"--meminit=ram,{elf.resolve()}", "+ibex_tracer_enable=0", *plus],
        d, timeout=timeout,
    )
    for n in ("m7_c5_events.log", "m7_c5_harness.log", "m7_ibex_c5_composed.log"):
        p = d / n
        if p.exists():
            log += f"\n--- {n} ---\n" + p.read_text()
    return log


def hex_field(log: str, name: str) -> int | None:
    m = re.search(rf"{name}: 0x([0-9a-fA-F]+)", log)
    return int(m.group(1), 16) if m else None


def first_evt(log: str, pat: str, after: int | None = None) -> int | None:
    for m in re.finditer(rf"CYC=(\d+) EVT={pat}", log):
        c = int(m.group(1))
        if after is None or c >= after:
            return c
    return None


def last_evt(log: str, pat: str) -> int | None:
    cyc = None
    for m in re.finditer(rf"CYC=(\d+) EVT={pat}", log):
        cyc = int(m.group(1))
    return cyc


def dma_auth_landmarks(log: str) -> dict:
    """Authorized RID=0x01 DMA: admit, first commit, last commit, first ERR=0 complete."""
    admit = last_evt(log, r"DMA_ADMITTED RID=0x01.*")
    first_commit = first_evt(
        log, r"PROT_COMMIT SRC=DMA ADDR=0x20000100 DATA=0xa11d00c5", after=admit)
    last_commit = None
    if admit is not None:
        for m in re.finditer(
            r"CYC=(\d+) EVT=PROT_COMMIT SRC=DMA ADDR=0x20000100 DATA=0xa11d00c5",
            log, flags=re.I,
        ):
            c = int(m.group(1))
            if c >= admit:
                last_commit = c
    done = first_evt(log, r"DMA_COMPLETED ERR=0", after=admit)
    return {
        "admit": admit,
        "first_commit": first_commit,
        "last_commit": last_commit,
        "complete": done,
    }


def dma_deny_landmarks(log: str) -> dict:
    deny = last_evt(log, r"DMA_DENIED RID=0x02.*")
    done = first_evt(log, r"DMA_COMPLETED ERR=1", after=deny)
    return {"deny": deny, "complete": done}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--random-n", type=int, default=500)
    ap.add_argument("--skip-random", action="store_true")
    ap.add_argument("--skip-throughput", action="store_true")
    ap.add_argument("--sim-ibex", type=Path, default=SIM_IBEX)
    ap.add_argument("--sim-c5", type=Path, default=SIM_RSTB)
    args = ap.parse_args()

    sim_ibex = args.sim_ibex
    sim_c5 = args.sim_c5 if args.sim_c5.exists() else SIM_COMP
    OUT.mkdir(parents=True, exist_ok=True)
    rows: list[dict] = []
    raw: list[dict] = []

    def add(test_id: str, metric: str, cycles, notes: str, source: str):
        ok = cycles is not None and cycles != "INCONCLUSIVE"
        rows.append({
            "test_id": test_id,
            "metric": metric,
            "cycles": cycles if ok else "INCONCLUSIVE",
            "source": source,
            "classification": "SIMULATION_EVIDENCE" if ok else "INCONCLUSIVE",
            "notes": notes,
        })

    # ----- CPU: Phase A mcycle landmarks -----
    if not sim_ibex.exists():
        print(f"ERROR: Ibex simple_system missing at {sim_ibex}")
        return 1

    cpu_map = [
        ("PERF-CPU-01", "PERF-CPU-01.elf", "mcycle_before_to_after_load",
         "M-mode authorized protected load; landmarks: csrr mcycle, lw prot_word, csrr mcycle"),
        ("PERF-CPU-02", "PERF-CPU-02.elf", "mcycle_before_to_after_store",
         "M-mode authorized protected store; landmarks: csrr mcycle, sw prot_word, csrr mcycle"),
    ]
    for tid, elfn, metric, notes in cpu_map:
        elf = SW_PMP / elfn
        if not elf.exists():
            add(tid, metric, None, f"{elfn} missing", "phase_a_mcycle")
            continue
        log = run_ibex(sim_ibex, elf)
        (OUT / f"{tid}.log").write_text(log)
        t0 = hex_field(log, "M7-CYC-REQ")
        t1 = hex_field(log, "M7-CYC-DONE")
        delta = hex_field(log, "M7-CYC-DELTA")
        if t0 is not None and t1 is not None:
            delta = t1 - t0
        add(tid, metric, delta, notes, "phase_a_mcycle")

    for tid, elfn, exp_mcause, metric, notes in [
        ("PERF-CPU-03", "PERF-CPU-03.elf", 5, "umode_attempt_to_trap",
         "U-mode denied protected load; landmarks: U-mode csrr cycle then sw g_cyc_req then lw; trap-handler csrr mcycle; expected mcause=5"),
        ("PERF-CPU-04", "PERF-CPU-04.elf", 7, "umode_attempt_to_trap",
         "U-mode denied protected store; landmarks: U-mode csrr cycle then sw g_cyc_req then sw; trap-handler csrr mcycle; expected mcause=7"),
    ]:
        elf = SW_PMP / elfn
        if not elf.exists():
            add(tid, metric, None, f"{elfn} missing", "phase_a_mcycle")
            continue
        log = run_ibex(sim_ibex, elf)
        (OUT / f"{tid}.log").write_text(log)
        mcause = hex_field(log, "MCAUSE")
        t0 = hex_field(log, "M7-CYC-REQ")
        t1 = hex_field(log, "M7-CYC-TRAP")
        ok = mcause == exp_mcause and t0 is not None and t1 is not None and t1 >= t0
        add(tid, metric, (t1 - t0) if ok else None,
            f"{notes}; mcause={mcause}", "phase_a_mcycle")

    # ----- DMA directed: C.5 event log, split endpoints -----
    if not sim_c5.exists():
        print(f"WARNING: C5 sim missing at {sim_c5}; DMA metrics skipped")
    else:
        elf = SW_RST / "RC-5.elf"
        plus_auth = ["+C5_TEST=200", "+TARGET_DELAY=0",
                     "+REL_CPU=10", "+REL_DMA=14", "+REL_IOPMP=12", "+REL_SEC=12", "+REL_IC=8"]
        log = run_c5(sim_c5, elf, plus_auth)
        (OUT / "PERF-DMA-auth.log").write_text(log)
        lm = dma_auth_landmarks(log)
        admit, fc, lc, done = lm["admit"], lm["first_commit"], lm["last_commit"], lm["complete"]
        add("PERF-DMA-01a", "admit_to_first_prot_commit",
            (fc - admit) if admit is not None and fc is not None else None,
            "authorized DMA RID=0x01 admit → first PROT_COMMIT (memory write visible)",
            "simulation_event_log")
        add("PERF-DMA-01b", "admit_to_last_prot_commit_strobe",
            (lc - admit) if admit is not None and lc is not None else None,
            "same write; last PROT_COMMIT while monitor holds mem_changed (previous directed '9')",
            "simulation_event_log")
        add("PERF-DMA-02", "admit_to_dma_completed_err0",
            (done - admit) if admit is not None and done is not None else None,
            "authorized DMA admit → first DMA_COMPLETED ERR=0 (response/completion)",
            "simulation_event_log")
        dn = dma_deny_landmarks(log)
        add("PERF-DMA-03", "deny_to_dma_completed_err1",
            (dn["complete"] - dn["deny"]) if dn["deny"] is not None and dn["complete"] is not None else None,
            "unauthorized DMA RID=0x02 deny → first DMA_COMPLETED ERR=1 (response)",
            "simulation_event_log")

        # Throughput: sequential allowed DMA, C5_TEST=900
        thru_rows = []
        if not args.skip_throughput:
            for n in (16, 64, 256):
                tmo = 30 + n // 2
                log = run_c5(sim_c5, elf, [f"+C5_TEST=900", f"+DMA_N={n}", "+TARGET_DELAY=0"],
                             timeout=tmo)
                (OUT / f"PERF-DMA-THRU-{n}.log").write_text(log)
                m = re.search(
                    r"THRU_DONE N=(\d+) FIRST_REQ=(\d+) LAST_DONE=(\d+) TOTAL=(\d+)", log)
                if not m:
                    thru_rows.append({
                        "n": n, "first_request_cycle": "N/A", "last_completion_cycle": "N/A",
                        "total_cycles": "N/A", "transfers_per_cycle": "N/A",
                        "cycles_per_transfer": "N/A", "classification": "NOT_MEASURED",
                        "notes": "THRU_DONE missing; C5 sim may predate DMA_N plusarg",
                    })
                    add(f"PERF-DMA-THRU-{n}", "cycles_per_transfer", None,
                        "sequential allowed DMA not measured (harness/log missing)",
                        "c5_test_900")
                    continue
                first_req, last_done, total = int(m.group(2)), int(m.group(3)), int(m.group(4))
                cpt = total / n
                tpc = n / total if total else 0
                thru_rows.append({
                    "n": n, "first_request_cycle": first_req, "last_completion_cycle": last_done,
                    "total_cycles": total, "transfers_per_cycle": round(tpc, 6),
                    "cycles_per_transfer": round(cpt, 4),
                    "classification": "MEASURED",
                    "notes": "single-outstanding sequential allowed DMA; includes inter-transfer harness gap",
                })
                add(f"PERF-DMA-THRU-{n}", "cycles_per_transfer_measured", round(cpt, 4),
                    f"N={n} first_req={first_req} last_done={last_done} total={total}",
                    "c5_test_900")
            THRU.parent.mkdir(parents=True, exist_ok=True)
            with THRU.open("w", newline="") as f:
                w = csv.DictWriter(f, fieldnames=list(thru_rows[0].keys()) if thru_rows else
                                   ["n", "classification", "notes"])
                w.writeheader()
                w.writerows(thru_rows)

        # 500-seed: auth completion and denied response as separate classes
        if not args.skip_random:
            rng = random.Random(0x07D000)
            auth_lats: list[int] = []
            deny_lats: list[int] = []
            for seed in range(args.random_n):
                off = 5 + (seed * 7) % 40
                plus = ["+C5_TEST=200", "+TARGET_DELAY=0",
                        "+REL_CPU=10", f"+REL_DMA={14+off}", "+REL_IOPMP=12",
                        "+REL_SEC=12", "+REL_IC=8"]
                log = run_c5(sim_c5, elf, plus, timeout=35)
                lm = dma_auth_landmarks(log)
                if lm["admit"] is not None and lm["complete"] is not None:
                    lat = lm["complete"] - lm["admit"]
                    auth_lats.append(lat)
                    raw.append({"seed": seed, "metric": "auth_dma_admit_to_complete", "cycles": lat})
                dn = dma_deny_landmarks(log)
                if dn["deny"] is not None and dn["complete"] is not None:
                    lat = dn["complete"] - dn["deny"]
                    deny_lats.append(lat)
                    raw.append({"seed": seed, "metric": "denied_dma_deny_to_complete", "cycles": lat})
                if seed % 100 == 99:
                    print(f"  random progress seed={seed} auth_n={len(auth_lats)} deny_n={len(deny_lats)}")

            for tid, metric, vals, note in [
                ("PERF-RAND-DMA-AUTH", "auth_dma_admit_to_complete", auth_lats,
                 "authorized DMA completion (admit → DMA_COMPLETED ERR=0)"),
                ("PERF-RAND-DMA-DENY", "denied_dma_deny_to_complete", deny_lats,
                 "denied DMA response (DMA_DENIED → DMA_COMPLETED ERR=1)"),
            ]:
                st = stats(vals)
                add(tid, metric, st["median"] if st["n"] else None,
                    f"{note}; n={st['n']} min={st['min']} median={st['median']} "
                    f"mean={st['mean']} p95={st['p95']} max={st['max']}",
                    str(RAW))

    rows.append({
        "test_id": "PERF-RESET-01", "metric": "secure_ready_latency",
        "cycles": "see_raw_files",
        "source": "results/tables/m7_realcore_reset_latency.csv;"
                  "results/tables/m7_realcore_release_order_latency.csv",
        "classification": "SIMULATION_EVIDENCE",
        "notes": "Phase C/C.5 raw latency preserved; not re-measured here",
    })

    TABLE.parent.mkdir(parents=True, exist_ok=True)
    with TABLE.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    with RAW.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["seed", "metric", "cycles"])
        w.writeheader()
        w.writerows(raw)

    fig = ROOT / "results/m7/ppa_full/figure_data/perf_latency_distribution.csv"
    fig.parent.mkdir(parents=True, exist_ok=True)
    with fig.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["seed", "metric", "cycles"])
        for r in raw:
            w.writerow([r["seed"], r["metric"], r["cycles"]])

    print(f"Wrote {TABLE} ({len(rows)} metrics, {len(raw)} raw samples)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
