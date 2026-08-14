#!/usr/bin/env bash
# M7 Phase E: transaction-level performance (simulation cycle counts).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m7/performance"
mkdir -p "${OUT}"

# Reuse M4 performance CSV as baseline cycle evidence where applicable
if [[ -f "${ROOT}/results/m4/performance/m4_performance_C1.csv" ]]; then
  cp "${ROOT}/results/m4/performance/m4_performance_C1.csv" "${OUT}/m4_baseline_cycles.csv"
fi

python3 "${ROOT}/scripts/analysis/aggregate_m7_performance.py"
echo "M7 performance summary at results/tables/m7_performance.csv"
