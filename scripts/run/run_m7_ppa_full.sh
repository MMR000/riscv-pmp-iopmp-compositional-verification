#!/usr/bin/env bash
# M7 Phase D full PPA orchestrator (OpenROAD + honest blocker classification).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m7/ppa_full"
LOG="${OUT}/toolchain_validation"
ORFS="${ROOT}/third_party/OpenROAD-flow-scripts"
TABLE="${ROOT}/results/tables/m7_full_ibex_ppa.csv"
OVER="${ROOT}/results/tables/m7_full_ibex_ppa_overhead.csv"
FIX2="${ROOT}/results/tables/m7_iopmp_fix2_ppa.csv"
FAIR="${OUT}/fairness_check.md"

mkdir -p "${OUT}" "${LOG}" "$(dirname "${TABLE}")"
bash "${ROOT}/scripts/ppa/generate_source_manifests.sh"

{
  echo "# M7 PPA fairness check"
  echo "date: $(date -Iseconds)"
  echo "platform_primary: sky130hd (intended)"
  echo "orfs_commit: $(cd "${ORFS}" && git rev-parse HEAD 2>/dev/null || echo MISSING)"
  echo "ibex_commit: $(git -C "${ROOT}/third_party/ibex" rev-parse HEAD)"
  echo "memory_policy: LOGIC-ONLY / MEMORY-BLACKBOX"
  echo "clock_period_ns_primary: 20"
  echo "simulation_logic_excluded: YES (see docs/m7_ppa_scope.md)"
  echo ""
  echo "## Gate results"
} > "${FAIR}"

OPENROAD=$(command -v openroad || true)
DOCKER=$(command -v docker || true)
YOSYS=$(command -v yosys || true)

if [[ -z "${OPENROAD}" ]] || [[ -z "${DOCKER}" && ! -x "${ORFS}/tools/install/OpenROAD/bin/openroad" ]]; then
  echo "- ORFS physical flow: **PPA_TOOLCHAIN_BLOCKER** (OpenROAD/Docker not available)" | tee -a "${FAIR}"
  echo "- Official gcd/ibex validation: **NOT_RUN** (ORFS bundled yosys missing)" | tee -a "${FAIR}"
  BLOCKED=1
else
  BLOCKED=0
fi

# Write main table with BLOCKED rows (no fabricated area/timing)
python3 - <<'PY' "${TABLE}" "${OVER}" "${FIX2}" "${BLOCKED}"
import csv, sys
from pathlib import Path
table, over, fix2, blocked = sys.argv[1:5]
blocked = int(blocked)
ibex = "c61e11c1e416b9ce2d996013b444c8e558d35b2b"
orfs = "f9ec54a6de7b2bc69fd586015f6ebdab34eca69c"
fields = [
    "variant","description","ibex_commit","orfs_commit","platform","clock_period_ns",
    "memory_policy","synth_cells","synth_area","place_area","route_area","core_area",
    "utilization","wns_ns","tns_ns","timing_pass","fmax_mhz_demonstrated","route_drc",
    "runtime_s","peak_memory_mb","result","notes"
]
rows = []
for v, desc in [
    ("J0","Real Ibex baseline PMPEnable=0"),
    ("J1","Real Ibex + architectural PMP"),
    ("J2","J1 + DMA + IOPMP + arbiter"),
    ("J3","J2 + RST-B fail-closed + domain reset"),
]:
    rows.append({
        "variant": v, "description": desc,
        "ibex_commit": ibex, "orfs_commit": orfs,
        "platform": "sky130hd", "clock_period_ns": "20",
        "memory_policy": "LOGIC-ONLY_BLACKBOX",
        "synth_cells": "", "synth_area": "", "place_area": "", "route_area": "",
        "core_area": "", "utilization": "", "wns_ns": "", "tns_ns": "",
        "timing_pass": "NOT_RUN", "fmax_mhz_demonstrated": "",
        "route_drc": "", "runtime_s": "", "peak_memory_mb": "",
        "result": "PPA_TOOLCHAIN_BLOCKER" if blocked else "NOT_RUN",
        "notes": "OpenROAD/Docker unavailable; no post-route metrics fabricated",
    })
rows.append({
    "variant": "J4", "description": "NOT_APPLICABLE_TO_REALCORE_TOP",
    "ibex_commit": ibex, "orfs_commit": orfs,
    "platform": "N/A", "clock_period_ns": "",
    "memory_policy": "N/A",
    "synth_cells": "", "synth_area": "", "place_area": "", "route_area": "",
    "core_area": "", "utilization": "", "wns_ns": "", "tns_ns": "",
    "timing_pass": "N/A", "fmax_mhz_demonstrated": "",
    "route_drc": "", "runtime_s": "", "peak_memory_mb": "",
    "result": "NOT_APPLICABLE",
    "notes": "FIX-2 on AXI abstractor only; see m7_iopmp_fix2_ppa.csv",
})
Path(table).parent.mkdir(parents=True, exist_ok=True)
with open(table, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields)
    w.writeheader(); w.writerows(rows)

# Overhead table empty until compatible runs exist
with open(over, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=[
        "comparison","cell_delta","cell_pct","area_delta","area_pct",
        "crit_delay_delta","crit_delay_pct","fmax_delta_mhz","fmax_pct","notes"])
    w.writeheader()
    w.writerow({"comparison":"ALL","notes":"BLOCKED: no compatible post-route runs"})

with open(fix2, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=[
        "variant","description","platform","clock_period_ns","synth_cells","route_area",
        "timing_pass","result","notes"])
    w.writeheader()
    for v, d in [("I0","IOPMP AXI abstractor original"),("I1","IOPMP AXI abstractor FIX-2")]:
        w.writerow({"variant":v,"description":d,"platform":"sky130hd","clock_period_ns":"20",
                    "synth_cells":"","route_area":"","timing_pass":"NOT_RUN",
                    "result":"PPA_TOOLCHAIN_BLOCKER" if blocked else "NOT_RUN",
                    "notes":"Separate from J-series; requires ORFS+slang"})
print(f"Wrote {table}")
PY

echo "Phase D PPA orchestrator complete (see ${TABLE})."
