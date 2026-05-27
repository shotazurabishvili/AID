# OSF deposit manifest — Measuring Aid for Learning

**Prepared:** 2026-05-25 ( preflight).
**Status:** Deposited at OSF (DOI <https://doi.org/10.17605/OSF.IO/JRBT8>);
`[AUTHOR: OSF DOI]` placeholders swapped into the manuscript and submission
package on 2026-05-26. Workflow steps below retained for reference.

This manifest lists what to upload to OSF, what to register, and what to keep
deposit-side vs. repository-side. Designed so that an external reader can
reproduce every reported result from the deposited artifacts alone.

## What to upload

### Core deposited artifacts (required for reproducibility claim)

| Path in repo | OSF folder | Notes |
|---|---|---|
| `R/**` | `code/` | All analysis scripts, including the three new peer-review scripts (R/80, R/81, R/82). |
| `R/lib/**` | `code/lib/` | Helper functions (iso3 normalization, IO, coverage). |
| `renv.lock` | `code/` | Lockfile pinning all package versions. |
| `data/interim/panel.parquet` | `data/` | Canonical analytical panel — 133 countries × 11 years. ~Single-MB scale. |
| `docs/decisions/0001-…0012-*.md` | `pre_analysis_plans/` | The twelve pre-analysis plans (PAP-0001 through PAP-0012) — the documents the methodology claim rests on. |
| `docs/decisions/INDEX.md` | `pre_analysis_plans/` | Plan index with PAP status. |
| `docs/the manuscript methodology section` | `documentation/` | Full methodology document supplementing manuscript §3. |
| `docs/data_dictionary.md` | `documentation/` | Variable definitions, source URLs, pinned indicator codes. |
| `output/tables/**.csv` | `outputs/tables/` | All analytical-output tables in machine-readable form. |
| `output/tables/**.md` | `outputs/tables/` | Same tables in human-readable form. |
| `output/figures/eda/**.png` | `outputs/figures/` | Rendered figures (PDFs optional). |
| `drafts/aid_without_learning.qmd` | `manuscript/` | Quarto source of the manuscript. |
| `drafts/aid_without_learning.docx` | `manuscript/` | Rendered manuscript. |
| `drafts/references.bib` | `manuscript/` | BibTeX bibliography. |
| `drafts/apa.csl` | `manuscript/` | APA 7 citation style file. |

### Documentation files to upload alongside

| Path | Purpose |
|---|---|
| `docs/osf_readme.md` | Top-level README for the OSF project (this folder's reproduction instructions, license, citation). |
| `docs/osf_deposit_manifest.md` | This file. |

### Not deposited (raw data already public via upstream portals)

The analysis uses only publicly-available administrative + harmonized-research
sources. The intermediate panel (`data/interim/panel.parquet`) is the merged
deposited artifact; the raw upstream sources are not redistributed (and would
violate the upstream redistribution terms in some cases). The data dictionary
(`docs/data_dictionary.md`) pins every variable's upstream URL + indicator
code so an independent researcher can reconstruct the panel from scratch.

Specifically NOT in the deposit:
- `data/raw/**` — raw downloads from OECD, WB, UNESCO, WGI, UCDP, AidData. Reconstruct via `R/10_ingest_*.R` scripts.
- `data/interim/*.parquet` other than the canonical `panel.parquet` — intermediate ingest artifacts. Reconstruct via the ingest scripts.
- `data/aiddata_gcdf/**`, `data/oecd_crs/**`, etc. — staging directories.

## Reproduction flow (documented in the OSF README)

After OSF download:

```bash
# 1. Restore the environment
Rscript -e 'install.packages("renv"); renv::restore()'

# 2. Reproduce the headline
Rscript R/51_model2_fe.R                 # Model 2 family + diagnostics
Rscript R/55_model2_wgi_operationalization.R  # WGI sensitivity inc. PC1 headline

# 3. Reproduce the peer-review additions
Rscript R/80_peer_review_bootstrap.R          # Wild cluster bootstrap
Rscript R/81_peer_review_placebo.R            # Falsification (future aid)
Rscript R/82_peer_review_ssa_heterogeneity.R  # SSA heterogeneity

# 4. Re-render the manuscript
quarto render drafts/aid_without_learning.qmd --to docx
```

Expected runtime: < 2 minutes per script on a contemporary laptop; bootstrap is
the slowest at ~30 seconds.

## License recommendation (author confirms)

- **Documents** (PAPs, methodology, manuscript): **CC-BY 4.0** — allows reuse
  and citation, requires attribution.
- **Code** (R scripts, helpers): **MIT** — minimal-friction reuse for replication.

Surfaced as author calls. Both are conventional choices for academic
deposits; OSF lets you pick a single project license or per-file.

## Registration

After upload + README + license selection, run **OSF registration** on the
project (osf.io → project → Registrations → New Registration → "OSF
Open-Ended Registration"). Registration is what mints the DOI and makes the
timestamp externally auditable.

The manuscript's claim that pre-analysis plans are timestamped in a public
commit history is independently strengthened by OSF registration: the OSF
timestamp is a third-party witness independent of the GitHub commit timeline.

## Author flow

1. Go to osf.io/new and create a project. Title: "Measuring Aid for Learning: deposit". Description: copy the manuscript abstract.
2. Create the four top-level folders (`code/`, `data/`, `pre_analysis_plans/`, `documentation/`, `outputs/`, `manuscript/`).
3. Upload the files in the manifest above. The web UI accepts folder drag-and-drop. Largest file is `panel.parquet` at single-MB scale; total deposit ~50 MB.
4. Upload `docs/osf_readme.md` as the project's wiki / front page.
5. Set the license (CC-BY 4.0 documents + MIT code, or one project-wide).
6. Run a registration: Registrations tab → New Registration → "OSF Open-Ended Registration".
7. Copy the DOI from the registration page (format: `10.17605/OSF.IO/XXXXX`).
8. Hand the DOI back; agent replaces the `[AUTHOR: OSF DOI]` placeholders in:
   - `drafts/aid_without_learning.qmd` (Data Availability section)
   - `SUBMISSION/cover_letter.docx`
   - `SUBMISSION/title_page.docx`
   - `SUBMISSION/declarations.docx`
9. Re-render `aid_without_learning.docx` and refresh `SUBMISSION/aid_without_learning.docx`.

## Coordination with GitHub visibility

The OSF deposit holds the snapshotted, registered version. The GitHub repo
holds the live, evolving version with its commit history. Both should be
public before submission. The DA statement cites both — OSF for the
registered snapshot + DOI, GitHub for the development history.

Flip GitHub to public *before or after* OSF deposit; order doesn't matter,
but both must be done before submission to *World Development*.
