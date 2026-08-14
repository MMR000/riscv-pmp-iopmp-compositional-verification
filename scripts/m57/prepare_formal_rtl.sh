#!/usr/bin/env bash
# Stage Yosys-compatible stubs + real abstractor/demux for M5.7 formal.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VARIANT="${M57_VARIANT:-proper}"
DEST="${1:-${ROOT}/formal/build/m57/src}"
RTL="${ROOT}/third_party/zero-day-labs-riscv-iopmp"
STUB="${ROOT}/formal/m57/stubs"

mkdir -p "${DEST}/vendor/common_cells" "${DEST}/vendor/axi" "${DEST}/include/common_cells"
cp -r "${RTL}/include/common_cells/"* "${DEST}/include/common_cells/"
cp -r "${RTL}/include/common_cells/"* "${DEST}/vendor/common_cells/"

case "${VARIANT}" in
  original|fix0|FIX-0) SRC="${ROOT}/m56/rtl/original/rv_iopmp_data_abstractor_axi.sv" ;;
  proper|fix2|FIX-2)   SRC="${ROOT}/m56/rtl/proper/rv_iopmp_data_abstractor_axi.sv" ;;
  *) echo "Unknown M57_VARIANT=${VARIANT}" >&2; exit 1 ;;
esac

cp "${STUB}/axi_pkg_min.sv" "${DEST}/axi_pkg.sv"
cp "${STUB}/lint_wrapper_min.sv" "${DEST}/lint_wrapper_pkg.sv"
cp "${STUB}/rv_iopmp_pkg_min.sv" "${DEST}/rv_iopmp_pkg.sv"
cp "${RTL}/rtl/interfaces/axi_support/rv_iopmp_axi4_bc.sv" "${DEST}/"
cp "${SRC}" "${DEST}/rv_iopmp_data_abstractor_axi.sv"
cp "${RTL}/vendor/axi_demux.sv" "${DEST}/"
cp "${RTL}/vendor/axi_err_slv.sv" "${DEST}/"
cp -r "${RTL}/vendor/common_cells/"* "${DEST}/vendor/common_cells/" 2>/dev/null || true
cp -r "${RTL}/vendor/axi/"* "${DEST}/vendor/axi/" 2>/dev/null || true
echo "${VARIANT}" > "${DEST}/.m57_variant"
echo "Prepared M57_VARIANT=${VARIANT} at ${DEST}"
