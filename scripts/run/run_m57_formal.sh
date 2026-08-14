#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SBY="${ROOT}/tools/SymbiYosys/sbysrc/sby.py"
OUT="${ROOT}/results/formal/m57"
BUILD="${ROOT}/formal/build/m57"
DEPTH="${M57_DEPTH:-32}"
VARIANT="${M57_VARIANT:-proper}"
MODE="${M57_MODE:-bmc}"
JOBS="${M57_JOBS:-4}"

export PATH="${ROOT}/tools/z3/bin:${HOME}/miniconda3/bin:${PATH}"

mkdir -p "${OUT}" "${BUILD}"

chmod +x "${ROOT}/scripts/m57/prepare_formal_rtl.sh"
M57_VARIANT="${VARIANT}" "${ROOT}/scripts/m57/prepare_formal_rtl.sh" "${BUILD}/src"
cp "${ROOT}/formal/harness/formal_m57_fullrtl_write_path_tb.sv" "${BUILD}/src/"

TASK="${BUILD}/m57_${VARIANT}_${MODE}${DEPTH}.sby"
DEF=""
if [[ "${VARIANT}" == "original" ]]; then
  DEF="-D M57_VARIANT_ORIGINAL"
fi

ENGINE="smtbmc z3"
EXPECT="pass"
if [[ "${MODE}" == "prove" ]]; then
  ENGINE="abc pdr"
  EXPECT="pass"
fi

cat > "${TASK}" <<EOF
[options]
mode ${MODE}
depth ${DEPTH}
expect ${EXPECT}

[engines]
${ENGINE}

[script]
read -sv -I vendor -I include axi_pkg.sv
read -sv -I vendor -I include lint_wrapper_pkg.sv
read -sv -I vendor -I include rv_iopmp_pkg.sv
read -sv -I vendor -I include rv_iopmp_axi4_bc.sv
read -sv -I vendor -I include axi_err_slv.sv
read -sv -I vendor -I include axi_demux.sv
read -sv ${DEF} -I vendor -I include rv_iopmp_data_abstractor_axi.sv
read -sv -formal -I vendor -I include formal_m57_fullrtl_write_path_tb.sv
prep -top formal_m57_fullrtl_write_path_tb

[files]
formal_m57_fullrtl_write_path_tb.sv
axi_pkg.sv
lint_wrapper_pkg.sv
rv_iopmp_pkg.sv
rv_iopmp_axi4_bc.sv
axi_err_slv.sv
axi_demux.sv
rv_iopmp_data_abstractor_axi.sv
EOF

NAME="m57_${VARIANT}_${MODE}${DEPTH}"
echo "Running ${NAME} depth=${DEPTH} variant=${VARIANT} mode=${MODE}"
(cd "${BUILD}/src" && python3 "${SBY}" -f -d "${OUT}/${NAME}" "${TASK}" -j "${JOBS}") || true

python3 "${ROOT}/scripts/analysis/aggregate_m57_formal.py" --variant "${VARIANT}" --task "${NAME}" --depth "${DEPTH}" --mode "${MODE}"
