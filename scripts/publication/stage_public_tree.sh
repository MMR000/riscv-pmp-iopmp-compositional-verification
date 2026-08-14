#!/usr/bin/env bash
# Stage a curated public snapshot. Does not rewrite the internal Git history.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${1:-/home/mmr/ricv_paper_public}"
FILTER="${SRC}/scripts/publication/rsync_exclude.txt"

if [[ ! -f "${FILTER}" ]]; then
  echo "missing ${FILTER}" >&2
  exit 1
fi

mkdir -p "${DEST}"
rsync -a --delete \
  --exclude-from="${FILTER}" \
  "${SRC}/" "${DEST}/"

# Ensure executable bits on published scripts
chmod +x "${DEST}/scripts/setup/fetch_dependencies.sh" \
  "${DEST}/scripts/artifact/check_artifact.py" \
  "${DEST}/scripts/publication/stage_public_tree.sh" 2>/dev/null || true

echo "staged ${SRC} -> ${DEST}"
du -sh "${DEST}"
find "${DEST}" -type f -size +50M -print || true
