---
date: 2026-05-17
session: 06
phase: 1 — Data Ingestion & Audit
duration_min: ~45
---

## Goal

Ingest **AidData GCDF v3.0** (Chinese development finance, TUFF methodology) — the headline robustness measure for the OECD-DAC-defined treatment variable. Per [ADR-0008](../decisions/0008-china-aid-inclusion.md) (Pending → Phase 5 lock), GCDF is what enables the with/without-China sensitivity check on Model 2. No ADR locks this session.

**Scope change**: AidData Core Research Release v3.1 dropped from Session 06 (author decision). Core is frozen at 2016 release with data ending 2013; the 4-year overlap with our HLO-usable 2010+ window is analytically marginal. Catalog stub stays as Pending for possible §6 historical-context use later.

## What we did

- Discovered the GCDF v3.0 bulk file: direct CloudFront download at `https://docs.aiddata.org/ad4/datasets/AidDatas_Global_Chinese_Development_Finance_Dataset_Version_3_0.zip` (~28 MB zip). Standard Deflate (no Deflate64 workaround needed). Inside: `AidDatasGlobalChineseDevelopmentFinanceDataset_v3.0.xlsx` (26 MB; sheet `GCDF_3.0` with 20,985 project rows × 126 columns) plus the field-definitions PDF, TUFF methodology PDF, and sub-national ADM CSVs.
- Verified column names by reading the xlsx directly: `Sector Name` values are UPPERCASE strings (24 sectors, "EDUCATION" is one); `Recommended For Aggregates` is the codebook-mandated row-filter; `Commitment Year` is the analytical match for OECD CRS commitment year; `Recipient ISO-3` is provided directly.
- Wrote `R/10_ingest_aiddata_gcdf.R` mirroring the OECD CRS Session-05 pattern (7 numbered sections, `[aiddata_gcdf]` log prefix, fail-graceful download with manual-fallback instruction, SHA-256 of both zip and extracted xlsx, schema introspection that fails fast if pinned columns missing).
- Applied filters: `Recommended For Aggregates == "Yes"` (avoids umbrella double-counting per AidData codebook), `Sector Name == "EDUCATION"`, `Commitment Year ∈ 1995:2024`. 20,985 → 2,662 rows post-filter → 2,654 after ISO3 normalization (8 rows on 5 regional aggregates dropped: "Africa, regional", "Asia, regional", "Oceania, regional", "Multi-Region", "America, regional").
- Computed (iso3, year) presence-of-Chinese-education-project availability. SSA-coverage contrast: **45.8% SSA vs 32.7% Rest** (gap **+13.1 pp**) — *coverage*, not *missingness* (GCDF only contains Chinese-funded projects; absence ≠ missing data).
- Headline volume: **1,131 SSA education projects across 47 of 48 SSA countries, $5.61 B constant USD 2021** — that's **60.4% of all Chinese education aid** ($9.29 B total) over the period.
- Locked the empirical hook into ADR-0008 (Data observed subsection) — threshold (≥10 SSA countries AND ≥100 projects) passes by wide margins.

## Decisions made

- **AidData Core dropped from Session 06 scope** (author decision). Latest Core release is v3.1 frozen 2016, data ends 2013. Overlap with HLO-usable 2010+ window is ~4 years — analytically marginal. The `aiddata_core` catalog stub remains as a Pending note for possible later §6 historical-context use.
- **`Recommended For Aggregates == "Yes"` filter applied at ingest** (per GCDF 3.0 codebook). Critical methodologically — without it, umbrella projects double-count their sub-component rows. Documented in script header and data dictionary.
- **Sector filter `toupper(Sector Name) == "EDUCATION"`** — GCDF uses string-named sectors (24 values, all UPPERCASE), NOT CRS purpose codes. This means GCDF and OECD CRS interim parquets are **not** directly stackable on the sector dimension; the Phase-2 merge stacks them on (iso3, year) value totals only.
- **`Amount (Constant USD 2021)` retained as primary value column**, alongside Original Currency and Nominal USD variants. ADR-0005 (commitment vs disbursement, Phase 5) is more nuanced for GCDF — Chinese aid often reports commitments without granular disbursement schedules; this is documented in the catalog notes.
- **No ADR locks** — ADR-0008 stays Pending until Phase 5 Model 2 sensitivity actually runs. Data Observed subsection appended.

## What we tried that didn't work

*Added retrospectively (template introduced post-Session-09). High confidence — within current conversation.*

- **Initial scope included AidData Core v3.1.** I planned both Core + GCDF in the first draft of the Session-06 plan. → Mid-plan escalation flagged that Core is frozen at 2016 with data ending 2013, giving only ~4 years of overlap with our HLO-usable window (2010+). Author dropped Core from scope; only GCDF ingested. `aiddata_core` catalog stub remains as a Pending note.
- **Catalog rendered `version = "fetched NA"`** again — same root cause as Session 05 (cached zip from probe phase skipped the `fetched_on(set=TRUE)` branch). → Manual backfill via `fetched_on("aiddata_gcdf", set = TRUE)` + re-render. Same known cosmetic edge case.

## Methodology entries written this session

- **ADRs written / updated:** ADR-0008 — "Data observed (Phase 1 Session 06)" subsection appended with SSA-coverage contrast table + headline volume + Phase-5 substantive implications.
- **`methodology.md` sections touched:** §3.11 (Chinese aid inclusion) — appended "Ingest done (Phase 1 Session 06)" paragraph with the SSA-coverage headline. Removed AidData Core from this session's scope; preserved as deferred. Header timestamp bumped.
- **`data_dictionary.md` rows added:** new "## AidData GCDF v3.0" section with 30 columns documented + filter rationale + SSA-coverage panel. Pending sources list updated to mark AidData Core as deferred and remove AidData GCDF from pending.
- **`obligations.md` items checked off:** SHA-256 row bumped to 8 sources hashed. No tick-flips on Chinese-aid obligation (that ticks Phase 5 after sensitivity actually runs).
- **`lit/` notes populated:** — (no new authors engaged; lit notes for Tierney/Custer/Strange/Dreher deferred to Phase 5/11 manuscript engagement)
- **`docs/decisions/INDEX.md` updated:** — (no status changes; ADR-0008 stays Pending)
- **`CLAUDE.md` Current state updated:** yes — 7/11 sources; last session 06; next action = Session 07 (UCDP/PRIO + UNESCO COVID closures).

## Results / findings

GCDF v3.0 interim parquet:

| Metric | Value |
|---|---|
| Rows (project-level, filtered) | 2,654 |
| Columns | 30 |
| Recipient countries | 138 |
| Year range | 2000–2021 (Commitment Year) |
| Sector filter | `Sector Name == "EDUCATION"` (1 of 24 GCDF sectors) |
| Aggregation filter | `Recommended For Aggregates == "Yes"` (codebook-mandated) |
| Total constant USD 2021 | $9.29 B |
| Regional/unresolved aggregates dropped | 8 rows (5 unique labels) |
| Raw zip SHA-256 | 290da2887a69… (28 MB) |
| Extracted xlsx SHA-256 | 52239cc315e6… (26 MB) |

**SSA-coverage headline** (`output/tables/ssa_aiddata_gcdf_coverage.csv`):

| Indicator | SSA coverage % | Non-SSA coverage % | Gap |
|---|---|---|---|
| `has_china_edu_project` | **45.8%** | 32.7% | **+13.1 pp** |

**Volume headline:** China funds education projects in **47 of 48** SSA countries; **1,131 projects** worth **$5.61 B constant USD 2021** — **60.4% of all Chinese education aid** ($9.29 B total) over the period.

**Substantive implications:**
- The non-DAC blind spot in OECD CRS is structurally largest in SSA. 60.4% of Chinese education aid being SSA-bound means the OECD-only headline Model 2 systematically under-counts education aid received by 47 SSA countries — exactly the recipients where the headline ODA→learning regression should have the most statistical power if China funds matter.
- The Phase-5 robustness check (Model 2 + GCDF added) is the substantively interesting comparison, not a courtesy sensitivity. If the within-country ODA coefficient changes sign/magnitude when GCDF is added, the OECD-only headline is biased; if it doesn't, it's robust to the non-DAC blind spot.
- The "+13.1 pp" coverage gap is a clean empirical fact that §6 Discussion can cite without methodological caveats: this is *geographic reach*, not amounts (which are TUFF-vs-CRS-comparability-contested).
- The framing distinction matters: for OECD CRS we measured *missingness* (real data gaps; per Session 05 the SSA gaps were tiny ~−1 pp); for GCDF we measure *coverage* (presence of Chinese funding). Different semantics, both legitimate.

## What's next

Phase 1 Session 07 — ingest **UCDP/PRIO Armed Conflict Dataset** (country-year version) + **UNESCO COVID-19 School Closures**. Both are confounders for Model 2 per §3.7. UCDP is from `https://ucdp.uu.se/downloads/`; COVID closures from `https://covid19.uis.unesco.org/global-monitoring-school-closures-covid19/`. Smaller sources than CRS/GCDF; should be quick.

## Open questions for the author

None.

## Files touched

- `R/10_ingest_aiddata_gcdf.R` — new (7 numbered sections)
- `data/raw/aiddata_gcdf/gcdf_bulk.zip` — new (28 MB, gitignored, sha256 290da2887a69…)
- `data/raw/aiddata_gcdf/AidDatas_*/AidDatasGlobalChineseDevelopmentFinanceDataset_v3.0.xlsx` — new (26 MB, gitignored, sha256 52239cc315e6…)
- `data/interim/aiddata_gcdf.parquet` — new (2,654 × 30)
- `data/catalog.yml` — `aiddata_gcdf` entry populated
- `data/catalog.md` — re-rendered
- `docs/methodology.md` — §3.11 expanded; timestamp bumped
- `docs/data_dictionary.md` — new GCDF section; Pending sources updated; timestamp bumped
- `docs/obligations.md` — SHA-256 row updated to 8 sources hashed
- `docs/decisions/0008-china-aid-inclusion.md` — Data Observed subsection appended
- `output/tables/ssa_aiddata_gcdf_coverage.csv` — new
- `output/figures/coverage/aiddata_gcdf.{pdf,png}` — new
- `output/figures/coverage/ssa_aiddata_gcdf_coverage.{pdf,png}` — new
- `output/logs/iso3_unresolved_aiddata_gcdf.csv` — new (5 regional aggregates)
- `CLAUDE.md` — Current state block updated
- `docs/session_log/2026-05-17-06-aiddata-gcdf.md` — this file
- `docs/session_log/CURRENT.md` — retargeted symlink
