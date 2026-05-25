#!/usr/bin/env python3
"""Extract all tables from a PDF into per-table CSV files.

Used by R/10_ingest_ai_readiness.R for the Oxford Insights GARI
2025 report. The PDF ships only as a registration-gated PDF without a CSV
export; pdfplumber's heuristic table extraction handles the country-ranking
table well enough for the ingest.

Usage:
    python3 extract_pdf_table.py <pdf_path> <output_dir>

Outputs:
    <output_dir>/table_<page>_<idx>.csv  — one file per detected table

Stdout:
    Summary lines: "page=P idx=I rows=R cols=C -> table_P_I.csv"
    Final line:   "extracted N tables"
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

try:
    import pdfplumber
except ImportError as exc:
    print(
        "ERROR: install pdfplumber via the project's tools venv:\n"
        "  bash scripts/setup_tools_venv.sh\n",
        file=sys.stderr,
    )
    raise SystemExit(2) from exc


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 1

    pdf_path = Path(argv[1])
    out_dir = Path(argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    n_extracted = 0
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages, start=1):
            try:
                tables = page.extract_tables()
            except Exception as exc:
                print(f"page={page_num} error={exc!s}", file=sys.stderr)
                continue
            for idx, table in enumerate(tables):
                if not table:
                    continue
                rows = len(table)
                cols = max((len(r) for r in table), default=0)
                out_path = out_dir / f"table_{page_num:03d}_{idx:02d}.csv"
                with out_path.open("w", newline="", encoding="utf-8") as f:
                    writer = csv.writer(f)
                    for row in table:
                        writer.writerow([c if c is not None else "" for c in row])
                print(f"page={page_num} idx={idx} rows={rows} cols={cols} -> {out_path.name}")
                n_extracted += 1

    print(f"extracted {n_extracted} tables")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
