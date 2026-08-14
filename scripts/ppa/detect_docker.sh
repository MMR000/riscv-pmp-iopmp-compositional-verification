#!/usr/bin/env bash
# Detect docker invocation for Phase D ORFS flows.
set -euo pipefail
if [[ -n "${DOCKER_CMD:-}" ]]; then
  echo "$DOCKER_CMD"
  exit 0
fi
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "docker"
  exit 0
fi
if command -v docker >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
  echo "sudo docker"
  exit 0
fi
echo "NONE"
exit 1
