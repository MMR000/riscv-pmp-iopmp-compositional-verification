#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REF="${ROOT}/third_party/riscv-iopmp-official/iopmp_ref_model"
OUT="${ROOT}/results/m5/reference_model"
mkdir -p "${OUT}"
cd "${REF}"
make build model=full_model 2>&1 | tee "${OUT}/build.log"
"${REF}/bin/full_model" 2>&1 | tee "${OUT}/upstream_tests.txt"
echo "REF-IOPMP full_model: $(grep -c PASS "${OUT}/upstream_tests.txt" || true) tests logged"
