#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m5/rtl"
mkdir -p "${OUT}"
bash "${ROOT}/scripts/run/run_m5_rtl_build.sh"
"${OUT}/rtl_iopmp_sim" +M5_RTL_RANDOM=500 +M5_RTL_RANDOM_OUT="${OUT}/rtl_random_results.csv" 2>&1 | tee "${OUT}/random.log"
echo "M5 RTL random campaign complete"
