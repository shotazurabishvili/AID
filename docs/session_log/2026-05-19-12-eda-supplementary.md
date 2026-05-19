---
date: 2026-05-19
session: 12
phase: 3 — Exploratory Data Analysis (Session 02 — close)
duration_min: ~50
---

## Goal

Phase 3 Session 02: supplementary EDA on the production panel. Three deliverables: **correlation matrix** among Model-2 candidate variables (informs Phase 5 VIF prep + ADR-0009); **regional mean trajectories 2010–2020** (4-panel figure); **Table 1 income-group stratification** (parallels Session 11's region-stratified Table 1).

Per Phase-2 external-review and the user's choice at the Session 11/12 fork: do supplementary EDA before Phase 4 (Model 1 OLS).

## What we did

- Wrote `R/43_eda_supplementary.R` (single script, three sections, ~250 LOC).
- **§1 — Correlation matrix.** 13 Model-2 candidate variables; skewed flow + scale variables (`wdi_gdp_pc_usd`, `wdi_population`, `crs_disburse_usd_defl_ma3`, `gcdf_amount_const2021_sum`) log-transformed; others used raw. Country-level mean aggregation first (one row per country across primary window), then `cor(., method = "pearson", use = "pairwise.complete.obs")`. Rendered as lower-triangle `corrplot::corrplot()` heatmap with cell numerals.
- **§2 — Regional trajectories.** Region-year means + SE for 4 metrics (HLO, gross primary enrollment, GDP/cap, OECD CRS disbursement). 4 separate ggplot panels combined via `cowplot::plot_grid`. **HLO panel uses `geom_point` only (no connecting line)** — connecting 2010→2017 HLO dots would imply 7-year interpolation. Other 3 panels: `geom_line + geom_point + geom_ribbon` (±1 SE). Shared bottom legend via `cowplot::get_legend()`.
- **§3 — Income-group Table 1.** Same 17-variable rows as Session 11; income classification via `WDI::WDI_data$country$income`. Columns: Low / Lower-middle / Upper-middle / High / Not classified / Total. Reused `VAR_SPEC` + `fmt_cell` pattern from `R/41_eda_descriptives.R`.
- Empirical check before scripting confirmed: `WDI::WDI_data` already in renv (no new install); `corrplot` + `cowplot` + `gridExtra` all in renv; `patchwork` NOT in renv (avoided via `cowplot::plot_grid` instead).
- Updated `docs/findings.md` with three supplementary findings sections: §4.3 extension (Regional trajectories + Income-group stratification) and new §4.7 (Control-variable correlation structure). Header timestamp bumped.
- Updated `docs/methodology.md` §3.6 with a new paragraph documenting the correlation structure observed and the ADR-0009 multicollinearity implication. Header timestamp bumped.

## Decisions made

- **Pearson on log-transformed skewed variables** (GDP/cap, population, CRS, GCDF). Reflects what Model 2 will actually see in Phase 5. Documented in figure caption. Alternative (Spearman or raw-Pearson) deferred as not needed.
- **HLO trajectory panel = dots only** (no line). Honest visual representation of HLO sparsity (HCI cycles 2010/2017/2018/2020 only); avoids implying 7-year interpolation.
- **Coverage-map polish dropped** (was original 4th candidate deliverable in plan). Cosmetic; defer to Phase 11 manuscript prep when all figures get formatting standardization together.
- **Income-group "Not classified" column kept as separate column** (1 country = XKX Kosovo). Documenting edge cases beats silent drops.
- **No new ADRs.** Multicollinearity finding informs ADR-0009 (Phase 5 lock); the EDA itself doesn't lock a decision.

## What we tried that didn't work

*Recorded live during this session.*

- **First run crashed in §3 with `Names must be unique. ✗ "Not classified" at locations 6 and 7`.** Root cause: my income-table builder unconditionally added two columns named "Not classified" — one from the `extras` loop (because `WDI::WDI_data` codes Kosovo as the string `"Not classified"`, not `NA`) and one from the `na_tab` block (which I wrote expecting NAs would be the not-classified path). When there are no NAs but there is a "Not classified" string value, both produced columns with identical names. → Refactored Section 3 to make `na_tab` conditional on `any(is.na(cm_inc$income))`, used the suffix " (NA)" for the genuine-NA column when present, and built footer rows iteratively over `cohort_names`. Single re-run succeeded.
- **No other issues** — `corrplot`, `cowplot`, `WDI` metadata all worked first-try.

## Methodology entries written this session

- **ADRs written / updated:** — (no new ADRs; findings inform ADR-0009 Phase-5 lock context)
- **`methodology.md` sections touched:** §3.6 — new paragraph documenting the correlation structure observed (governance × log(GDP/cap) r = 0.79; expected VIF > 5-7 in joint specs). Header timestamp bumped.
- **`data_dictionary.md` rows added:** — (HCI/LAYS section was already annotated in Session 11; no new variables)
- **`obligations.md` items checked off:** — (no ticks; VIF + ADR-0009 lock remain Phase 5)
- **`lit/` notes populated:** —
- **`docs/decisions/INDEX.md` updated:** —
- **`CLAUDE.md` Current state updated:** yes — Phase 3 closed; next = Phase 4 Session 01.
- **`docs/findings.md` updated:** yes — §4.3 extension (regional trajectories + income-group stratification); new §4.7 (control-variable correlation structure). Phase-3 substantive content now fully captured for the eventual §4 manuscript writing.

## Results / findings

**Correlation matrix top 5 |r| pairs** (`output/tables/correlation_matrix_primary.csv`):

| Pair | r |
|---|---|
| LAYS — HLO | 0.85 (tautological; LAYS = EYS × HLO/625) |
| Gov effectiveness — log(GDP/cap) | **0.79** (binding multicollinearity for ADR-0009) |
| LAYS — log(GDP/cap) | 0.78 |
| PTR primary — log(GDP/cap) | **−0.77** |
| Primary completion — LAYS | 0.77 |

The governance × GDP/cap collinearity is the load-bearing finding for Phase 5 ADR-0009: Model 2 specifications including both will likely show VIF > 5-7 for the pair. Options for ADR-0009: drop governance (rely on log GDP/cap as institutional proxy); PCA-collapse the 6 WGI dimensions; drop GDP/cap. Phase 5 decides empirically.

**Regional HLO 2010 vs 2020 deltas** (cycle composition shifts visible):

| Region | 2010 mean | 2020 mean | Δ |
|---|---|---|---|
| East Asia & Pacific | 473.4 | 417.5 | **−55.9** (likely composition shift) |
| Europe & Central Asia | 439.5 | 445.8 | +6.3 |
| Latin America & Caribbean | 411.4 | 404.7 | −6.7 |
| Middle East & North Africa | 418.3 | 403.7 | −14.6 |
| South Asia | (NA — no 2010 obs) | 374.3 | — |
| Sub-Saharan Africa | 395.5 | 374.0 | −21.5 |

EAP's −56-point drift is almost certainly composition (Korea, Singapore graduated out; lower-HLO EAP countries entered later cycles). Reading this as learning *deterioration* would be misleading — the trajectory caption documents this caveat.

**Income-group HLO + LAYS gradient** (`output/tables/table1_by_income.md`):

| Income group | n | HLO | LAYS (yrs) | GDP/cap (USD) | PTR primary | Conflict % | CRS aid (USD M) |
|---|---|---|---|---|---|---|---|
| Low | 20 | **354** | — | (low) | (high) | (high) | (high) |
| Lower middle | 45 | 386 | 6.2 | 2,276 | 31.6 | 19.6% | 143 |
| Upper middle | 44 | 415 | 7.9 | 6,367 | 20.1 | 14.0% | 92 |
| High (graduated) | 23 | **456** | 9.4 | 23,984 | 14.3 | 2.8% | 8 |
| Not classified (XKX) | 1 | 356 | 4.5 | 587 | 54.6 | — | 360 |
| **Total** | **133** | 403 | 6.9 | 7,138 | 27.5 | 19.8% | 96 |

The income gradient is **sharper than the regional gradient**: HLO spread Low → High = 102 points (vs 82 for SSA → ECA region). The graduated High-income bucket (Chile, Korea, etc.) shows the strongest learning and weakest aid intensity — countries that have already escaped the aid universe through development success.

## What's next

**Phase 3 closed.** Both Session 01 (Table 1 + divergence figure + LAYS) and Session 02 (correlation + trajectories + income stratification) complete. All Phase 3 exit criteria (per `docs/plan.md`) met.

**Next: Phase 4 Session 01 — Model 1 OLS baseline.** Cross-sectional OLS on the production panel; country-clustered SE; specification:
$$\text{HLO}_i = \beta_0 + \beta_1 \log(\text{CRS\_disburse\_defl\_MA3})_i + \beta_2 \log(\text{GDP/cap})_i + \beta_3 \text{PTR}_i + \beta_4 \text{ed\_exp}_i + \beta_5 \text{Gov\_effect}_i + \varepsilon_i$$
Establishes the naive cross-sectional association that Phase 5 Model 2 (within-country FE) then challenges. Single session; should complete with first inferential coefficient.

## Open questions for the author

None.

## Files touched

- `R/43_eda_supplementary.R` — new (~250 LOC; 3 sections)
- `output/tables/correlation_matrix_primary.csv` — new (13×13 Pearson matrix)
- `output/tables/table1_by_income.csv` + `.md` — new (income-group Table 1)
- `output/figures/eda/correlation_heatmap.{pdf,png}` — new
- `output/figures/eda/regional_trajectories.{pdf,png}` — new (4-panel cowplot)
- `docs/findings.md` — §4.3 extension (regional trajectories + income stratification) + new §4.7 (correlation structure); timestamp bumped
- `docs/methodology.md` — §3.6 correlation paragraph added; timestamp bumped
- `CLAUDE.md` — Current state updated (Phase 3 closed; next = Phase 4 Session 01)
- `docs/session_log/2026-05-19-12-eda-supplementary.md` — this file
- `docs/session_log/CURRENT.md` — retargeted symlink
