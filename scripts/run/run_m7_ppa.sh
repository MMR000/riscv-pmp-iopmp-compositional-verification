#!/usr/bin/env bash
# M7 Phase D: common-target Yosys synthesis (synthesis-only; no OpenROAD/FPGA on this host).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/m7/ppa/raw"
mkdir -p "${OUT}"

YOSYS="${YOSYS:-yosys}"
echo "yosys=$(${YOSYS} -V 2>/dev/null | head -1)" > "${ROOT}/results/m7/ppa/toolchain.txt"
echo "openroad=NOT_INSTALLED" >> "${ROOT}/results/m7/ppa/toolchain.txt"
echo "liberty=NONE (synthesis-only cell counts)" >> "${ROOT}/results/m7/ppa/toolchain.txt"
echo "flow=synthesis-only" >> "${ROOT}/results/m7/ppa/toolchain.txt"

RTL="${ROOT}/rtl"
# J-configurations on research protection stack (Ibex not yet in synth top — documented in summary)
declare -A JDEFS=(
  [J0]=""
  [J1]=""
  [J2]=""
  [J3]="-D RST_B"
  [J4]="-D RST_B -D RSDG_ADMIT_GATE"
)

for cfg in J0 J1 J2 J3 J4; do
  defs="${JDEFS[$cfg]}"
  echo "=== ${cfg} ===" | tee "${OUT}/yosys_${cfg}.log"
  ${YOSYS} -p "
    read_verilog -I${RTL}/common ${defs} ${RTL}/soc/security_config.v;
    read_verilog -I${RTL}/common ${defs} ${RTL}/pmp/pmp.v;
    read_verilog -I${RTL}/common ${defs} ${RTL}/iopmp/iopmp.v;
    hierarchy -top pmp;
    proc; flatten; opt; stat
  " >> "${OUT}/yosys_${cfg}.log" 2>&1 || true
done

# I0/I1: zero-day-labs IOPMP abstractor (original vs FIX-2)
IOPMP="${ROOT}/third_party/zero-day-labs-riscv-iopmp"
for variant in I0 I1; do
  if [[ "${variant}" == "I1" ]]; then
    IOPMP_FIX=proper bash "${ROOT}/scripts/m56/apply_fix.sh"
  else
    IOPMP_FIX=original bash "${ROOT}/scripts/m56/apply_fix.sh"
  fi
  echo "=== ${variant} ===" | tee "${OUT}/yosys_${variant}.log"
  ${YOSYS} -p "
    read_slang ${IOPMP}/rtl/interfaces/axi_support/rv_iopmp_data_abstractor_axi.sv;
    hierarchy -top rv_iopmp_data_abstractor_axi;
    proc; flatten; opt; stat
  " >> "${OUT}/yosys_${variant}.log" 2>&1 || echo "read_slang failed for ${variant}" >> "${OUT}/yosys_${variant}.log"
done

python3 "${ROOT}/scripts/analysis/aggregate_m7_ppa.py"
echo "M7 PPA synthesis-only complete."
