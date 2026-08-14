#!/usr/bin/env bash
# M7 Phase D: generate per-variant source manifests (reproducible file lists).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m7/ppa_full/source_manifests"
IBEX="${ROOT}/third_party/ibex"
mkdir -p "${OUT}"

common_m7=(
  "${ROOT}/m7/ppa/rtl/m7_ppa_mem_slave.v"
  "${ROOT}/m7/ppa/rtl/m7_ppa_top.sv"
  "${ROOT}/rtl/common/bus_pkg.vh"
  "${ROOT}/m7/rtl/m7_composed_map.vh"
  "${IBEX}/shared/rtl/bus_pkg.sv"
  "${IBEX}/shared/rtl/bus.sv"
  "${IBEX}/shared/rtl/timer.sv"
)

common_ibex=()
while IFS= read -r f; do
  common_ibex+=("$f")
done < <(find "${IBEX}/rtl" -name '*.sv' | sort)
while IFS= read -r f; do
  common_ibex+=("$f")
done < <(find "${IBEX}/vendor/lowrisc_ip/ip/prim/rtl" -name '*.sv' 2>/dev/null | sort)

write_variant() {
  local name="$1"
  shift
  local top="$1"
  shift
  {
    echo "# M7 PPA manifest ${name} top=${top}"
    echo "# ibex_commit=$(git -C "${IBEX}" rev-parse HEAD)"
    echo "# generated=$(date -Iseconds)"
    for f in "$@"; do echo "$f"; done
  } > "${OUT}/${name}.files"
}

comp=(
  "${ROOT}/m7/ppa/rtl/m7_ppa_domain_reset.v"
  "${ROOT}/m7/rtl/m7_ibex_data_adapter.sv"
  "${ROOT}/m7/rtl/m7_research_arbiter.sv"
  "${ROOT}/rtl/dma/dma_master.v"
  "${ROOT}/rtl/iopmp/iopmp.v"
  "${ROOT}/rtl/soc/security_config.v"
)

write_variant J0 "${ROOT}/m7/ppa/rtl/m7_ppa_j0_top.sv" \
  "${ROOT}/m7/ppa/rtl/m7_ppa_j0_top.sv" "${common_m7[@]}" "${common_ibex[@]}"

write_variant J1 "${ROOT}/m7/ppa/rtl/m7_ppa_j1_top.sv" \
  "${ROOT}/m7/ppa/rtl/m7_ppa_j1_top.sv" "${common_m7[@]}" "${common_ibex[@]}"

write_variant J2 "${ROOT}/m7/ppa/rtl/m7_ppa_j2_top.sv" \
  "${ROOT}/m7/ppa/rtl/m7_ppa_j2_top.sv" "${common_m7[@]}" "${comp[@]}" "${common_ibex[@]}"

write_variant J3 "${ROOT}/m7/ppa/rtl/m7_ppa_j3_top.sv" \
  "${ROOT}/m7/ppa/rtl/m7_ppa_j3_top.sv" "${common_m7[@]}" "${comp[@]}" "${common_ibex[@]} # -DRST_B"

echo "J4=NOT_APPLICABLE_TO_REALCORE_TOP" > "${OUT}/J4.files"
echo "I0/I1 see third_party/zero-day-labs-riscv-iopmp FIX-2 abstractor" >> "${OUT}/J4.files"

echo "Wrote manifests in ${OUT}"
