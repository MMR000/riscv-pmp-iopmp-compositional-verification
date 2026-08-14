#!/usr/bin/env bash
# M7 Phase A: build/run Ibex simple_system + PMP tests (no Ibex RTL changes).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IBEX="${ROOT}/third_party/ibex"
OUT="${ROOT}/results/m7/ibex"
LOGS="${OUT}/logs"
TESTS="${OUT}/tests"

mkdir -p "${LOGS}" "${TESTS}" "${ROOT}/results/tables"

TOOL_BIN="${ROOT}/third_party/toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin"
GCC="${TOOL_BIN}/riscv-none-elf-gcc"
OBJCOPY="${TOOL_BIN}/riscv-none-elf-objcopy"
OBJDUMP="${TOOL_BIN}/riscv-none-elf-objdump"
export PATH="${TOOL_BIN}:${PATH}"
export CPATH="${CPATH:-}:/home/mmr/miniconda3/include"
export CPLUS_INCLUDE_PATH="${CPLUS_INCLUDE_PATH:-}:/home/mmr/miniconda3/include"
export LIBRARY_PATH="${LIBRARY_PATH:-}:/home/mmr/miniconda3/lib:/usr/lib/x86_64-linux-gnu"

ARCH=rv32imc_zicsr
ABI=ilp32
PMPEnable=1
PMPNumRegions=8
PMPGranularity=0
RV32M=ibex_pkg::RV32MFast
FUSESOC_OPTS="--PMPEnable=${PMPEnable} --PMPNumRegions=${PMPNumRegions} --PMPGranularity=${PMPGranularity} --RV32M=${RV32M}"

echo "=== CSR smoke test ===" | tee "${LOGS}/gcc_smoke.log"
cat > "${OUT}/csr_smoke.c" <<'EOF'
int main(void) {
  unsigned long v;
  __asm__ volatile("csrr %0, mhartid" : "=r"(v));
  return (int)v;
}
EOF
"${GCC}" -march="${ARCH}" -mabi="${ABI}" -nostdlib -ffreestanding "${OUT}/csr_smoke.c" -o "${OUT}/csr_smoke.elf" 2>&1 | tee -a "${LOGS}/gcc_smoke.log"
echo "CSR smoke: OK" | tee -a "${LOGS}/gcc_smoke.log"

echo "=== Clean Ibex build dir ===" | tee "${LOGS}/simple_system_build.log"
rm -rf "${IBEX}/build/lowrisc_ibex_ibex_simple_system_0"

echo "=== FuseSoC setup+build ===" | tee -a "${LOGS}/simple_system_build.log"
cd "${IBEX}"
fusesoc --cores-root=. run --target=sim --setup --build lowrisc:ibex:ibex_simple_system ${FUSESOC_OPTS} \
  2>&1 | tee -a "${LOGS}/simple_system_build.log"

SIM="${IBEX}/build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system"
if [[ ! -x "${SIM}" ]]; then
  echo "ERROR: simulator not found" | tee "${OUT}/build_error.txt"
  exit 1
fi

{
  echo "simulator=$(realpath "${SIM}")"
  sha256sum "${SIM}"
  echo "verilator=$(verilator --version | head -1)"
  echo "fusesoc=$(fusesoc --version)"
  echo "ibex_commit=$(git -C "${IBEX}" rev-parse HEAD)"
} | tee "${OUT}/simulator_pin.txt"

echo "=== Hello test build ===" | tee "${LOGS}/hello_build.log"
make -C "${IBEX}/examples/sw/simple_system/hello_test" clean 2>/dev/null || true
# ELF only: --meminit=ram does not require srec_cat/vmem (srecord optional).
make -C "${IBEX}/examples/sw/simple_system/hello_test" CC="${GCC}" ARCH="${ARCH}" hello_test.elf \
  2>&1 | tee "${LOGS}/hello_build.log"
HELLO_ELF="${IBEX}/examples/sw/simple_system/hello_test/hello_test.elf"
if [[ ! -f "${HELLO_ELF}" ]]; then
  echo "ERROR: hello_test.elf not built" | tee "${OUT}/hello_error.txt"
  exit 1
fi
echo "=== Hello test run ===" | tee "${LOGS}/hello_run.log"
"${SIM}" --meminit=ram,"${HELLO_ELF}" 2>&1 | tee -a "${LOGS}/hello_run.log"

echo "=== PMP tests build ===" | tee "${LOGS}/pmp_build.log"
make -C "${ROOT}/m7/sw/ibex_pmp" clean
make -C "${ROOT}/m7/sw/ibex_pmp" all GCC="${GCC}" ARCH="${ARCH}" \
  2>&1 | tee "${LOGS}/pmp_build.log"

python3 "${ROOT}/scripts/analysis/run_m7_ibex_pmp_tests.py" --sim "${SIM}" --gcc "${GCC}" --arch "${ARCH}"

echo "Phase A runner complete."
