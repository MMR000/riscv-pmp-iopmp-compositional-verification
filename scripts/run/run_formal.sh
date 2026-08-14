#!/usr/bin/env bash
# Run SymbiYosys formal verification tasks for Milestone M3.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SBY="${ROOT}/tools/SymbiYosys/sbysrc/sby.py"
Z3="${ROOT}/tools/z3/bin/z3"
FORMAL="${ROOT}/formal/sby"
OUT="${ROOT}/results/formal"
JOBS="${1:-4}"
MODE="${FORMAL_MODE:-smoke}"

export PATH="${ROOT}/tools/z3/bin:${HOME}/miniconda3/bin:${PATH}"

if [[ ! -f "${SBY}" ]]; then
    echo "ERROR: SymbiYosys not found at ${SBY}" >&2
    exit 1
fi
if ! command -v yosys >/dev/null 2>&1; then
    echo "ERROR: yosys not found in PATH" >&2
    exit 1
fi
if [[ ! -x "${Z3}" ]] && ! command -v z3 >/dev/null 2>&1; then
    echo "ERROR: z3 not found" >&2
    exit 1
fi

mkdir -p "${OUT}" "${ROOT}/results/formal/counterexamples"

copy_counterexample() {
    local task="$1"
    local prop_id="$2"
    local trace="${OUT}/${task}/engine_0/trace.vcd"
    local dest="${OUT}/counterexamples/${prop_id}"
    if [[ -f "${trace}" ]]; then
        mkdir -p "${dest}"
        cp -f "${trace}" "${dest}/trace.vcd"
        [[ -f "${OUT}/${task}/logfile.txt" ]] && cp -f "${OUT}/${task}/logfile.txt" "${dest}/solver_output.txt"
        [[ -f "${FORMAL}/${task}.sby" ]] && cp -f "${FORMAL}/${task}.sby" "${dest}/configuration.sby"
        git -C "${ROOT}" rev-parse HEAD > "${dest}/commit.txt" 2>/dev/null || true
    fi
}

run_task() {
    local task="$1"
    local name
    name="$(basename "${task}" .sby)"
    echo "=== Formal task: ${name} ==="
    (cd "${FORMAL}" && python3 "${SBY}" -f -d "${OUT}/${name}" "${name}.sby" -j "${JOBS}") || true
    case "${name}" in
        spb01_model_b) copy_counterexample "${name}" "SP-B01" ;;
        sp08_reset)    copy_counterexample "${name}" "SP-08" ;;
        sp02_pmp_unit) copy_counterexample "${name}" "SP-02" ;;
        sp04_iopmp_unit) copy_counterexample "${name}" "SP-04" ;;
        sp10_integration) copy_counterexample "${name}" "SP-10" ;;
    esac
}

if [[ "${MODE}" == "smoke" ]]; then
    TASKS=(
        "${FORMAL}/sp02_pmp_unit.sby"
        "${FORMAL}/sp04_iopmp_unit.sby"
        "${FORMAL}/spb01_model_b.sby"
    )
elif [[ "${MODE}" == "full" ]]; then
    TASKS=(
        "${FORMAL}/sp02_pmp_unit.sby"
        "${FORMAL}/sp04_iopmp_unit.sby"
        "${FORMAL}/sp10_integration.sby"
        "${FORMAL}/sp08_reset.sby"
        "${FORMAL}/spb01_model_b.sby"
        "${FORMAL}/m3_cover.sby"
    )
else
    echo "Unknown FORMAL_MODE=${MODE} (use smoke or full)" >&2
    exit 1
fi

for t in "${TASKS[@]}"; do
    run_task "${t}"
done

python3 "${ROOT}/scripts/analysis/aggregate_formal.py"
echo "Formal run complete. See ${OUT}/m3_summary.md"
