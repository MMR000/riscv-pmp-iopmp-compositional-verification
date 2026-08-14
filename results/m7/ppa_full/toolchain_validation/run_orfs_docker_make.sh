#!/usr/bin/env bash
# Host-side ORFS docker_shell wrapper (needs docker group via sg docker).
set -euo pipefail
FLOW="${FLOW:-/home/mmr/ricv_paper/third_party/OpenROAD-flow-scripts/flow}"
DESIGN_CONFIG="${1:?DESIGN_CONFIG required, e.g. ./designs/nangate45/gcd/config.mk}"
LOG="${2:?log path required}"
# LEC_CHECK=0: kepler-formal in openroad/orfs:latest contains AVX-512 (zmm);
# Intel i9-14900KF has AVX-512 fused off. Official ORFS workaround; does not
# modify design RTL/config. Physical flow still runs synth→finish.
LEC_CHECK="${LEC_CHECK:-0}"
mkdir -p "$(dirname "$LOG")"
cd "$FLOW"
echo "START_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee "$LOG"
echo "DESIGN_CONFIG=$DESIGN_CONFIG" | tee -a "$LOG"
echo "LEC_CHECK=$LEC_CHECK" | tee -a "$LOG"
echo "FLOW=$FLOW" | tee -a "$LOG"
START_S=$(date +%s)
set +e
sg docker -c "bash -lc './util/docker_shell make LEC_CHECK=${LEC_CHECK} DESIGN_CONFIG=${DESIGN_CONFIG}'" >>"$LOG" 2>&1
EC=$?
set -e
END_S=$(date +%s)
echo "END_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$LOG"
echo "ELAPSED_SEC=$((END_S-START_S))" | tee -a "$LOG"
echo "EXIT_CODE=$EC" | tee -a "$LOG"
exit "$EC"
