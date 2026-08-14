#!/usr/bin/env bash
# M7 Phase C: build RST-A (sim) and RST-B (sim_rstb) + run matrix.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IBEX="${ROOT}/third_party/ibex"
OUT="${ROOT}/results/m7/realcore_reset"
LOGS="${OUT}/logs"
mkdir -p "${LOGS}" "${OUT}/tests" "${ROOT}/results/tables"

TOOL_BIN="${ROOT}/third_party/toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin"
export PATH="${TOOL_BIN}:${PATH}"
export CPATH="${CPATH:-}:/home/mmr/miniconda3/include"
export CPLUS_INCLUDE_PATH="${CPLUS_INCLUDE_PATH:-}:/home/mmr/miniconda3/include"
export LIBRARY_PATH="${LIBRARY_PATH:-}:/home/mmr/miniconda3/lib:/usr/lib/x86_64-linux-gnu"

ARCH=rv32imc_zicsr
FUSESOC_COMMON="--PMPEnable=1 --PMPNumRegions=8 --PMPGranularity=0 --RV32M=ibex_pkg::RV32MFast"

echo "=== Build software ===" | tee "${LOGS}/sw_build.log"
make -C "${ROOT}/m7/sw/ibex_reset" all ARCH="${ARCH}" 2>&1 | tee -a "${LOGS}/sw_build.log"

build_one() {
  local name="$1"
  local target="$2"
  echo "=== FuseSoC build ${name} target=${target} ===" | tee -a "${LOGS}/build_${name}.log"
  rm -rf "${IBEX}/build/local_m7_m7_ibex_reset_composed_0"
  cd "${IBEX}"
  # shellcheck disable=SC2086
  fusesoc --cores-root="${ROOT}" --cores-root=. run --target="${target}" --setup --build \
    local:m7:m7_ibex_reset_composed ${FUSESOC_COMMON} \
    2>&1 | tee -a "${LOGS}/build_${name}.log"
  local simdir
  simdir="$(find "${IBEX}/build/local_m7_m7_ibex_reset_composed_0" -type f -name 'Vm7_ibex_reset_composed_top' | head -1 | xargs dirname)"
  if [[ -z "${simdir}" || ! -x "${simdir}/Vm7_ibex_reset_composed_top" ]]; then
    echo "ERROR: simulator binary missing for ${name}" | tee -a "${LOGS}/build_${name}.log"
    find "${IBEX}/build/local_m7_m7_ibex_reset_composed_0" -maxdepth 3 -type d | head -40
    exit 1
  fi
  mkdir -p "${OUT}/${name}"
  rm -rf "${OUT}/${name}/sim-verilator"
  cp -a "${simdir}" "${OUT}/${name}/sim-verilator"
  echo "${OUT}/${name}/sim-verilator/Vm7_ibex_reset_composed_top" | tee "${OUT}/${name}/simulator_path.txt"
}

build_one rsta sim
build_one rstb sim_rstb

SIMA="${OUT}/rsta/sim-verilator/Vm7_ibex_reset_composed_top"
SIMB="${OUT}/rstb/sim-verilator/Vm7_ibex_reset_composed_top"

echo "=== Run Phase C matrix ===" | tee "${LOGS}/matrix_run.log"
python3 "${ROOT}/scripts/analysis/run_m7_realcore_reset_tests.py" \
  --sim-a "${SIMA}" --sim-b "${SIMB}" \
  2>&1 | tee -a "${LOGS}/matrix_run.log"

echo "Phase C runner complete."
