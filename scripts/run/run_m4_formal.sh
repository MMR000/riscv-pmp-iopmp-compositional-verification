#!/usr/bin/env bash
# M4B formal evaluation: SP-08/11/13 (+ optional BMC depths).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SBY="python3 ${ROOT}/tools/SymbiYosys/sbysrc/sby.py"
FORMAL="${ROOT}/formal/sby"
OUT="${ROOT}/results/formal"
Z3="${ROOT}/tools/z3/bin"
export PATH="${Z3}:${PATH}"
mkdir -p "${OUT}"

run_task() {
  local task="$1"
  echo "=== Formal ${task} ==="
  (cd "${FORMAL}" && ${SBY} -f -d "${OUT}/${task}" "${task}.sby" -j 4) || true
}

run_task sp08_rstb_prove
run_task sp08_reset
run_task sp13_c0_bmc
run_task sp13_c1_prove
run_task sp11_rsdg_prove

python3 "${ROOT}/scripts/analysis/aggregate_m4.py" --formal-only
echo "M4 formal complete."
