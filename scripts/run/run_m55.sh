#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "${ROOT}/scripts/run/run_m55_baseline.sh"
bash "${ROOT}/scripts/run/run_m55_nsaid.sh"
bash "${ROOT}/scripts/run/run_m55_permissions.sh"
bash "${ROOT}/scripts/run/run_m55_config.sh"
bash "${ROOT}/scripts/run/run_m55_random.sh"
python3 "${ROOT}/scripts/analysis/aggregate_m55.py"
echo "M55 complete. See results/m55/m55_summary.md"
