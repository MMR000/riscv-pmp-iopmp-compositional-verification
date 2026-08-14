#!/usr/bin/env bash
# Stage full RTL + vendor closure for M5.8 read_slang formal.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VARIANT="${M58_VARIANT:-proper}"
DEST="${1:-${ROOT}/formal/build/m58/src}"
RTL="${ROOT}/third_party/zero-day-labs-riscv-iopmp"

mkdir -p "${DEST}/vendor" "${DEST}/include/common_cells" "${DEST}/include/axi"
cp -r "${RTL}/include/common_cells/"* "${DEST}/include/common_cells/" 2>/dev/null || true
cp -r "${RTL}/include/axi/"* "${DEST}/include/axi/" 2>/dev/null || true

case "${VARIANT}" in
  original|fix0|FIX-0) ABSTRACTOR="${ROOT}/m56/rtl/original/rv_iopmp_data_abstractor_axi.sv" ;;
  proper|fix2|FIX-2)   ABSTRACTOR="${ROOT}/m56/rtl/proper/rv_iopmp_data_abstractor_axi.sv" ;;
  *) echo "Unknown M58_VARIANT=${VARIANT}" >&2; exit 1 ;;
esac

cp "${RTL}/packages/dependencies/cf_math_pkg.sv" "${DEST}/"
cp "${RTL}/packages/dependencies/axi_pkg.sv" "${DEST}/"
cp "${RTL}/packages/dependencies/lint_wrapper_pkg.sv" "${DEST}/"
cp "${RTL}/packages/rv_iopmp/rv_iopmp_pkg.sv" "${DEST}/"
cp "${RTL}/packages/rv_iopmp/rv_iopmp_reg_pkg.sv" "${DEST}/"
cp "${RTL}/rtl/interfaces/axi_support/rv_iopmp_axi4_bc.sv" "${DEST}/"
cp "${ABSTRACTOR}" "${DEST}/rv_iopmp_data_abstractor_axi.sv"
find "${RTL}/vendor" -name '*.sv' -exec cp {} "${DEST}/vendor/" \;
cp "${ROOT}/formal/harness/formal_m57_fullrtl_write_path_tb.sv" "${DEST}/"
echo "${VARIANT}" > "${DEST}/.m58_variant"
echo "Prepared M58_VARIANT=${VARIANT} at ${DEST}"
