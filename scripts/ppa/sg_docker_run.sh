#!/usr/bin/env bash
# Wrapper: join docker group then run ORFS (for sandboxed agent shells).
set -euo pipefail
exec sg docker -c "$*"
