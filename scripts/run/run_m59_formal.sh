#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SBY="${ROOT}/tools/SymbiYosys/sbysrc/sby.py"
OUT="${ROOT}/results/formal/m59"
BUILD="${ROOT}/formal/build/m59"
SRC="${BUILD}/src"
VARIANT="${M59_VARIANT:-proper}"
MODE="${M59_MODE:-bmc}"
DEPTH="${M59_DEPTH:-64}"
JOBS="${M59_JOBS:-4}"
ENGINE="${M59_ENGINE:-smtbmc z3}"
ENV_LEVEL="${M59_ENV_LEVEL:-5}"
TAG="${M59_TAG:-}"

export PATH="${ROOT}/tools/z3/bin:${HOME}/miniconda3/bin:${PATH}"

mkdir -p "${OUT}"
chmod +x "${ROOT}/scripts/m58/prepare_formal_rtl.sh"
M58_VARIANT="${VARIANT}" "${ROOT}/scripts/m58/prepare_formal_rtl.sh" "${SRC}"

DEF="-DFORMAL -DM59_ENV_LEVEL=${ENV_LEVEL}"
[[ "${VARIANT}" == "original" ]] && DEF="${DEF} -DM57_VARIANT_ORIGINAL"

EXPECT="pass"
SKIP_OPT=""
case "${MODE}" in
  bmc)
    SKIP_OPT="skip 5"
    [[ "${VARIANT}" == "original" ]] && EXPECT="fail"
    ;;
  prove|pdr) ENGINE="${M59_ENGINE:-abc pdr}"; MODE="prove"; EXPECT="pass" ;;
  induction) ENGINE="${M59_ENGINE:-smtbmc z3}"; MODE="bmc"; EXPECT="pass" ;;
esac

NAME="m59_${VARIANT}_env${ENV_LEVEL}_${MODE}${DEPTH}"
[[ -n "${TAG}" ]] && NAME="m59_${TAG}"

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

echo "Running ${NAME} variant=${VARIANT} env=${ENV_LEVEL} mode=${MODE} depth=${DEPTH}"
START=$(date +%s)
python3 "${SBY}" -f -d "${OUT}/${NAME}" "${BUILD}/${NAME}.sby" -j "${JOBS}" || true
END=$(date +%s)
mkdir -p "${OUT}/${NAME}"
echo "$((END-START))" > "${OUT}/${NAME}/runtime_sec.txt"
echo "${ENV_LEVEL}" > "${OUT}/${NAME}/env_level.txt"

if [[ -f "${OUT}/${NAME}/engine_0/trace.vcd" ]]; then
  python3 "${ROOT}/scripts/m59/decode_formal_trace.py" \
    "${OUT}/${NAME}/engine_0/trace.vcd" \
    -o "${OUT}/${NAME}/engine_0/trace_table.csv" || true
fi
