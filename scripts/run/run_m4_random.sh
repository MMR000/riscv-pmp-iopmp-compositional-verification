#!/usr/bin/env bash
# M4 corrected random campaign: archive stale results, run 200×5 fresh, validate, replay failures.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TB="${ROOT}/tb/cocotb"
OUT="${ROOT}/results/simulation"
ARCH="${OUT}/archive"
mkdir -p "${ARCH}" "${OUT}"

# Archive pre-fix campaign (audit trail)
if [[ -f "${OUT}/m4_random_reset_runs.csv" ]]; then
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  cp -f "${OUT}/m4_random_reset_runs.csv" "${ARCH}/m4_random_reset_runs_pre_fix.csv"
  cp -f "${OUT}/m4_failing_seeds.csv" "${ARCH}/m4_failing_seeds_pre_fix.csv" 2>/dev/null || true
  echo "Archived pre-fix random results to ${ARCH}/"
fi

# Remove stale per-seed CSVs
rm -f "${OUT}"/m4_random_C*_seed*.csv

HEADER="campaign_id,seed,configuration,git_commit,testbench_version,iopmp_in_path,operation,address,requester_id,policy_valid,reset_sequence,secure_ready,expected,observed,property,result,classification,dma_error,mem_after"
RUNS="${OUT}/m4_random_reset_runs.csv"
FAILS="${OUT}/m4_failing_seeds.csv"
echo "${HEADER}" > "${RUNS}"
echo "seed,configuration,classification,property,notes" > "${FAILS}"

echo "=== M4 corrected random campaign (1000 runs) ==="
for cfg in C0 C1 C2 C3 C4; do
  for seed in $(seq 0 199); do
    (cd "${TB}" && M4_CONFIG="${cfg}" M4_SEED="${seed}" python3 -m pytest test_m4_random_runner.py -q)
    f="${OUT}/m4_random_${cfg}_seed$(printf '%04d' "${seed}").csv"
    if [[ ! -f "${f}" ]]; then
      echo "MISSING ${f}" >&2
      exit 1
    fi
    tail -n +2 "${f}" >> "${RUNS}"
  done
  echo "  ${cfg}: 200 seeds done"
done

python3 "${ROOT}/scripts/analysis/validate_m4_random.py"
python3 "${ROOT}/scripts/analysis/replay_m4_failures.py"
python3 "${ROOT}/scripts/analysis/aggregate_m4.py" --random-only
echo "Random campaign complete: ${RUNS}"
