#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CSV="${ROOT}/results/tables/m57_regression_matrix.csv"
mkdir -p "$(dirname "${CSV}")"
echo "target,result,notes" > "${CSV}"

run() {
  local t="$1"; shift
  if "$@" >/tmp/m57_reg.log 2>&1; then
    echo "${t},PASS," >> "${CSV}"
  else
    echo "${t},FAIL,see /tmp/m57_reg.log" >> "${CSV}"
  fi
}

run m55-baseline make -C "${ROOT}" m55-baseline
IOPMP_FIX=proper run m56-regression bash -c "cd '${ROOT}' && bash scripts/run/run_m56_build.sh && results/m56/m56_sim +M56_MODE=regression +M56_FIX=proper"
run m1 make -C "${ROOT}" m1
run m2 make -C "${ROOT}" m2
echo "Wrote ${CSV}"
