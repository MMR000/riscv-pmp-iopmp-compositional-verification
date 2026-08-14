#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m5/rtl"
mkdir -p "${OUT}"
bash "${ROOT}/scripts/run/run_m5_rtl_build.sh"
timeout 120 "${OUT}/rtl_iopmp_sim" +M5_RTL_RESULTS="${OUT}/rtl_results.csv" 2>&1 | tee "${OUT}/directed.log"
cp -f "${OUT}/rtl_results.csv" "${ROOT}/results/tables/m5_rtl_results.csv"
echo "M5 RTL directed tests complete"
