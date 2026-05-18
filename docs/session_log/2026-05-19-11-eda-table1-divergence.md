---
date: 2026-05-19
session: 11
phase: 3 — Exploratory Data Analysis (Session 01)
duration_min: ~60
---

## Goal

Phase 3 Session 01: produce the paper's §4.1 descriptive layer on the production panel. Three deliverables: descriptive **Table 1** stratified by World Bank region; the **enrollment-vs-learning divergence figure** (brief's stated headline §4.1 visual); **LAYS reporting layer** verification + methodology documentation (Phase-2 external-review commitment).

## What we did

- Wrote `R/41_eda_descriptives.R` (Table 1, ~140 LOC). 17 analytical variables × 6 WB regions + Total = 8 columns × 17 variable rows + 2 footer rows. Country-level mean across primary window first, then region-level mean (SD) across countries. Cell format: `mean (SD)` for continuous, `%` for binary (`ucdp_in_conflict`).
- Wrote `R/42_eda_divergence.R` (scatter + OLS, ~95 LOC). 2020 cross-section; n=106 countries with both HLO and gross primary enrollment non-NA. Colored by WB region; sized by log10(population); 7 named-country labels via `ggrepel` (NGA, BGD, IND, IDN, KEN, BRA, EGY; VNM dropped because it lacks 2020 WDI enrollment). OLS overlay with shaded 95% CI; annotation block with slope, R², n; figure saved both PDF (8 × 5.5 in) and PNG (150 dpi).
- Installed `ggrepel 0.9.8` via renv (one-time); `renv::snapshot()` updated `renv.lock`.
- Fixed CRS unit-scaling bug caught on first run: OECD CRS reports flows in USD millions natively (`usd_disbursement` values 0-1000 = $0M-$1B); GCDF reports in raw USD. Updated `VAR_SPEC` to scale CRS by 1 and GCDF by 1e-6; both display as USD millions.
- Verified LAYS = EYS × HLO/625 identity on 5 random 2020 countries (AFG, AGO, ALB, ARG, ARM); implied EYS values are realistic (8-13 years).
- Updated `docs/methodology.md` §3.4 with "LAYS reporting layer" subsection. Added GEEAP 2023 / Angrist 2024 citation hooks; documented the spot-check; noted Phase-5 implementation pending. Timestamp bumped.
- Ticked `docs/obligations.md` LAYS row `[ ]` → `[~]` with evidence pointers.
- Annotated `docs/data_dictionary.md` HCI section: `lays_overall` now marked as the "manuscript's secondary outcome metric per GEEAP 2023 / Angrist 2024".

## Decisions made

- **2020 cross-section for the divergence figure** (not "latest cycle per country"). All 133 universe countries have a 2020 HLO observation, so 2020 gives the cleanest possible single-year visualization; n=106 with both HLO and 2020 enrollment.
- **Table 1 country-level-mean-first aggregation**. Each country contributes once to its region's region-mean, regardless of how many years of data it has. Avoids over-weighting denser-coverage countries. Standard practice in cross-country Table 1.
- **Region stratification only, not income-group**. `countrycode::codelist` has no income classification; income groups would require a `wbstats` ingest. Deferred to optional Phase 3 Session 02 expansion. The brief's "Nigeria vs Bangladesh" framing supports region-as-primary-contrast adequately.
- **CRS unit fix**: OECD CRS arrives in USD millions natively (verified empirically); GCDF arrives in raw USD. Scaling factors in `VAR_SPEC` set accordingly so both display as USD millions for cross-source readability.
- **LAYS used as-is** (`hci_lays_overall` from `HD.HCI.LAYS`). No re-derivation. Verified the WB identity holds on spot-checked countries.
- **VNM excluded from named labels** (silent drop). VNM has 2020 HLO but no 2020 WDI gross primary enrollment in our panel; the `ggrepel` call's `na.rm = TRUE` handles this without raising warnings. Documented here.

## What we tried that didn't work

*Recorded live during this session — high confidence.*

- **First Table 1 run had CRS column showing `0.00 (0.00)` for all regions.** Investigated: OECD CRS bulk-parquet reports flows in USD MILLIONS natively (`usd_disbursement` raw values are 0.01-1000, where 1.0 = $1M). My initial `VAR_SPEC` applied a 1e-6 scaling on top — making the displayed values microscopic. → Set CRS scale = 1; kept GCDF scale = 1e-6 (since GCDF arrives in raw USD with values like 13,156,946). Cross-source displayed unit is now consistently "USD millions".
- **First divergence-figure run failed with `there is no package called 'ggrepel'`.** Pre-flight `requireNamespace("ggrepel", quietly=TRUE)` exited 0 because that call doesn't error on missing packages — it just returns FALSE silently. → `renv::install("ggrepel")` + `renv::snapshot()` (added ggrepel 0.9.8). Fixed the pre-flight check to capture the return value explicitly going forward.
- **Em-dash encoding warning on first figure write** (`mbcsToSbcs: dot substituted for <94>`). Same gotcha as Session 04's HLO ingest: base R's default locale on this WSL Ubuntu can't render Unicode em-dashes (—) in figure captions. → Replaced the em-dash with an ASCII hyphen in the caption ("Descriptive association only - not a causal claim"). Clean re-run.

## Methodology entries written this session

- **ADRs written / updated:** —  (no new ADRs this session; LAYS verification is documentation, not a decision)
- **`methodology.md` sections touched:** §3.4 — new "LAYS reporting layer" subsection inserted after the Sandefur block; documented spot-check + GEEAP/Angrist citation hooks + Phase-5 implementation hand-off. Header timestamp bumped.
- **`data_dictionary.md` rows added:** No new rows; `hci_lays_overall` row annotated as the manuscript's secondary outcome metric.
- **`obligations.md` items checked off:** LAYS reporting layer row `[ ]` → `[~]` (verification done; Phase-5 Model-5 implementation pending).
- **`lit/` notes populated:** — (no new authors engaged; GEEAP and Angrist 2024 referenced but lit-note stubs to be populated when Phase 5/8 work cites them)
- **`docs/decisions/INDEX.md` updated:** —
- **`CLAUDE.md` Current state updated:** yes — Phase 3 Session 01 done; next = Phase 3 Session 02 (optional supplementary EDA) OR Phase 4 Session 01 (Model 1 OLS baseline).

## Results / findings

**Table 1 highlights** (`output/tables/table1_descriptives.md`, 17 vars × 6 regions + Total):

| Variable | EAP | ECA | LAC | MENA | South Asia | SSA | Total |
|---|---|---|---|---|---|---|---|
| HLO score | 418 (66) | **456 (35)** | 403 (29) | 405 (43) | 372 (21) | 374 (43) | 403 (51) |
| LAYS (years) | 7.84 | **9.16** | 7.75 | 7.39 | 6.35 | **4.90** | 6.94 |
| GDP per capita (USD) | 10,456 | 7,635 | 8,982 | 13,609 | 1,815 | 2,311 | 7,138 |
| Pupil-teacher ratio (primary) | 23.1 | 16.4 | 20.7 | 18.1 | 33.8 | **40.6** | 27.5 |
| Gross primary enrollment (%) | 106.6 | 98.5 | 109.1 | 98.5 | 104.6 | 102.2 | 103.6 |
| Out-of-school rate (primary, %) | 3.9 | 4.2 | 4.9 | 6.8 | 4.9 | **18.6** | 9.1 |
| In active conflict (%) | 14.8% | 8.6% | 3.8% | 34.7% | **45.5%** | 27.3% | 19.8% |
| COVID closure days (2020) | 73 | 85 | 152 | 134 | **179** | 100 | 112 |
| OECD CRS aid (USD M) | 83 | 45 | 75 | 144 | **349** | 78 | 96 |
| AidData GCDF (USD M) | 1.7 | 1.8 | 1.6 | 0.1 | 2.0 | **7.4** | 3.3 |
| **n countries** | 24 | 18 | 26 | 16 | **7** | **42** | **133** |

Headline observations: enrollment is uniformly high (98–109%) across all regions — *convergence*; HLO and LAYS show ~85-point and ~4-year spreads — *divergence*. Pupil-teacher ratio in SSA is 2.5× that of ECA. Chinese aid (GCDF) is 7-50× more concentrated in SSA than any other region. South Asia leads conventional ODA (India dominates); SSA leads GCDF.

**Divergence figure** (`output/figures/eda/enrollment_vs_learning.{pdf,png}`):

- 2020 cross-section; n = 106 with both HLO and enrollment non-NA
- HLO range 307-575, mean 408 (SD 50); enrollment range 72-143%, mean 102% (SD 11)
- OLS: HLO = 474 + (-0.65) × Enrollment
- **slope p = 0.13 (not significant); R² = 0.021**
- Enrollment "explains" ~2% of cross-country HLO variance. Stronger empirical support for the divergence thesis than expected — the slope is even slightly negative, suggesting countries pushing enrollment expansion hardest may have absorbed lower-prepared students or stretched teacher resources, dampening per-student learning.

**Named-country contrasts** (paper §4.1 narrative anchors):

| ISO3 | Region | Enrollment | HLO | Reading |
|---|---|---|---|---|
| KEN | SSA | 92% | **455** | Lower enrollment, *higher* learning — the inverse of the global pattern |
| NGA | SSA | 84% | 309 | Low enrollment AND low learning |
| BGD | South Asia | **110%** | 368 | Over-100% gross enrollment but persistently low learning — brief's headline contrast country |
| IND | South Asia | 101% | 399 | High enrollment, middling learning |
| IDN | EAP | 101% | 395 | High enrollment, middling learning |
| BRA | LAC | 106% | 413 | High enrollment, modest learning |
| EGY | MENA | 96% | 356 | Moderate enrollment, low learning |

The Kenya-Bangladesh contrast is the paper's empirically cleanest illustration of "enrollment is celebrated, learning is not delivered": Kenya gets ~90% of students into school AND teaches them substantially better than Bangladesh, which gets ~110% of students enrolled but produces lower test scores.

**LAYS verification.** `hci_lays_overall` is the WB-published value (`HD.HCI.LAYS`). Coverage 443/1463 in primary window (30%, same as HLO cycles). Identity LAYS = EYS × (HLO/625) holds on 5 spot-checked countries with realistic implied EYS (AFG 8.9, ALB 12.9, ARG 12.9, ARM 11.3, AGO 8.1 years). Phase-5 Model 5 counterfactual will report gains in LAYS units alongside raw HLO points.

## What's next

**Phase 3 Session 01 complete.** Phase 3 budget per `plan.md`: 2-3 sessions. Two paths from here:

- **Phase 3 Session 02** (optional): supplementary EDA — correlation matrices among controls; income-group stratification of Table 1 (requires `wbstats::wb_countries()` ingest); time-series visuals of mean HLO vs enrollment trajectories 2010-2020; multi-panel coverage map for the manuscript appendix.
- **Phase 4 Session 01 (recommended)**: skip optional EDA and start Model 1 OLS baseline. Phase 3 has delivered the brief's stated §4.1 deliverables (Table 1 + divergence figure + LAYS layer); further EDA is supplementary, not load-bearing. Author choice at next session start.

## Open questions for the author

- Phase 3 Session 02 (supplementary EDA) vs jump to Phase 4 Session 01 (Model 1 OLS)? Default recommendation: Phase 4 unless the §4.1 narrative needs more figures. Will escalate via AskUserQuestion at next session start.

## Files touched

- `R/41_eda_descriptives.R` — new (~140 LOC)
- `R/42_eda_divergence.R` — new (~95 LOC)
- `output/tables/table1_descriptives.csv` — new (machine-readable)
- `output/tables/table1_descriptives.md` — new (manuscript-ready)
- `output/tables/divergence_2020_summary.txt` — new
- `output/figures/eda/enrollment_vs_learning.pdf` — new
- `output/figures/eda/enrollment_vs_learning.png` — new
- `docs/methodology.md` — §3.4 LAYS subsection added; timestamp bumped
- `docs/data_dictionary.md` — `lays_overall` row annotated as manuscript secondary metric
- `docs/obligations.md` — LAYS row `[ ]` → `[~]`
- `renv.lock` — ggrepel 0.9.8 added
- `CLAUDE.md` — Current state updated (Phase 3 Session 01 done; next = Phase 4 Session 01 recommended)
- `docs/session_log/2026-05-19-11-eda-table1-divergence.md` — this file
- `docs/session_log/CURRENT.md` — retargeted symlink
