#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "${ROOT}/scripts/run/run_m55_build.sh"
"${ROOT}/results/m55/m55_sim" +M55_MODE=random +M55_RANDOM_N=500
