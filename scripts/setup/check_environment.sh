#!/usr/bin/env bash
# Check research environment tool availability and versions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/results/environment.txt"
M1_ONLY="${1:-}"

mkdir -p "${ROOT}/results"

check_cmd() {
    local name="$1"
    local required="$2"
    shift 2
    if command -v "$1" >/dev/null 2>&1; then
        local ver
        ver=$("$@" 2>&1 | head -1 || true)
        printf "OK   %-24s %s\n" "${name}" "${ver}"
        echo "${name}: ${ver}" >> "${OUT}.tmp"
        return 0
    else
        if [[ "${required}" == "required" ]]; then
            printf "MISS %-24s (required, not found)\n" "${name}"
        else
            printf "MISS %-24s (optional, not found)\n" "${name}"
        fi
        echo "${name}: MISSING" >> "${OUT}.tmp"
        return 1
    fi
}

missing_required=0
missing_optional=0
: > "${OUT}.tmp"

echo "=== RISC-V Compositional Isolation Research Environment ==="
echo "Root: ${ROOT}"
echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

check_cmd "git"      required git --version || missing_required=$((missing_required + 1))
check_cmd "python3"  required python3 --version || missing_required=$((missing_required + 1))
check_cmd "pytest"   required python3 -m pytest --version || missing_required=$((missing_required + 1))
check_cmd "cocotb"   required cocotb-config --version || missing_required=$((missing_required + 1))
check_cmd "iverilog" required iverilog -V || missing_required=$((missing_required + 1))
check_cmd "vvp"      required vvp -V || missing_required=$((missing_required + 1))
check_cmd "make"     required make --version || missing_required=$((missing_required + 1))

check_cmd "verilator" optional verilator --version || missing_optional=$((missing_optional + 1))
check_cmd "yosys"     optional yosys -V || missing_optional=$((missing_optional + 1))
if [[ -x "${ROOT}/tools/SymbiYosys/sbysrc/sby.py" ]]; then
    ver=$(python3 "${ROOT}/tools/SymbiYosys/sbysrc/sby.py" --version 2>&1 | head -1 || true)
    printf "OK   %-24s %s\n" "sby" "${ver}"
    echo "sby: ${ver}" >> "${OUT}.tmp"
else
    check_cmd "sby" optional sby --version || missing_optional=$((missing_optional + 1))
fi
if [[ -x "${ROOT}/tools/z3/bin/z3" ]]; then
    ver=$("${ROOT}/tools/z3/bin/z3" --version 2>&1 | head -1 || true)
    printf "OK   %-24s %s\n" "z3" "${ver}"
    echo "z3: ${ver}" >> "${OUT}.tmp"
else
    check_cmd "z3" optional z3 --version || missing_optional=$((missing_optional + 1))
fi
check_cmd "boolector" optional boolector --version || missing_optional=$((missing_optional + 1))
check_cmd "cmake"     optional cmake --version || missing_optional=$((missing_optional + 1))
check_cmd "gcc"       optional gcc --version || missing_optional=$((missing_optional + 1))
check_cmd "g++"       optional g++ --version || missing_optional=$((missing_optional + 1))
check_cmd "riscv64-gcc" optional riscv64-unknown-elf-gcc --version || missing_optional=$((missing_optional + 1))
check_cmd "riscv32-gcc" optional riscv32-unknown-elf-gcc --version || missing_optional=$((missing_optional + 1))

{
    echo "# Environment snapshot"
    echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "# Host: $(uname -a)"
    cat "${OUT}.tmp"
    echo ""
    echo "[M3 Formal Toolchain]"
    if [[ -x "${ROOT}/tools/z3/bin/z3" ]]; then
        "${ROOT}/tools/z3/bin/z3" --version 2>&1 | head -1 | sed 's/^/z3: /'
    else
        echo "z3: MISSING"
    fi
    if [[ -x "${ROOT}/tools/SymbiYosys/sbysrc/sby.py" ]]; then
        python3 "${ROOT}/tools/SymbiYosys/sbysrc/sby.py" --version 2>&1 | head -1 | sed 's/^/sby: /'
    else
        echo "sby: MISSING"
    fi
    echo "boolector: MISSING"
} > "${OUT}"
rm -f "${OUT}.tmp"

echo ""
echo "Wrote ${OUT}"
if [[ ${missing_required} -gt 0 ]]; then
    echo "ERROR: ${missing_required} required tool(s) missing for simulation."
    exit 1
fi
if [[ ${missing_optional} -gt 0 ]]; then
    echo "NOTE: ${missing_optional} optional tool(s) missing (formal/synthesis/RISC-V toolchain)."
fi
echo "Environment OK for Milestone M1 simulation."
