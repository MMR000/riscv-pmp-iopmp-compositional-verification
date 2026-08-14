#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m55"
M55_TRACE=vcd bash "${ROOT}/scripts/run/run_m55_build.sh"
"${OUT}/m55_sim" +M55_MODE=baseline +M55_VCD
echo "M55 baseline -> ${OUT}/baseline/"
