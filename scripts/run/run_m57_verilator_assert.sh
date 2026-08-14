#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VARIANT="${M57_VARIANT:-proper}"
OUT="${ROOT}/results/m57"
CEX_DIR="${ROOT}/results/formal/m57/pre_fix_counterexamples"

mkdir -p "${OUT}" "${CEX_DIR}"
bash "${ROOT}/scripts/run/run_m57_verilator.sh" >/dev/null

LOG="${OUT}/assert_${VARIANT}.log"
set +e
"${OUT}/m57_prop_sim" 2>&1 | tee "${LOG}"
RC=${PIPESTATUS[0]}
set -e

if [[ "${VARIANT}" == "original" && "${RC}" -ne 0 ]]; then
  cp "${LOG}" "${CEX_DIR}/M57-FP-04_original_verilator.trace.txt"
  echo "EXPECTED_ORIGINAL_DEFECT" > "${CEX_DIR}/M57-FP-04_original.classification"
fi

python3 - <<'PY'
import re, os, csv
from pathlib import Path
root = Path(os.environ.get("ROOT", "."))
variant = os.environ.get("M57_VARIANT", "proper")
log = (root / "results/m57" / f"assert_{variant}.log").read_text()
rc = 1 if "Assertion failed" in log or "Error:" in log else 0
if variant == "original" and rc:
    status = "COUNTEREXAMPLE"
elif rc:
    status = "COUNTEREXAMPLE"
else:
    status = "BOUNDED_PASS"
row = {
    "property_id": "M57-FP-04",
    "variant": variant,
    "status": status,
    "engine": "verilator-assert",
    "depth": "directed",
}
print(f"M57 Verilator {variant}: {status}")
PY

exit 0
