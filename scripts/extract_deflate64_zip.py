#!/usr/bin/env python3
"""Extract a Deflate64 (ZIP method 9) zip file.

Python's stdlib `zipfile` and R's `unzip()` cannot read Deflate64 entries.
The OECD CRS bulk parquet is shipped as a Deflate64 zip. This tiny helper
uses the `zipfile-deflate64` PyPI shim to handle it.

Usage:
    python3 extract_deflate64_zip.py <zip_path> <extract_dir> [<member_name>]

If <member_name> is omitted, all entries are extracted. The script prints
each extracted path to stdout (one per line).
"""

from __future__ import annotations

import sys
from pathlib import Path

try:
    import zipfile_deflate64 as zipfile  # drop-in replacement supporting method 9
except ImportError as exc:
    print(
        "ERROR: install zipfile-deflate64 via the project's tools venv:\n"
        "  python3 -m venv .venv-tools\n"
        "  .venv-tools/bin/pip install zipfile-deflate64\n",
        file=sys.stderr,
    )
    raise SystemExit(2) from exc


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 1

    zip_path = Path(argv[1])
    out_dir = Path(argv[2])
    member = argv[3] if len(argv) > 3 else None

    out_dir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(zip_path, "r") as zf:
        names = [member] if member else zf.namelist()
        for name in names:
            zf.extract(name, path=out_dir)
            print((out_dir / name).resolve())

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
