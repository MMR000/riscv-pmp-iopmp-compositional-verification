#!/usr/bin/env bash
# M7 Phase B: build/run composed Ibex + DMA + IOPMP system.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IBEX="${ROOT}/third_party/ibex"
OUT="${ROOT}/results/m7/ibex_composed"
LOGS="${OUT}/logs"
TESTS="${OUT}/tests"

mkdir -p "${LOGS}" "${TESTS}" "${ROOT}/results/tables"

TOOL_BIN="${ROOT}/third_party/toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin"
GCC="${TOOL_BIN}/riscv-none-elf-gcc"
export PATH="${TOOL_BIN}:${PATH}"
export CPATH="${CPATH:-}:/home/mmr/miniconda3/include"
export CPLUS_INCLUDE_PATH="${CPLUS_INCLUDE_PATH:-}:/home/mmr/miniconda3/include"
export LIBRARY_PATH="${LIBRARY_PATH:-}:/home/mmr/miniconda3/lib:/usr/lib/x86_64-linux-gnu"

ARCH=rv32imc_zicsr
FUSESOC_OPTS="--PMPEnable=1 --PMPNumRegions=8 --PMPGranularity=0 --RV32M=ibex_pkg::RV32MFast"

echo "=== Clean composed build dir ===" | tee "${LOGS}/build.log"
rm -rf "${IBEX}/build/local_m7_m7_ibex_composed_0"

echo "=== FuseSoC build m7_ibex_composed ===" | tee -a "${LOGS}/build.log"
cd "${IBEX}"
fusesoc --cores-root="${ROOT}" --cores-root=. run --target=sim --setup --build \
  local:m7:m7_ibex_composed ${FUSESOC_OPTS} \
  2>&1 | tee -a "${LOGS}/build.log"

SIM="${IBEX}/build/local_m7_m7_ibex_composed_0/sim-verilator/Vm7_ibex_composed_top"
if [[ ! -x "${SIM}" ]]; then
  echo "ERROR: composed simulator not found" | tee "${OUT}/build_error.txt"
  exit 1
fi

{
  echo "simulator=$(realpath "${SIM}")"
  sha256sum "${SIM}"
  echo "verilator=$(verilator --version | head -1)"
  echo "fusesoc=$(fusesoc --version)"
  echo "ibex_commit=$(git -C "${IBEX}" rev-parse HEAD)"
  echo "project_commit=$(git -C "${ROOT}" rev-parse HEAD)"
} | tee "${OUT}/simulator_pin.txt"

echo "=== Build composed software ===" | tee "${LOGS}/sw_build.log"
make -C "${ROOT}/m7/sw/ibex_composed" clean
make -C "${ROOT}/m7/sw/ibex_composed" all ARCH="${ARCH}" 2>&1 | tee "${LOGS}/sw_build.log"

echo "=== Run IBEX-COMP-01..08 ===" | tee "${LOGS}/composed_run.log"
python3 "${ROOT}/scripts/analysis/run_m7_ibex_composed_tests.py" --sim "${SIM}" \
  2>&1 | tee -a "${LOGS}/composed_run.log"

echo "=== Randomized scenario campaign (100 seeds) ===" | tee -a "${LOGS}/composed_run.log"
python3 "${ROOT}/scripts/analysis/run_m7_ibex_composed_random.py" --sim "${SIM}" --num-seeds 100 \
  2>&1 | tee -a "${LOGS}/composed_run.log" | tee "${LOGS}/random_campaign.log"

echo "Phase B composed runner complete."
