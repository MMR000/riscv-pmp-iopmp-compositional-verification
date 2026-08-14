#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m7/reset"
mkdir -p "${OUT}"
export PYTHONPATH="${ROOT}/tb/cocotb:${PYTHONPATH:-}"
export M7_RESET_OUT="${OUT}"
export M7_RANDOM_SEEDS="${M7_RANDOM_SEEDS:-32}"

for cfg in C0 C1; do
  echo "=== M7 reset config ${cfg} ===" | tee -a "${OUT}/run.log"
  export M7_RESET_CONFIG="${cfg}"
  cd "${ROOT}/tb/cocotb"
  python3 -m pytest test_m7_reset_runner.py -q 2>&1 | tee -a "${OUT}/run.log"
done

python3 "${ROOT}/scripts/analysis/aggregate_m7_reset.py"
