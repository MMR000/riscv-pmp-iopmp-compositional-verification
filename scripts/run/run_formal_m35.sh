#!/usr/bin/env bash
# M3.5 formal suite: BMC depths + prove attempts + RST-B.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SBY="${ROOT}/tools/SymbiYosys/sbysrc/sby.py"
FORMAL="${ROOT}/formal/sby"
OUT="${ROOT}/results/formal"
JOBS="${1:-4}"

export PATH="${ROOT}/tools/z3/bin:${HOME}/miniconda3/bin:${PATH}"

mkdir -p "${OUT}" "${OUT}/counterexamples"

run_bmc() {
    local task="$1"
    local depth="$2"
    local name
    name="$(basename "${task}" .sby)"
    local dest="${OUT}/${name}_d${depth}"
    echo "=== BMC ${name} depth=${depth} ==="
    (cd "${FORMAL}" && python3 "${SBY}" -f -d "${dest}" "${name}.sby" --depth "${depth}" -j "${JOBS}") || true
    echo "${name},bmc,${depth},$(grep -m1 'DONE' "${dest}/logfile.txt" 2>/dev/null || echo UNKNOWN)" >> "${OUT}/m35_bmc_depth.log"
}

run_task() {
    local task="$1"
    local name
    name="$(basename "${task}" .sby)"
    echo "=== Formal task: ${name} ==="
    (cd "${FORMAL}" && python3 "${SBY}" -f -d "${OUT}/${name}" "${name}.sby" -j "${JOBS}") || true
}

# BMC depth sweep (selected properties)
for d in 8 16 32 64; do
    run_bmc sp02_pmp_unit.sby "${d}"
    run_bmc sp04_iopmp_unit.sby "${d}"
done

# Standard tasks
TASKS=(
    sp02_pmp_unit.sby
    sp04_iopmp_unit.sby
    sp10_integration.sby
    sp08_reset.sby
    sp08_reset_rstb.sby
    spb01_model_b.sby
    m3_cover.sby
    sp02_pmp_prove.sby
    sp04_iopmp_prove.sby
)

for t in "${TASKS[@]}"; do
    run_task "${FORMAL}/${t}"
done

# Preserve RST-A counterexample (do not overwrite SP-08 archive)
if [[ -f "${OUT}/sp08_reset/engine_0/trace.vcd" ]]; then
    mkdir -p "${OUT}/counterexamples/SP-08"
    cp -f "${OUT}/sp08_reset/engine_0/trace.vcd" "${OUT}/counterexamples/SP-08/trace.vcd"
fi

python3 "${ROOT}/scripts/analysis/aggregate_m35.py"
echo "M3.5 formal complete. See ${OUT}/m35_summary.md"
