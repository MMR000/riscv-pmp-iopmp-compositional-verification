#!/usr/bin/env bash
# Generate inspectable M4 waveform FST files (one scenario per simulation).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TB="${ROOT}/tb/cocotb"
WAVE="${ROOT}/results/m4/waveforms"
FORMAL_CE="${ROOT}/results/formal/sp08_reset/engine_0/trace.vcd"
mkdir -p "${WAVE}"

run_wave() {
  local cfg="$1" scenario="$2"
  echo "=== Waveform ${cfg} ${scenario} ==="
  (cd "${TB}" && M4_CONFIG="${cfg}" M4_WAVE_SCENARIO="${scenario}" \
    python3 -m pytest test_m4_waveform_runner.py -q)
}

# Required directed scenarios
run_wave C0 R01
run_wave C0 R07
run_wave C1 R01
run_wave C0 R03
run_wave C1 R03
run_wave C2 R03
run_wave C1 R09
run_wave C1 R11
run_wave C0 R16
run_wave C1 R16
run_wave C3 R16

# Formal SP-08 RST-A counterexample trace
if [[ -f "${FORMAL_CE}" ]]; then
  cp -f "${FORMAL_CE}" "${WAVE}/m4_sp08_rst_a_counterexample.vcd"
fi

python3 - <<'PY'
from pathlib import Path
wave = Path("results/m4/waveforms")
bad = []
for p in wave.glob("*"):
    if p.stat().st_size < 1024:
        bad.append(f"{p.name} ({p.stat().st_size} bytes)")
if bad:
    raise SystemExit("Undersized waveform files:\n  " + "\n  ".join(bad))
print(f"Waveform check PASS: {len(list(wave.glob('*')))} files, all nontrivial")
PY

echo "M4 waveforms complete: ${WAVE}"
