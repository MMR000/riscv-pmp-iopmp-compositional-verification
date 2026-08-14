#!/usr/bin/env bash
# Run an M7 ORFS design in the validated openroad/orfs image (digest-pinned).
# Usage: run_orfs_m7_docker.sh <variant> <log>
#   variant: J0|J1|J2|J3
set -euo pipefail
REPO="${REPO:-/home/mmr/ricv_paper}"
FLOW="${FLOW:-$REPO/third_party/OpenROAD-flow-scripts/flow}"
IMAGE="${ORFS_IMAGE:-openroad/orfs@sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277}"
VARIANT="${1:?variant J0-J3}"
LOG="${2:?log path}"
# Script cds into FLOW; keep an absolute log path for the caller.
if [[ "$LOG" != /* ]]; then
  LOG="$(pwd)/$LOG"
fi
LEC_CHECK="${LEC_CHECK:-0}"
CLOCK_PERIOD="${CLOCK_PERIOD:-10.0}"
FLOW_VARIANT="${FLOW_VARIANT:-base}"
case "$VARIANT" in
  J0|J1|J2|J3) ;;
  *) echo "variant must be J0-J3" >&2; exit 2 ;;
esac
vlower=$(echo "$VARIANT" | tr 'A-Z' 'a-z')
DESIGN_CONFIG="/repo/m7/ppa/orfs/sky130hd/m7_${vlower}/config.mk"
mkdir -p "$(dirname "$LOG")"
cd "$FLOW"
{
  echo "START_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "VARIANT=$VARIANT"
  echo "DESIGN_CONFIG=$DESIGN_CONFIG"
  echo "LEC_CHECK=$LEC_CHECK"
  echo "CLOCK_PERIOD=$CLOCK_PERIOD"
  echo "FLOW_VARIANT=$FLOW_VARIANT"
  echo "ORFS_IMAGE=$IMAGE"
  echo "FLOW=$FLOW"
} | tee "$LOG"
START_S=$(date +%s)
set +e
DOCKER_BIN=docker
if ! docker info >/dev/null 2>&1; then
  # Session often lacks docker group; sg elevates without sudo.
  DOCKER_BIN="sg docker -c docker"
fi
# Prefer direct docker when available; otherwise invoke via sg.
if docker info >/dev/null 2>&1; then
  docker run --rm -i \
    -u "$(id -u):$(id -g)" \
    -e LIBGL_ALWAYS_SOFTWARE=1 \
    -e FLOW_HOME=/OpenROAD-flow-scripts/flow/ \
    -e WORK_HOME=/work \
    -e YOSYS_EXE=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys \
    -e OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad \
    -e KLAYOUT_CMD=/usr/bin/klayout \
    -v "${FLOW}:/work:Z" \
    -v "${REPO}:/repo:Z" \
    --network host \
    "${IMAGE}" \
    bash -c "set -e; mkdir -p /tmp/xdg-run; cd /OpenROAD-flow-scripts/flow; if [ -f ../env.sh ]; then . ../env.sh; fi; make LEC_CHECK=${LEC_CHECK} CLOCK_PERIOD=${CLOCK_PERIOD} ABC_CLOCK_PERIOD_IN_PS=${CLOCK_PERIOD} FLOW_VARIANT=${FLOW_VARIANT} DESIGN_CONFIG=${DESIGN_CONFIG}" >>"$LOG" 2>&1
  EC=$?
else
  sg docker -c "docker run --rm -i \
    -u $(id -u):$(id -g) \
    -e LIBGL_ALWAYS_SOFTWARE=1 \
    -e FLOW_HOME=/OpenROAD-flow-scripts/flow/ \
    -e WORK_HOME=/work \
    -e YOSYS_EXE=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys \
    -e OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad \
    -e KLAYOUT_CMD=/usr/bin/klayout \
    -v ${FLOW}:/work:Z \
    -v ${REPO}:/repo:Z \
    --network host \
    ${IMAGE} \
    bash -c 'set -e; mkdir -p /tmp/xdg-run; cd /OpenROAD-flow-scripts/flow; if [ -f ../env.sh ]; then . ../env.sh; fi; make LEC_CHECK=${LEC_CHECK} CLOCK_PERIOD=${CLOCK_PERIOD} ABC_CLOCK_PERIOD_IN_PS=${CLOCK_PERIOD} FLOW_VARIANT=${FLOW_VARIANT} DESIGN_CONFIG=${DESIGN_CONFIG}'" >>"$LOG" 2>&1
  EC=$?
fi
set -e
END_S=$(date +%s)
{
  echo "END_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "ELAPSED_SEC=$((END_S-START_S))"
  echo "EXIT_CODE=$EC"
} | tee -a "$LOG"
exit "$EC"
