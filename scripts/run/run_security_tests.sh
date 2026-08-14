#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="${HOME}/miniconda3/bin:${PATH}"
cd "${ROOT}/tb/cocotb"
python3 -m pytest test_soc_top.py -v
