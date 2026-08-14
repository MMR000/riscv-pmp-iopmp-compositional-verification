#!/usr/bin/env bash
# Run M4 directed simulation for configurations C0-C4.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TB="${ROOT}/tb/cocotb"
mkdir -p "${ROOT}/results/simulation" "${ROOT}/results/m4"

for cfg in C0 C1 C2 C3 C4; do
  echo "=== M4 directed simulation ${cfg} ==="
  (cd "${TB}" && M4_CONFIG="${cfg}" python3 -m pytest test_m4_runner.py -q) || true
done

python3 "${ROOT}/scripts/analysis/aggregate_m4.py" --sim-only
echo "M4 simulation complete."
