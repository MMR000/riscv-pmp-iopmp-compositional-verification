#!/usr/bin/env bash
# M7 Phase F: formal closure attempts (no property redefinition).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m7/formal"
mkdir -p "${OUT}"

echo "=== SP-06/SP-09 unit (sp04_iopmp) ===" | tee "${OUT}/run.log"
cd "${ROOT}/formal/sby"
sby -f -d "${OUT}/sp06_sp09_unit" sp04_iopmp_unit.sby 2>&1 | tee -a "${OUT}/run.log" || true
sby -f -d "${OUT}/sp06_sp09_prove" sp04_iopmp_prove.sby 2>&1 | tee -a "${OUT}/run.log" || true

echo "=== M57-FP-04 M59 ENV-4 BMC ===" | tee -a "${OUT}/run.log"
M59_VARIANT=proper M59_ENV_LEVEL=4 M59_DEPTH=512 bash "${ROOT}/scripts/run/run_m59_formal.sh" 2>&1 | tee -a "${OUT}/run.log" || true

python3 "${ROOT}/scripts/analysis/aggregate_m7_formal.py"
echo "M7 formal attempts complete."
