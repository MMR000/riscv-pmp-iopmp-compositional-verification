#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${ROOT}/third_party/zero-day-labs-riscv-iopmp"
OUT="${ROOT}/results/m56"
M5A="${ROOT}/m5/adapters"
M56A="${ROOT}/m56/adapters"
FIX="${IOPMP_FIX:-proper}"

chmod +x "${ROOT}/scripts/m56/apply_fix.sh"
IOPMP_FIX="$FIX" "${ROOT}/scripts/m56/apply_fix.sh"

mkdir -p "${OUT}" "${ROOT}/m56/obj_dir"
WARN="-Wno-MULTITOP -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-UNSIGNED -Wno-CMPCONST -Wno-SYMRSVDWORD -Wno-LATCH -Wno-WIDTH -Wno-SELRANGE -Wno-TIMESCALEMOD -Wno-MODDUP -Wno-IMPLICITSTATIC"

INC=(
  -I"${RTL}/packages/dependencies"
  -I"${RTL}/packages/rv_iopmp"
  -I"${RTL}/vendor"
  -I"${RTL}/include"
  -I"${RTL}/rtl"
  -I"${RTL}/rtl/matching_logic"
  -I"${RTL}/rtl/interfaces"
  -I"${RTL}/rtl/interfaces/axi_support"
  -I"${RTL}/rtl/interfaces/regmap"
  -I"${M5A}"
  -I"${M56A}"
)

mapfile -t VENDOR_SV < <(find "${RTL}/vendor" -name '*.sv' | sort)
mapfile -t RTL_SV < <(find "${RTL}/rtl" -name '*.sv' | sort)
PKG_SV=(
  "${RTL}/packages/dependencies/cf_math_pkg.sv"
  "${RTL}/packages/dependencies/axi_pkg.sv"
  "${RTL}/packages/dependencies/lint_wrapper_pkg.sv"
  "${RTL}/packages/rv_iopmp/rv_iopmp_pkg.sv"
  "${RTL}/packages/rv_iopmp/rv_iopmp_reg_pkg.sv"
)

cd "${ROOT}/m56"
verilator --binary --timing -j 0 ${WARN} \
  "${INC[@]}" \
  --top-module m56_rtl_adapter \
  -Mdir obj_dir \
  -o "${OUT}/m56_sim" \
  "${PKG_SV[@]}" \
  "${VENDOR_SV[@]}" \
  "${RTL_SV[@]}" \
  "${M5A}/axi_simple_mem.sv" \
  "${M5A}/rtl_iopmp_dut_wrapper.sv" \
  adapters/m56_rtl_adapter.sv \
  2>&1 | tee "${OUT}/build_${FIX}.log"

echo "M56 sim (${FIX}): ${OUT}/m56_sim"
