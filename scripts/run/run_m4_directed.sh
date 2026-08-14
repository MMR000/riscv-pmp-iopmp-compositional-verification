#!/usr/bin/env bash
# M4B full directed reset matrix: 16 experiments × 5 configurations.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TB="${ROOT}/tb/cocotb"
MATRIX="${ROOT}/results/tables/m4_directed_reset_matrix.csv"
mkdir -p "${ROOT}/results/tables" "${ROOT}/results/m4/waveforms"

: > "${MATRIX}.partial"
for cfg in C0 C1 C2 C3 C4; do
  echo "=== M4 directed matrix ${cfg} ==="
  (cd "${TB}" && M4_CONFIG="${cfg}" python3 -m pytest test_m4_directed_runner.py -q)
done

python3 "${ROOT}/scripts/analysis/merge_m4_directed.py"
echo "Directed matrix complete: ${MATRIX}"
