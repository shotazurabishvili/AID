#!/usr/bin/env bash
# Sync selected artifacts from the WSL working tree to the Windows-side mirror,
# so the author can see current outputs from Windows (Explorer, Word, etc.) without
# crossing into WSL. One-way push: never edit files in the mirror; they will be overwritten.

set -euo pipefail

SRC="$HOME/AID"
DST="/mnt/c/Users/szura/Desktop/AID/mirror"

mkdir -p "$DST"

# Outputs (tables, figures) — committed, useful to see
rsync -a --delete "$SRC/output/tables/"  "$DST/output/tables/"
rsync -a --delete "$SRC/output/figures/" "$DST/output/figures/"

# Manuscript drafts
rsync -a --delete --exclude '.quarto' --exclude '_files' \
  "$SRC/drafts/" "$DST/drafts/"

# Current session log + plan + brief (for quick reference on Windows)
mkdir -p "$DST/docs/session_log"
rsync -a "$SRC/docs/plan.md"     "$DST/docs/plan.md"
rsync -a "$SRC/docs/brief.md"    "$DST/docs/brief.md"
rsync -a --copy-links "$SRC/docs/session_log/CURRENT.md" "$DST/docs/session_log/CURRENT.md" 2>/dev/null || true
rsync -a "$SRC/docs/session_log/" "$DST/docs/session_log/" --exclude '_template.md'

echo "Synced WSL→Windows mirror at: $DST"
