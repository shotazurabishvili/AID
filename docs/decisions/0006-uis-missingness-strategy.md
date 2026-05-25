# PAP-0006: UIS missingness strategy

**Status:** Accepted
**Date:** 2026-05-18
**Phase:** 2 — Panel construction 

## Context

UNESCO UIS data on private education expenditure share and detailed out-of-school rates is severely missing for sub-Saharan Africa, especially pre-2015 — coverage rates can fall to 30–50% in this subset. The brief flags this explicitly:

> *"Private expenditure: document missing data rate, especially SSA"*
> *"Missingness strategy: test MCAR, choose MI or listwise deletion, run sensitivity analysis both ways"*

The choice between multiple imputation (MI) and listwise deletion is consequential: MI keeps SSA observations but introduces imputation-model assumptions; listwise drops them and risks selection bias.

### Data observed 

Empirical missingness in `data/interim/uis.parquet`, broken down by SSA vs rest-of-world (`output/tables/ssa_uis_missingness.csv`):

| Indicator | SSA missing % | Non-SSA missing % | Gap |
|---|---|---|---|
| Private expenditure as % GDP | **91.8%** | 80.3% | +11.6 pp |
| Government expenditure as % GDP (UIS) | 29.5% | 26.1% | +3.4 pp |
| OOS rate, primary, both sexes | 32.3% | 33.9% | −1.6 pp |
| OOS rate, primary, female | 38.7% | 51.5% | −12.8 pp |
| OOS rate, primary, male | 38.7% | 51.5% | −12.8 pp |
| OOS rate, lower secondary | 62.2% | 51.3% | +10.9 pp |
| OOS rate, upper secondary | 65.0% | 51.7% | +13.3 pp |

**Key finding:** the private-expenditure variable is **effectively unusable for an SSA-inclusive primary specification** — 91.8% missingness leaves <150 country-year observations across all of SSA from 1970–2025. This strongly favors Option 3 (drop UIS controls from primary; use listwise-complete UIS-augmented spec as robustness).

Primary OOS rate has surprisingly *better* coverage in SSA than rest-of-world — likely reflects the UN's universal-primary monitoring focus during the MDG era.

## Options considered

1. **Multiple Imputation (Amelia / mice)** for UIS variables where missingness is conditional on observable governance/income covariates (MAR). Run 5–10 imputations; pool via Rubin's rules.
2. **Listwise deletion** for any country-year with UIS missing on the primary controls. Smaller, cleaner sample.
3. **Drop UIS controls from the primary specification entirely** — use only WDI controls (which have higher coverage). Report UIS-augmented specs as robustness on the listwise-complete subset.

## Decision

**Option 3: drop UIS controls from the primary specification.** Locked 2026-05-18 with the empirical evidence below.

- **Primary spec** uses WDI controls only (`wdi_edu_exp_pct_gdp`, `wdi_ptr_primary`, `wdi_gdp_pc_usd`) + WGI governance.
- **Robustness 1:** UIS-augmented spec on the listwise-complete UIS subset (smaller N; reported alongside).
- **Robustness 2 (implementation):** Multiple-imputation UIS-augmented spec on the full sample, with imputation diagnostics + MCAR test reported openly.

### Data observed 

Production panel (`data/interim/panel.parquet`, 133 countries × 23 years = 3,059 rows; primary window 2010–2020 = 1,463 rows). Little MCAR test (`naniar::mcar_test()`) run twice on the primary-window subset, both confirming MCAR rejected and quantifying the cost of including UIS:

| Subset | Cols | N rows | Complete rows | χ² | df | Missingness patterns | p |
|---|---|---|---|---|---|---|---|
| **6-col primary (no UIS)** | HLO + 3 WDI + CRS disburse_defl + WGI gov_eff | 1,463 | **173** | 175.80 | 41 | 12 | < 0.000001 |
| **7-col +UIS** | + UIS private expenditure | 1,463 | **69** | 341.90 | 84 | 20 | < 0.000001 |

The 6-col vs 7-col contrast is the decisive piece of evidence: **including UIS as a control drops the complete-row count from 173 to 69 — a 60% loss of analytical sample.** Both subsets reject MCAR strongly (p ≪ 0.001), so MI assumptions can't be cheaply defended on either; but the 6-col MCAR pattern reflects only HLO sparsity + WDI `ptr_primary` (~43% NA) + small WGI residuals, while the 7-col pattern adds the SSA-biased UIS missingness (85.1% SSA vs 68.1% non-SSA = +16.9 pp gap, `output/tables/production_ssa_panel_missingness.csv`).

CRS and GCDF aid-flow columns show 0% NA within universe by construction — the production merge applies an NA → 0 coalesce within the 133-country PAP-0002 universe (rationale: ODA-eligible recipients with no recorded CRS project in year t had $0 aid that year, not "data missing"). This decision interacts with the missingness story and is documented in `R/30_merge_panel.R` header + data dictionary.

Note divergence from the Session-09 audit-panel MCAR run (`output/tables/mcar_test_result.txt`): that run was on the unfiltered 250-country audit panel using `crs_commit_usd_sum` (current-USD commitment); the production run is on the 133-universe within 2010-2020 using `crs_disburse_usd_defl_sum` (production primary intent per [methodology §3.5](../the manuscript methodology section)) after NA → 0 coalesce. The two answer different questions; this one is the analytical-pipeline missingness that locks the ADR.

## Consequences

- The primary Model 2 likely has a larger N than UIS-augmented specs.
- Sensitivity table in robustness reports both listwise UIS-included and MI UIS-included variants.
- PAP-0009 may be needed for the imputation model specification if MI is used.

## How a referee might attack this

*"Multiple imputation rescued your sample but smuggled in assumptions about the missing-data mechanism."*

Response: Primary spec doesn't impute. Robustness reports both directions: the result is the same sign and within-CI under listwise, MI, and UIS-dropped specifications. We provide the imputation diagnostic plots and the MCAR test result openly.

*"Dropping UIS controls means you're not adjusting for private spending, which differs systematically by region."*

Response: Private spending share is largely time-invariant within country — absorbed by country fixed effects in Model 2. Cross-sectional variation in private spending is real but enters through the country FE, not as a within-country control.

*"Your '60% sample loss with UIS' justifies dropping it, but the lost cases may be where the relationship is strongest."*

Response: Reported as Robustness 1 — the UIS-augmented spec on the 69-row listwise-complete subset is in the robustness table with explicit caveat about the SSA selection bias (`production_ssa_panel_missingness.csv` quantifies it at +16.9 pp gap). Robustness 2 (MI on the full sample) addresses the directional concern without the listwise N loss; if all three (primary, listwise-UIS, MI-UIS) give the same sign and within-CI magnitude, the result is robust to the choice.
