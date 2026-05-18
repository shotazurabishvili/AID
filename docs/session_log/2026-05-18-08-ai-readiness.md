---
date: 2026-05-18
session: 08
phase: 1 — Data Ingestion & Audit
duration_min: ~45
---

## Goal

Ingest the **Oxford Insights Government AI Readiness Index 2025 (GARI)** — the last regular Phase-1 source. Feeds the brief's Phase-9 "Compounding AI Penalty" section (HCI × AI Readiness composite). With this in, Phase 1 is **substantively complete** (10/11 sources; AidData Core deferred per Session 06 author decision). Session 09 is the Phase-1 close-out audit + ADR-0002/0003 locks.

## What we did

- **Author decision (escalated mid-plan):** PDF-extract Oxford Insights GARI 2025 rather than substitute the IMF AI Preparedness Index (available via Data360 with clean CSV API). The brief specifies Oxford Insights; the §9 composite is built around the GARI methodology. IMF AIPI noted as possible Phase-9 sensitivity if our extraction is poor.
- **Toolchain workaround:** `pdftools` referenced in renv.lock but not installed; `libpoppler-cpp-dev` unavailable; no sudo. Extended `.venv-tools/` (Session 05 vintage) with `pdfplumber` — same architectural pattern as the Deflate64 workaround. New committed helper: `scripts/extract_pdf_table.py` (47 lines, dumps every page's tables as CSVs). Updated `scripts/setup_tools_venv.sh` to install both `zipfile-deflate64` and `pdfplumber`.
- **PDF structure probed before scripting**: 11 tables in the 8.1 MB PDF. Page 10 has a 7×3 methodology framework. **Pages 59–68 each have an 8-column country-ranking sub-table; concatenated they yield exactly 195 country rows + 1 header row** (the GARI universe). Source columns: Country, Rank, Policy Capacity, AI Infrastructure, Governance, Public Sector Adoption, Development & Diffusion, Resilience.
- **Substantive schema finding:** **No overall composite score is published in the source table.** Computed `ai_readiness_score_mean` as the equally-weighted mean of the 6 pillars; clearly labeled DERIVED in column name, catalog notes, and data dictionary. Oxford's official composite weighting may differ; ours is transparent and reproducible.
- Wrote `R/10_ingest_ai_readiness.R` (8 numbered sections; same template as `R/10_ingest_ucdp.R`). 10 columns × 195 rows × 0% missing × 0 unresolved labels — the cleanest ingest of Phase 1.
- **Phase-9 preview diagnostic** baked into the script: joined GARI with most-recent HCI per country (189 matches); `cor(ai_readiness_score_mean, hci_overall) = 0.777`. Strong positive correlation — the empirical face of the brief's compounding-penalty thesis.
- Updated documentation layer: methodology §3.12 supplementary-measures subsection (Phase-9 framing + preview correlation); data dictionary new GARI section (with explicit derived-composite caveat); obligations SHA-256 row flipped from `[ ]` to `[x]` (Phase 1 substantively complete).

## Decisions made

- **Sourced from public PDF, not registration-gated.** Despite Oxford's landing-page registration form, the PDF (`oxfordinsights.com/wp-content/uploads/2026/01/...Report_01_26.pdf`) is publicly accessible. We pin the 2026-01-29 update (8.1 MB) over the 2025-12-20 version (10.6 MB) — same edition, more recent re-cut.
- **`ai_readiness_score_mean` as DERIVED composite** (equally-weighted mean of 6 pillars). Source has no overall score; we name our composite explicitly to avoid ambiguity. Rank also retained for ordinal use.
- **PDF extraction toolchain:** `pdfplumber` via `.venv-tools/`. Pure Python, no system deps. Same pattern as the Deflate64 workaround.
- **Year stamp = 2025** for join compatibility. Cross-sectional source; the year column is an edition stamp, not a measurement year. Documented in catalog notes and data dictionary.
- **No ADR locks** — Phase-9 enters with a pre-specified construction (HCI × GARI) per the brief; no methodological choice point to adjudicate this session.

## What we tried that didn't work

*Added retrospectively (template introduced post-Session-09). High confidence — within current conversation.*

- **R-native PDF extraction blocked.** `pdftools` is referenced in `renv.lock` but not installed (`requireNamespace` returned FALSE). Attempted `renv::install("pdftools")` — failed at configure step because `libpoppler-cpp-dev` system headers aren't installed and no sudo to apt-install them. → Reused the `.venv-tools/` Python venv pattern from Session 05; added `pdfplumber` to the venv via `scripts/setup_tools_venv.sh`.
- **Considered substituting the IMF AI Preparedness Index** (available via World Bank Data360 with a clean machine-readable CSV API; verified live download with 857 rows). Different methodology than Oxford GARI; escalated via AskUserQuestion as a framing call. → Author chose Oxford PDF extraction over IMF substitution. IMF AIPI noted as possible Phase-9 sensitivity if Oxford extraction is poor.
- **First plan-mode draft assumed Oxford published an overall composite score** in the country-ranking table. Empirically false. The PDF table has 8 columns: Country, Rank, and 6 pillar scores (Policy Capacity, AI Infrastructure, Governance, Public Sector Adoption, Development & Diffusion, Resilience). No overall score is published. → Derived `ai_readiness_score_mean` as the equally-weighted mean of the 6 pillars; explicitly labeled DERIVED in column name, catalog notes, and data dictionary. Phase-9 reading must disclose this when citing.
- **Catalog rendered `version = "fetched NA"`** a third time — same root cause as Sessions 05 and 06 (cached file from probe phase). → Manual backfill via `fetched_on("ai_readiness", set = TRUE)` + re-render. Pattern is now familiar enough that a future template/helper change could address it permanently; deferred for now.

## Methodology entries written this session

- **ADRs written / updated:** — (no ADR touched this session)
- **`methodology.md` sections touched:** §3.12 — added "Supplementary measure: Oxford Insights AI Readiness (Phase 9 input)" subsection at the end. Covers source, extraction method, derived-composite caveat, and the r = 0.777 preview correlation. Header timestamp bumped to 10/11.
- **`data_dictionary.md` rows added:** new "## Oxford Insights GARI 2025" section with 10 columns + extraction-method paragraph + derived-composite caveat + Phase-9 preview footer. Pending sources trimmed to AidData Core (deferred) only.
- **`obligations.md` items checked off:** SHA-256 reproducibility row flipped from `[ ]` to `[x]` — Phase 1 substantively complete (11 sources hashed; only deferred Core remaining).
- **`lit/` notes populated:** — (Oxford Insights / GARI authors deferred to Phase 11)
- **`docs/decisions/INDEX.md` updated:** — (no status changes)
- **`CLAUDE.md` Current state updated:** yes — 10/11 sources; Phase-1 substantively closed; next action = Session 09 audit + ADR-0002/0003 locks.

## Results / findings

GARI 2025 interim parquet:

| Metric | Value |
|---|---|
| Rows | **195** (all GARI countries) |
| Columns | 10 (iso3 + year + rank + 6 pillars + derived mean) |
| Year | 2025 (edition stamp; cross-sectional) |
| Missing % | **0%** across all numeric cols |
| Unresolved labels | **0** (every country normalized via `normalize_iso3(origin="country.name")`) |
| Source PDF (sha256 e31993095b72…) | 8.1 MB, dated 2026-01-29 |
| Derived composite range | 10.28 – 87.68 |

**Phase-9 preview diagnostic** (the §9 thesis getting an empirical anchor):

| Comparison | N countries | Correlation |
|---|---|---|
| `ai_readiness_score_mean` × `hci_overall` (most-recent HCI cycle per country) | 189 | **r = 0.777** |

**Substantive implications:**
- The strong positive HCI×GARI correlation (0.777) means human capital and AI readiness are co-located: countries below the HCI median are also disproportionately below the GARI median. That's the empirical mechanism of the brief's "compounding penalty" — low-learning countries face *double exclusion* from AI-augmented labor markets. Phase 9 will partition the joint distribution (low-low / low-high / high-low / high-high quadrants) and quantify the count + population share in the low-low quadrant.
- The 6 unresolved at the join are GARI countries with no HCI observation (likely small economies or those outside HCI's measurement universe; verify in Phase 9 if relevant).
- The DERIVED composite caveat matters for Phase-9 framing: any §9 paragraph that uses `ai_readiness_score_mean` must disclose it's an equally-weighted pillar mean, not Oxford's official composite. The 6 pillars are also available individually for sensitivity.

## What's next

**Phase 1 substantively complete.** Session 09 is the close-out audit:
- Build the merged-panel coverage map (`R/40_*` family or similar)
- Run MCAR test on the merged panel
- **Lock [ADR-0002](../decisions/0002-country-universe.md)** (country universe) and **[ADR-0003](../decisions/0003-year-range.md)** (year range) — both Pending since Session 02
- Expect ADR-0003 to shift from "2000–2022 primary" to "2010–2020 primary" given Session 04's HLO sparsity finding (HCI only publishes 2010/2017/2018/2020 cycles)
- Then Phase 2 (panel construction) opens

## Open questions for the author

None.

## Files touched

- `R/10_ingest_ai_readiness.R` — new (8 numbered sections, pdfplumber-driven extraction)
- `scripts/extract_pdf_table.py` — new (Python helper for table extraction)
- `scripts/setup_tools_venv.sh` — edited (added pdfplumber)
- `data/raw/ai_readiness/gari_2025.pdf` — new (8.1 MB, gitignored, sha256 e31993095b72…)
- `data/raw/ai_readiness/tables/table_*.csv` — new (11 files, gitignored — these are intermediate extraction artifacts)
- `data/interim/ai_readiness.parquet` — new (195 × 10)
- `data/catalog.yml` — `ai_readiness` entry populated
- `data/catalog.md` — re-rendered
- `docs/methodology.md` — §3.12 supplementary-measures subsection added; timestamp bumped to 10/11
- `docs/data_dictionary.md` — new GARI section; Pending list trimmed
- `docs/obligations.md` — SHA-256 row ticked `[x]`
- `output/figures/coverage/ai_readiness.{pdf,png}` — new (single-year heatmap; visually thin by construction)
- `CLAUDE.md` — Current state block updated
- `docs/session_log/2026-05-18-08-ai-readiness.md` — this file
- `docs/session_log/CURRENT.md` — retargeted symlink
