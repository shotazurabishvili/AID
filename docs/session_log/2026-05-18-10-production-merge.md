---
date: 2026-05-18
session: 10
phase: 2 — Panel construction (Session 01)
duration_min: ~75
---

## Goal

Phase 2 Session 01: rewrite `R/30_merge_panel.R` from audit-grade (Session 09) to production-grade. Build `data/interim/panel.parquet` filtered to the 133-country ADR-0002 universe over 2000-2022, with the ADR-0005 ODA column matrix (commit × disburse × current × constant USD × {raw, 3-yr trailing MA, 1-yr lag}). Re-run the Little MCAR test on the production panel — with and without UIS — and lock [ADR-0006](../decisions/0006-uis-missingness-strategy.md) (UIS missingness strategy).

## What we did

- Installed `slider` 0.3.3 (+ `warp` 0.2.3 dep) via renv. `renv::snapshot()` updated `renv.lock`.
- Rewrote `R/30_merge_panel.R` for production:
  - Read 10 interim parquets (skip AI Readiness — cross-sectional 2025; out of widest robustness window).
  - Loaded ADR-0002 universe (133 ISO3s) from `output/tables/country_universe_candidates.csv::meets_adr0002_option1 == TRUE`.
  - Built `expand_grid(iso3 = universe, year = 2000:2022)` → 3,059-row skeleton.
  - Aggregated OECD CRS (537,586 project rows) to (iso3, year) with 6 columns: 4 raw flows (commit × disburse × current × constant-USD), `n_projects`, `n_donors`.
  - Aggregated GCDF (2,654 project rows) to (iso3, year) with `amount_const2021_sum` + `n_projects`.
  - Collapsed AAP-2018 sub-national rows to (iso3, year) means (Session-09 audit pattern carried forward; 486 → 454 rows).
  - Dropped COVID date columns (not analytically used; created pivot friction in audit).
  - Left-joined all sources with source-slug prefixes (`prep()` helper).
  - **Coalesced NA → 0** on CRS + GCDF aid-flow columns (8 explicit columns) within universe. Rationale: ODA-eligible recipients with no CRS/GCDF project in year *t* received $0 that year, not "data missing"; this enables clean trailing MAs.
  - Computed 3-yr trailing-inclusive MAs (`slider::slide_dbl(.before=2, .after=0, .complete=TRUE)`) + 1-yr lags (`dplyr::lag(n=1)`) within iso3 group: 4 MA3 cols + 2 lag1 cols for CRS, 1 MA3 + 1 lag1 for GCDF.
  - Added flags: `in_primary_window` (2010-2020), `in_robust_2005_2020` (2005-2020), `has_2plus_hlo` (127 FE-identifiable countries within the 133 universe).
  - Verified (iso3, year) uniqueness + balanced shape (133 × 23 = 3,059).
  - Wrote per-source production join stats to `output/tables/production_join_stats.csv` and the panel to `data/interim/panel.parquet` (915 KB; committed, not gitignored).
- Extended `R/40_eda_audit.R` with `PANEL_PATH` env-var; produced parallel `production_*` outputs without breaking the Session-09 audit-mode behavior.
- Ran the production audit. Headline finding: MCAR rejected in both 6-col (no UIS) and 7-col (+UIS) primary-window subsets, with the +UIS run **dropping complete-row count from 173 to 69 (60% loss)** — quantifies the cost of including UIS as a control.
- Locked **[ADR-0006](../decisions/0006-uis-missingness-strategy.md) Accepted 2026-05-18**: Option 3 — drop UIS controls from primary; UIS-augmented listwise + MI both reported as robustness.
- Updated `methodology.md` §3.5 (production-panel CRS column matrix), §3.9 (ADR-0006 locked + production MCAR table), §3.12 (UIS row ticked); timestamp bumped.
- Updated `data_dictionary.md` with the production-panel section (CRS column matrix, GCDF cols, flags, NA→0 convention).
- Updated `obligations.md`: Missingness-strategy row `[~]` → `[x]` (full evidence); UIS-missingness robustness row `[ ]` → `[~]` (Phase-5 implementation pending).
- Updated `INDEX.md`: ADR-0006 row Pending → Accepted with 2026-05-18.

## Decisions made

- **[ADR-0006](../decisions/0006-uis-missingness-strategy.md) Accepted 2026-05-18**: Option 3 (drop UIS from primary). Primary uses WDI controls + WGI; UIS-augmented listwise (smaller N) and MI on full sample (Phase-5 implementation) are the two robustness specs.
- **MA window: trailing-inclusive `mean(t-2, t-1, t)`**. Standard development-econ interpretation; "lagged" in the brief refers to disbursement physics, not a model-time offset. `.complete=TRUE` returns NA for the first 2 years per country (the alternative — `partial=TRUE` — would fake an MA from 1 obs).
- **NA → 0 coalesce scope: aid-flow columns only.** CRS + GCDF aggregation columns within the 133-country universe. Outcome/control columns (HLO, HLO_AAP, WGI, UIS, WDI, HCI, COVID) stay NA because NA there means "not measured", which is structurally different from $0.
- **GCDF coalesce applied within ADR-0002 universe** (not just within China-recipient universe). Defensible call: within the ODA-eligible set, absence of GCDF reporting for a country-year = $0 Chinese aid; documented in script header + ADR-0006 alongside.
- **Panel year storage range: 2000-2022** (widest robustness window). Primary-window selection happens at model-script time via `filter(in_primary_window)`.
- **AI Readiness dropped from the production panel.** Cross-sectional 2025 only; Phase 9 (Compounding AI Penalty) re-joins it separately from `data/interim/ai_readiness.parquet`.
- **MCAR column choice: `crs_disburse_usd_defl_sum`** (production primary intent per methodology §3.5), diverging from Session-09's `crs_commit_usd_sum`. After NA→0 coalesce the CRS column shows 0% NA, so MCAR effectively measures missingness across {HLO + 3 WDI + WGI} ± UIS.

## What we tried that didn't work

*Recorded live during this session — high confidence.*

- **The slider package wasn't in `renv.lock`.** First attempt to source `R/30_merge_panel.R` would have errored on `library(slider)`. Caught during pre-flight `requireNamespace()` check. → `renv::install("slider")` + `renv::snapshot()` (added slider 0.3.3 + warp 0.2.3 dep).
- **The plan originally had `mutate(across(starts_with("crs_") & where(is.numeric), \(x) coalesce(x, 0)))` for the NA→0 step.** During self-review I caught that this would catch the MA + lag columns too — except those don't exist *yet* at this point in the script, so it would have worked by accident. Replaced with explicit column names (8 cols) to remove the ordering dependency and document intent clearly.

*Clean run on execution itself — no failed merge attempts. The plan's self-review pass caught the bugs before they ran.*

## Methodology entries written this session

- **ADRs written / updated:** ADR-0006 Pending → Accepted with "Data observed (Phase 2 Session 01)" block (6-col vs 7-col MCAR contrast + complete-row N delta); ADR-0006 Decision section rewritten from "Pending → Working preference" to a locked Option 3 with three robustness layers; added a third referee-attack response on the 60%-loss interpretation. `INDEX.md` row Pending → Accepted with 2026-05-18.
- **`methodology.md` sections touched:** §3.5 (Production panel constructed subsection: CRS column matrix + MA window semantics + pre-2002 disbursement caveat); §3.9 (Working plan → Locked decision with production MCAR table + audit-vs-production divergence note); §3.12 (UIS-missingness row ticked + ADR-0006 link). Header timestamp bumped.
- **`data_dictionary.md` rows added:** Production panel section (full): CRS column matrix (12 cols), GCDF column matrix (4 cols), window + identification flags (3 cols), NA→0 convention block. Timestamp bumped.
- **`obligations.md` items checked off:** "Missingness strategy MCAR" `[~]` → `[x]` with full evidence; "UIS missingness robustness" `[ ]` → `[~]` (Phase-5 implementation).
- **`lit/` notes populated:** — (no new authors engaged).
- **`docs/decisions/INDEX.md` updated:** yes — ADR-0006 row.
- **`CLAUDE.md` Current state updated:** yes (next item in this session).

## Results / findings

**Production panel:** `data/interim/panel.parquet` (~915 KB) — **3,059 rows × 79 cols × 133 countries × 2000–2022**; 1,463 primary-window rows; 127 countries with ≥2 HLO observations (Model-2 FE-identifiable).

**Per-source production join statistics** (`output/tables/production_join_stats.csv`):

| Source | Rows in source | Cells with data in panel |
|---|---|---|
| WDI | 6,480 | 3,040 |
| HCI | 2,277 | 443 |
| WGI | 5,112 | 2,916 |
| UIS | 7,059 | 602 |
| HLO | 2,277 | 447 |
| AAP-2018 | 454 | 236 |
| UCDP | 7,470 | 582 (conflict-country-years) |
| COVID closures | 630 | 396 |
| OECD CRS | 537,586 | 2,735 (positive-amount cells) |
| AidData GCDF | 2,654 | 436 (positive-amount cells) |

**MCAR results** — primary-window 2010-2020, n=1,463 rows:

| Subset | Complete rows | χ² | df | p | Patterns |
|---|---|---|---|---|---|
| 6-col primary (no UIS) | **173** | 175.80 | 41 | < 0.000001 | 12 |
| 7-col +UIS (private exp) | **69** | 341.90 | 84 | < 0.000001 | 20 |

Both reject MCAR strongly; adding UIS as a control drops complete-row count by **60%** (`output/tables/production_mcar_test_result.txt` + `production_mcar_with_uis.txt`). This is the load-bearing evidence for ADR-0006 Option 3.

**SSA missingness on the production panel (primary window)** (`output/tables/production_ssa_panel_missingness.csv`):

| Indicator | SSA missing % | Non-SSA missing % | Gap |
|---|---|---|---|
| `hlo_hlo_score` | 68.2% | 70.0% | −1.85 pp |
| `wdi_gdp_pc_usd` | 1.08% | 0.20% | +0.88 pp |
| `wdi_edu_exp_pct_gdp` | 11.5% | 25.1% | −13.6 pp |
| `wdi_ptr_primary` | 43.9% | 43.2% | +0.78 pp |
| `crs_disburse_usd_defl_sum` | 0% | 0% | 0 pp |
| `wgi_ge_est` | 0.22% | 0% | +0.22 pp |
| `uis_priv_exp_pct_gdp` | **85.1%** | 68.1% | **+16.9 pp** |

UIS private expenditure is the only indicator with a meaningfully SSA-biased missingness pattern (+16.9 pp) — confirms the Session-03 finding survives into the production panel and is the structural reason for dropping UIS from primary.

**ADR-0005 column matrix built** (10 ODA flow columns + 4 GCDF cols + 4 coverage signals): Phase 5 has the full {commit, disburse} × {current, constant USD} × {raw, MA3, lag1} matrix available for the commitment-vs-disbursement and lag-structure ADR-0005 lock decision.

## What's next

**Phase 2 closed; Phase 3 (EDA) opens.**

Phase 3 Session 01 — **Descriptive analysis on the production panel**: Table 1 (descriptive statistics by region × income group); enrollment vs learning divergence figure (the brief's headline §4.1 visual); region-by-year coverage map of the primary window. Output target: `output/tables/table1_descriptives.csv` + `output/figures/enrollment_vs_learning.{pdf,png}`.

After Phase 3 → Phase 4 (Model 1 OLS baseline) → Phase 5 (Model 2 FE panel, the headline) which will lock ADR-0005 + ADR-0008 + ADR-0009.

## Open questions for the author

None.

## Files touched

- `R/30_merge_panel.R` — rewritten (audit-grade → production)
- `R/40_eda_audit.R` — extended with `PANEL_PATH` env-var; `production_*` outputs
- `data/interim/panel.parquet` — new (committed; 915 KB)
- `docs/decisions/0006-uis-missingness-strategy.md` — Accepted; Data Observed block; Decision rewritten; referee-attack response added
- `docs/decisions/INDEX.md` — ADR-0006 row Pending → Accepted
- `docs/methodology.md` — §3.5, §3.9, §3.12; timestamp bumped
- `docs/data_dictionary.md` — Production panel section appended; timestamp bumped
- `docs/obligations.md` — MCAR row ticked; UIS-missingness robustness row partial-ticked
- `output/tables/production_join_stats.csv` — new
- `output/tables/production_coverage_matrix.csv` — new
- `output/tables/production_mcar_test_result.txt` — new (6-col)
- `output/tables/production_mcar_with_uis.txt` — new (7-col)
- `output/tables/production_ssa_panel_missingness.csv` — new
- `output/tables/production_audit_summary.md` — new (Phase-2 open scorecard)
- `output/figures/coverage/panel_production.{pdf,png}` — new
- `renv.lock` — slider 0.3.3 + warp 0.2.3 added
- `CLAUDE.md` — Current state block updated (Phase 2 opened; next = Phase 3 Session 01)
- `docs/session_log/2026-05-18-10-production-merge.md` — this file
- `docs/session_log/CURRENT.md` — retargeted symlink
