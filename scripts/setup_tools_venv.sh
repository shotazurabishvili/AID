#!/usr/bin/env bash
# Set up the .venv-tools/ Python venv with helpers the R ingest scripts shell
# out to. Currently used for:
#   - Deflate64 zip extraction (OECD CRS bulk)
#   - PDF table extraction (Oxford Insights GARI 2025)
#
# Idempotent. Run once per fresh machine, or after deleting .venv-tools/.

set -euo pipefail

cd "$(dirname "$0")/.."

VENV=".venv-tools"

if [[ ! -d "$VENV" ]]; then
  echo "[tools] creating venv at $VENV"
  python3 -m venv "$VENV"
fi

echo "[tools] installing/upgrading pip"
"$VENV/bin/pip" install --quiet --upgrade pip

echo "[tools] installing zipfile-deflate64 + pdfplumber"
"$VENV/bin/pip" install --quiet zipfile-deflate64 pdfplumber

echo "[tools] ready: $VENV/bin/python"
