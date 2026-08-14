#!/usr/bin/env bash
# M5.6 campaign orchestrator
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m56"
TABLES="${ROOT}/results/tables"
GIT_COMMIT="$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
export M56_GIT_COMMIT="${GIT_COMMIT}"

mkdir -p "${OUT}/before_fix" "${OUT}/random" "${OUT}/synthesis" "${TABLES}" "${ROOT}/results/figures" "${ROOT}/results/formal"

run_sim() {
  local fix="$1"
  local mode="$2"
  shift 2
  IOPMP_FIX="${fix}" bash "${ROOT}/scripts/run/run_m56_build.sh" >/dev/null
  "${OUT}/m56_sim" +M56_MODE="${mode}" +M56_FIX="${fix}" +M56_GIT_COMMIT="${GIT_COMMIT}" "$@"
}

stage="${1:-all}"

case "${stage}" in
  build-proper)
    IOPMP_FIX=proper bash "${ROOT}/scripts/run/run_m56_build.sh"
    ;;
  before)
    run_sim original before +M56_VCD
    ;;
  regression)
    run_sim proper regression
    run_sim proper read
    ;;
  timing)
    run_sim proper timing
    ;;
  stale-route)
    run_sim proper stale-route
    ;;
  random)
    run_sim proper random +M56_RANDOM_N=500 +M56_RANDOM_SEED=56001
    ;;
  reset)
    run_sim proper reset
    ;;
  latency)
    run_sim proper latency
    for fix in original proper; do
      run_sim "${fix}" latency
    done
    ;;
  fix-compare)
    for fix in original naive proper; do
      run_sim "${fix}" fix_compare
      mv -f "${TABLES}/m56_fix_comparison.csv" "${OUT}/fix_compare_${fix}.csv"
    done
    python3 "${ROOT}/scripts/analysis/merge_m56_fix_compare.py"
    ;;
  formal)
    bash "${ROOT}/scripts/run/run_m56_formal.sh" || true
    ;;
  historical)
    bash "${ROOT}/scripts/m56/revert_fix.sh"
    make -C "${ROOT}" m1 m2 m5 || true
    make -C "${ROOT}" m55-baseline
    ;;
  aggregate)
    python3 "${ROOT}/scripts/analysis/aggregate_m56.py"
    ;;
  all)
    bash "$0" before
    bash "$0" regression
    bash "$0" timing
    bash "$0" stale-route
    bash "$0" random
    bash "$0" reset
    bash "$0" latency
    bash "$0" fix-compare
    bash "$0" formal
    bash "$0" historical
    bash "$0" aggregate
    ;;
  *)
    echo "Unknown stage: ${stage}" >&2
    exit 1
    ;;
esac

echo "M56 stage '${stage}' complete."
