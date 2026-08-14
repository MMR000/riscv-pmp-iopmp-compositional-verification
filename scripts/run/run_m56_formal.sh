#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SBY="${ROOT}/tools/SymbiYosys/sbysrc/sby.py"
TASK="${ROOT}/formal/tasks/m56_write_path.sby"
OUT="${ROOT}/results/formal/m56_write_path"
Z3="${ROOT}/tools/z3/bin"

mkdir -p "${OUT}"
if [[ ! -f "${TASK}" ]]; then
  echo "NOT_RUN: ${TASK} missing" | tee "${ROOT}/results/formal/m56_summary.md"
  exit 0
fi

if [[ ! -x "${Z3}/z3" ]]; then
  echo "NOT_RUN: z3 unavailable" | tee "${ROOT}/results/formal/m56_summary.md"
  exit 0
fi

PATH="${Z3}:${PATH}" python3 "${SBY}" -d "${OUT}" -f "${TASK}" || true
python3 "${ROOT}/scripts/analysis/aggregate_m56_formal.py"
