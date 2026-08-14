#!/usr/bin/env bash
# Yosys synthesis for M4 configuration comparison (unified m4_synth_top).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${ROOT}/rtl"
OUT="${ROOT}/results/m4/synthesis"
mkdir -p "${OUT}"

YOSYS="${YOSYS:-yosys}"
TOOL_VER="$(${YOSYS} -V 2>/dev/null | head -1 || echo unknown)"
echo "yosys_version=${TOOL_VER}" > "${OUT}/tool_info.txt"

declare -A DEFS=(
  [C0]=""
  [C1]="-D RST_B"
  [C2]="-D RSDG_ADMIT_GATE"
  [C3]="-D RSDG_ADMIT_GATE -D RSDG_COMMIT_EPOCH"
  [C4]="-D RST_B -D RSDG_ADMIT_GATE"
)

for cfg in C0 C1 C2 C3 C4; do
  echo "=== Synthesis m4_synth_top ${cfg} ==="
  RSDG=""
  if [[ "${cfg}" == C2 || "${cfg}" == C3 || "${cfg}" == C4 ]]; then
    RSDG="read_verilog -I${RTL}/common ${DEFS[$cfg]} ${RTL}/soc/rsdg.v;"
  fi
  ${YOSYS} -p "
    read_verilog -I${RTL}/common ${DEFS[$cfg]} ${RTL}/soc/security_config.v;
    read_verilog -I${RTL}/common ${DEFS[$cfg]} ${RTL}/iopmp/iopmp.v;
    ${RSDG}
    read_verilog -I${RTL}/common ${DEFS[$cfg]} ${RTL}/soc/m4_synth_top.v;
    hierarchy -top m4_synth_top;
    proc; flatten; opt; stat -top m4_synth_top
  " > "${OUT}/yosys_stat_${cfg}.txt" 2>&1 || true
done

python3 "${ROOT}/scripts/analysis/aggregate_m4.py" --synth-only
echo "M4 synthesis complete."
