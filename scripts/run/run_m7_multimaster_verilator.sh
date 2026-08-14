#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PYTHONPATH="${ROOT}/tb/cocotb:${PYTHONPATH:-}"
export M7_MM_OUT="${ROOT}/results/m7/multimaster"
mkdir -p "${M7_MM_OUT}"
cd "${ROOT}/tb/cocotb"
python3 -m pytest test_m7_multimaster_runner.py -q
