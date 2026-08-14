#!/usr/bin/env bash
# Apply IOPMP data-abstractor overlay for M5.6 builds.
# Usage: IOPMP_FIX=original|naive|proper scripts/m56/apply_fix.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${ROOT}/third_party/zero-day-labs-riscv-iopmp/rtl/interfaces/axi_support"
TARGET="${RTL}/rv_iopmp_data_abstractor_axi.sv"
STAMP="${ROOT}/third_party/zero-day-labs-riscv-iopmp/.m56_fix_mode"
FIX="${IOPMP_FIX:-proper}"

case "$FIX" in
  original)
    cp "${ROOT}/m56/rtl/original/rv_iopmp_data_abstractor_axi.sv" "$TARGET"
    ;;
  naive)
    cp "${ROOT}/m56/rtl/naive/rv_iopmp_data_abstractor_axi.sv" "$TARGET"
    ;;
  proper)
    cp "${ROOT}/m56/rtl/proper/rv_iopmp_data_abstractor_axi.sv" "$TARGET"
    ;;
  *)
    echo "Unknown IOPMP_FIX=$FIX (use original|naive|proper)" >&2
    exit 1
    ;;
esac
echo "$FIX" > "$STAMP"
echo "Applied IOPMP_FIX=$FIX to $TARGET"
