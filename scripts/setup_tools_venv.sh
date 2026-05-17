#!/usr/bin/env bash
# Set up the .venv-tools/ Python venv with helpers the R ingest scripts shell
# out to. Currently only needed for Deflate64 zip extraction (OECD CRS bulk).
#
# Idempotent. Run once per fresh machine, or after deleting .venv-tools/.

set -euo pipefail

cd "$(dirname "$0")/.."

VENV=".venv-tools"

if [[ ! -d "$VENV" ]]; then
  echo "[tools] creating venv at $VENV"
  python3 -m venv "$VENV"
fi

echo "[tools] installing/upgrading zipfile-deflate64"
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet zipfile-deflate64

echo "[tools] ready: $VENV/bin/python"
