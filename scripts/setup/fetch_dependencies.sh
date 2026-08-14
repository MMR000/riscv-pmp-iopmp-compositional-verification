#!/usr/bin/env bash
# Fetch pinned third-party sources. Never updates a checkout to latest.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PINS="${ROOT}/third_party/pins"
WITH_IOPMP=0

usage() {
  cat <<'EOF'
Usage: bash scripts/setup/fetch_dependencies.sh [--with-iopmp]

Clones (if absent) and checks out exact recorded commits:
  Ibex  -> third_party/ibex
  ORFS  -> third_party/OpenROAD-flow-scripts

Optional:
  --with-iopmp  also fetch official RISC-V IOPMP and zero-day-labs RTL

Does not download PDKs, compiler binaries, or Docker images.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-iopmp) WITH_IOPMP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

read_pin() {
  tr -d '[:space:]' < "$1"
}

fetch_repo() {
  local dest="$1" url="$2" pinfile="$3" name="$4"
  local expected resolved
  expected="$(read_pin "${pinfile}")"
  mkdir -p "$(dirname "${dest}")"
  if [[ ! -d "${dest}/.git" ]]; then
    echo "clone ${name} -> ${dest}"
    git clone "${url}" "${dest}"
  fi
  git -C "${dest}" fetch --tags origin
  git -C "${dest}" checkout --detach "${expected}"
  resolved="$(git -C "${dest}" rev-parse HEAD)"
  if [[ "${resolved}" != "${expected}" ]]; then
    echo "ERROR: ${name} resolved to ${resolved}, expected ${expected}" >&2
    exit 1
  fi
  echo "OK ${name} ${resolved}"
}

echo "repository root: ${ROOT}"

fetch_repo \
  "${ROOT}/third_party/ibex" \
  "https://github.com/lowRISC/ibex.git" \
  "${PINS}/ibex.commit" \
  "Ibex"

fetch_repo \
  "${ROOT}/third_party/OpenROAD-flow-scripts" \
  "https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git" \
  "${PINS}/orfs.commit" \
  "OpenROAD-flow-scripts"

if [[ "${WITH_IOPMP}" -eq 1 ]]; then
  fetch_repo \
    "${ROOT}/third_party/zero-day-labs-riscv-iopmp" \
    "https://github.com/zero-day-labs/riscv-iopmp.git" \
    "${PINS}/zero-day-labs-riscv-iopmp.commit" \
    "zero-day-labs/riscv-iopmp"
  fetch_repo \
    "${ROOT}/third_party/riscv-iopmp-official" \
    "https://github.com/riscv-non-isa/riscv-iopmp.git" \
    "${PINS}/riscv-iopmp-official.commit" \
    "riscv-non-isa/riscv-iopmp"
fi

echo
echo "pins"
echo "  Ibex:  $(read_pin "${PINS}/ibex.commit")"
echo "  ORFS:  $(read_pin "${PINS}/orfs.commit")"
echo "  Docker:$(read_pin "${PINS}/orfs_docker.digest")"
if [[ "${WITH_IOPMP}" -eq 1 ]]; then
  echo "  ZDL:   $(read_pin "${PINS}/zero-day-labs-riscv-iopmp.commit")"
  echo "  Official IOPMP: $(read_pin "${PINS}/riscv-iopmp-official.commit")"
fi
echo
echo "Done. PDKs, xPack GCC, and Docker images are not fetched by this script."
