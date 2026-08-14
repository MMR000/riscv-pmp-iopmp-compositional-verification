#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "${ROOT}/results/m5/reference_model" "${ROOT}/results/tables"
cd "${ROOT}/m5"
make all
M5_REF_RESULTS="${ROOT}/results/m5/reference_model/reference_results.csv" \
M5_RANGE_RESULTS="${ROOT}/results/m5/reference_model/range_results.csv" \
  ./bin/m5_ref_campaign
cp -f "${ROOT}/results/m5/reference_model/reference_results.csv" \
      "${ROOT}/results/tables/m5_reference_results.csv"
echo "M5 REF campaign complete"
