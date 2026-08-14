#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="${HOME}/miniconda3/bin:${PATH}"
"${ROOT}/scripts/run/run_security_tests.sh"
