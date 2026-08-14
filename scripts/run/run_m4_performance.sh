#!/usr/bin/env bash
# M4B normal-operation and recovery latency measurements.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TB="${ROOT}/tb/cocotb"
PERF="${ROOT}/results/m4/performance"
mkdir -p "${PERF}"

for cfg in C0 C1 C2 C3 C4; do
  echo "=== M4 performance ${cfg} ==="
  (cd "${TB}" && M4_CONFIG="${cfg}" python3 -m pytest test_m4_performance_runner.py -q)
done

python3 "${ROOT}/scripts/analysis/aggregate_m4.py" --performance-only
echo "M4 performance complete."
