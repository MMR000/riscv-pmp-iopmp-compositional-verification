#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${ROOT}/third_party/zero-day-labs-riscv-iopmp"
OUT="${ROOT}/results/m57"
VARIANT="${M57_VARIANT:-proper}"
BUILD="${ROOT}/formal/build/m57/vsim"

chmod +x "${ROOT}/scripts/m56/apply_fix.sh"
IOPMP_FIX="${VARIANT}" "${ROOT}/scripts/m56/apply_fix.sh"

mkdir -p "${OUT}" "${BUILD}"
WARN="-Wno-MULTITOP -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-UNSIGNED -Wno-CMPCONST -Wno-SYMRSVDWORD -Wno-LATCH -Wno-WIDTH -Wno-SELRANGE -Wno-TIMESCALEMOD -Wno-MODDUP -Wno-IMPLICITSTATIC"

INC=(
  -I"${RTL}/packages/dependencies"
  -I"${RTL}/packages/rv_iopmp"
  -I"${RTL}/vendor"
  -I"${RTL}/include"
  -I"${RTL}/rtl"
  -I"${RTL}/rtl/interfaces"
  -I"${RTL}/rtl/interfaces/axi_support"
  -I"${ROOT}/formal/harness"
)

DEF=""
[[ "${VARIANT}" == "original" ]] && DEF="-DM57_VARIANT_ORIGINAL"

mapfile -t VENDOR_SV < <(find "${RTL}/vendor" -name '*.sv' | sort)
PKG=( "${RTL}/packages/dependencies/cf_math_pkg.sv" "${RTL}/packages/dependencies/axi_pkg.sv"
      "${RTL}/packages/dependencies/lint_wrapper_pkg.sv" "${RTL}/packages/rv_iopmp/rv_iopmp_pkg.sv"
      "${RTL}/packages/rv_iopmp/rv_iopmp_reg_pkg.sv" )
RTL_SV=(
  "${RTL}/rtl/interfaces/axi_support/rv_iopmp_axi4_bc.sv"
  "${RTL}/rtl/interfaces/axi_support/rv_iopmp_data_abstractor_axi.sv"
)

cd "${BUILD}"
verilator --binary --timing -j 0 ${WARN} --assert ${DEF} \
  "${INC[@]}" \
  --top-module formal_m57_fullrtl_write_path_tb \
  -Mdir obj_dir \
  -o "${OUT}/m57_prop_sim" \
  "${PKG[@]}" "${VENDOR_SV[@]}" "${RTL_SV[@]}" \
  "${ROOT}/formal/harness/formal_m57_fullrtl_write_path_tb.sv" \
  2>&1 | tee "${OUT}/build_${VARIANT}.log"

echo "M57 property sim: ${OUT}/m57_prop_sim"
