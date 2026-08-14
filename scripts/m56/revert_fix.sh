#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOPMP_FIX=original "${ROOT}/scripts/m56/apply_fix.sh"
echo "Reverted to original upstream abstractor overlay"
