#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "${ROOT}/scripts/run/run_m7_realcore.sh" || true
bash "${ROOT}/scripts/run/run_m7_reset.sh"
bash "${ROOT}/scripts/run/run_m7_multimaster.sh"
bash "${ROOT}/scripts/run/run_m7_ppa.sh"
bash "${ROOT}/scripts/run/run_m7_performance.sh"
bash "${ROOT}/scripts/run/run_m7_formal.sh" || true
python3 "${ROOT}/scripts/analysis/aggregate_m7.py"
echo "M7 aggregate complete."
