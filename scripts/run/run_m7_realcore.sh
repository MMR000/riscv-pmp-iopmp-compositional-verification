#!/usr/bin/env bash
# M7 Phase A: Ibex real-core PMP validation via ibex_simple_system + bare-metal SW.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IBEX="${ROOT}/third_party/ibex"
OUT="${ROOT}/results/m7/ibex"
mkdir -p "${OUT}"

TOOLCHAIN_BIN=""
for d in "${ROOT}"/third_party/toolchain/xpack-riscv-none-elf-gcc-*/bin; do
  if [[ -d "$d" ]]; then TOOLCHAIN_BIN="$d"; break; fi
done
if [[ -z "${TOOLCHAIN_BIN}" ]]; then
  echo "ERROR: riscv-none-elf-gcc not found under third_party/toolchain" | tee "${OUT}/toolchain_error.txt"
  exit 2
fi
export PATH="${TOOLCHAIN_BIN}:${PATH}"
GCC="${TOOLCHAIN_BIN}/riscv-none-elf-gcc"

echo "ibex_commit=$(git -C "${IBEX}" rev-parse HEAD)" > "${OUT}/ibex_pin.txt"
echo "ibex_remote=$(git -C "${IBEX}" remote get-url origin 2>/dev/null || echo unknown)" >> "${OUT}/ibex_pin.txt"
echo "riscv_gcc=$(${GCC} --version | head -1)" >> "${OUT}/ibex_pin.txt"
echo "verilator=$(verilator --version | head -1)" >> "${OUT}/ibex_pin.txt"
echo "fusesoc=$(fusesoc --version 2>/dev/null || echo not_installed)" >> "${OUT}/ibex_pin.txt"

# M7 Ibex configuration (reproducible): 8 PMP regions, RV32IMC, no Smepmp extras
PMPEnable=1
PMPNumRegions=8
PMPGranularity=0
RV32M=ibex_pkg::RV32MFast
CONFIG_NAME="m7-pmp8"

echo "=== Building Ibex simple_system (PMPEnable=${PMPEnable}, PMPNumRegions=${PMPNumRegions}) ===" | tee "${OUT}/build.log"
cd "${IBEX}"
export VERILATOR_FLAGS="${VERILATOR_FLAGS:-} -Wno-UNOPTFLAT"
FUSESOC_OPTS="--PMPEnable=${PMPEnable} --PMPNumRegions=${PMPNumRegions} --PMPGranularity=${PMPGranularity} --RV32M=${RV32M}"
fusesoc --cores-root=. run --target=sim --setup lowrisc:ibex:ibex_simple_system ${FUSESOC_OPTS} \
  2>&1 | tee -a "${OUT}/build.log"
BUILD_DIR="${IBEX}/build/lowrisc_ibex_ibex_simple_system_0/sim-verilator"
if [[ -f "${BUILD_DIR}/config.mk" ]]; then
  sed -i 's/-Wall --unroll/-Wno-UNOPTFLAT -Wall --unroll/' "${BUILD_DIR}/config.mk" || true
fi
( cd "${BUILD_DIR}" && make -j"$(nproc 2>/dev/null || echo 2)" ) 2>&1 | tee -a "${OUT}/build.log" || true

SIM="${IBEX}/build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system"
if [[ ! -x "${SIM}" ]]; then
  echo "ERROR: Ibex simulator binary not found" | tee "${OUT}/build_error.txt"
  exit 1
fi

SW_DIR="${ROOT}/m7/sw/ibex_pmp"
RESULTS_CSV="${OUT}/ibex_pmp_results.csv"
echo "test_id,exit_code,log_file,status" > "${RESULTS_CSV}"

run_test() {
  local tid="$1"
  local elf="$2"
  local log="${OUT}/${tid}.log"
  echo "--- ${tid} ---" | tee -a "${OUT}/run.log"
  set +e
  "${SIM}" --meminit=ram,"${elf}" 2>&1 | tee "${log}"
  local ec=${PIPESTATUS[0]}
  set -e
  local status="PASS"
  if grep -q "FAIL" "${log}" 2>/dev/null; then status="FAIL"; fi
  if grep -q "PASS" "${log}" 2>/dev/null && [[ ${ec} -eq 0 ]]; then status="PASS"; fi
  echo "${tid},${ec},${log},${status}" >> "${RESULTS_CSV}"
}

make -C "${SW_DIR}" all GCC="${GCC}" OBJCOPY="${TOOLCHAIN_BIN}/riscv-none-elf-objcopy" \
  OBJDUMP="${TOOLCHAIN_BIN}/riscv-none-elf-objdump" 2>&1 | tee "${OUT}/sw_build.log"

for tid in IBEX-PMP-01 IBEX-PMP-02 IBEX-PMP-03 IBEX-PMP-04 IBEX-PMP-05 IBEX-PMP-06 IBEX-PMP-07 IBEX-PMP-08; do
  elf="${SW_DIR}/${tid}.elf"
  if [[ -f "${elf}" ]]; then
    run_test "${tid}" "${elf}"
  else
    echo "${tid},,,NOT_BUILT" >> "${RESULTS_CSV}"
  fi
done

echo "M7 real-core PMP tests complete. See ${RESULTS_CSV}"
