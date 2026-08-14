#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SBY="${ROOT}/tools/SymbiYosys/sbysrc/sby.py"
OUT="${ROOT}/results/formal/m58"
BUILD="${ROOT}/formal/build/m58"
SRC="${BUILD}/src"
VARIANT="${M58_VARIANT:-proper}"
MODE="${M58_MODE:-bmc}"
DEPTH="${M58_DEPTH:-32}"
JOBS="${M58_JOBS:-4}"
ENGINE="${M58_ENGINE:-smtbmc z3}"

export PATH="${ROOT}/tools/z3/bin:${HOME}/miniconda3/bin:${PATH}"

mkdir -p "${OUT}"
chmod +x "${ROOT}/scripts/m58/prepare_formal_rtl.sh"
M58_VARIANT="${VARIANT}" "${ROOT}/scripts/m58/prepare_formal_rtl.sh" "${SRC}"

DEF="-DFORMAL"
[[ "${VARIANT}" == "original" ]] && DEF="${DEF} -DM57_VARIANT_ORIGINAL"

EXPECT="pass"
SKIP_OPT=""
case "${MODE}" in
  bmc)
    SKIP_OPT="skip 5"
    [[ "${VARIANT}" == "original" ]] && EXPECT="fail"
    ;;
  prove|pdr) ENGINE="${M58_ENGINE:-abc pdr}"; MODE="prove"; EXPECT="pass" ;;
esac

NAME="m58_${VARIANT}_${MODE}${DEPTH}"
VENDOR_LIST=$(cd "${SRC}/vendor" && ls *.sv | sed "s|^|${SRC}/vendor/|" | tr '\n' ' ')

cat > "${BUILD}/${NAME}.sby" <<EOF
[options]
mode ${MODE}
depth ${DEPTH}
expect ${EXPECT}
wait on
${SKIP_OPT}

[engines]
${ENGINE}

[script]
read_slang -I${SRC} -I${SRC}/vendor -I${SRC}/include ${DEF} ${SRC}/rv_iopmp_reg_pkg.sv ${SRC}/lint_wrapper_pkg.sv ${SRC}/rv_iopmp_pkg.sv ${VENDOR_LIST} ${SRC}/rv_iopmp_axi4_bc.sv ${SRC}/rv_iopmp_data_abstractor_axi.sv ${SRC}/formal_m57_fullrtl_write_path_tb.sv --top formal_m57_fullrtl_write_path_tb
prep -top formal_m57_fullrtl_write_path_tb
EOF

echo "Running ${NAME} variant=${VARIANT} mode=${MODE} depth=${DEPTH}"
START=$(date +%s)
python3 "${SBY}" -f -d "${OUT}/${NAME}" "${BUILD}/${NAME}.sby" -j "${JOBS}" || true
END=$(date +%s)
mkdir -p "${OUT}/${NAME}"
echo "$((END-START))" > "${OUT}/${NAME}/runtime_sec.txt"

if [[ "${VARIANT}" == "original" ]]; then
  mkdir -p "${OUT}/fix0" "${OUT}/counterexamples/M57-FP-04_FIX0"
  cp -r "${OUT}/${NAME}/"* "${OUT}/fix0/" 2>/dev/null || true
  for f in engine_0/trace.vcd engine_0/trace_tb.v logfile.txt; do
    [[ -f "${OUT}/${NAME}/${f}" ]] && cp "${OUT}/${NAME}/${f}" "${OUT}/counterexamples/M57-FP-04_FIX0/" || true
  done
fi

python3 "${ROOT}/scripts/analysis/aggregate_m58_formal.py" \
  --variant "${VARIANT}" --mode "${MODE}" --depth "${DEPTH}" --task "${NAME}" --engine "${ENGINE}" || true
