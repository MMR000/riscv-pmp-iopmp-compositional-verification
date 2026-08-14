#!/usr/bin/env bash
# M7 Phase C: multi-requester / outstanding-depth scalability (research RTL + Verilator).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m7/multimaster"
mkdir -p "${OUT}"

bash "${ROOT}/scripts/run/run_m7_multimaster_verilator.sh" 2>&1 | tee "${OUT}/run.log"
python3 "${ROOT}/scripts/analysis/aggregate_m7_multimaster.py"
echo "M7 multimaster complete."
