# PAP-0010: Identification strategy — System GMM as headline robustness

**Status:** Accepted with caveats — System GMM attempted ; reported but Hansen overid rejects instrument validity (small-T limitation); static FE remains headline; Bond (2002) bounds also degenerate on T=4 HCI cycles; identification defense relies on transparent §3 acknowledgment of small-T limits.
**Date:** 2026-05-19
**Phase:** 5 — Model 2 

## Context

The headline regression in Model 2 is the within-country effect of education ODA on learning outcomes (HLO). Country fixed effects ($\alpha_i$) absorb time-invariant heterogeneity, but the canonical critique in the aid-effectiveness literature is **time-varying endogeneity**:

1. **Reverse causality** — donors may target deteriorating learning (aid responds to need), biasing the OLS/FE coefficient toward zero or even reversing its sign.
2. **Time-varying omitted variables** — a country acquires simultaneously a reform-minded education minister, more aid, and better learning. Country FE does not catch this.
3. **Dynamic dependence** — learning persists strongly within country; static FE that ignores $Learning_{i,t-1}$ on the RHS produces biased SE and potentially biased point estimates (Nickell bias is small in long panels but our T is small).

The directly comparable *World Development* paper ([Asongu, Tchamyou & Acha-Anyi 2019](../lit/)) and the dynamic-panel literature (Yogo 2017; the broader Arellano-Bond / Blundell-Bond aid-effectiveness thread) all use IV or GMM. A static-FE-only specification will draw the predictable referee critique: *"How do you address the fact that ODA responds to learning shortfalls?"*

External review flagged this as the "defensible weak flank". Decision: close it by adding System GMM as headline robustness — not bolt-on, full Roodman apparatus.

## Options considered

1. **System GMM as headline robustness, locked via this PAP** — `plm::pgmm` or `pdynmc` in R. Two-step robust SE, instrument-count management (collapse vs full matrix), full Roodman diagnostics: Hansen overid, Difference-in-Hansen, AR(1) and AR(2) on residuals. Builds on the production panel's PAP-0005 column matrix (lagged ODA columns are pre-built).
2. **Difference GMM (Arellano-Bond)** instead of system — simpler but less efficient when the dependent variable is persistent (learning scores are highly persistent).
3. **External IV** (e.g., Galiani-style IDA-graduation thresholds; Dreher-style donor characteristics) — cleaner exclusion restriction in principle, but defending it for *education* aid is harder than for *total* aid.
4. **Descriptive-FE with measurement-failure lean** — own the identification limit in §3; lean on the measurement-architecture thesis as the headline claim. Lower cost; probably aims at IJED rather than *World Development*.

## Decision

**Option 1 with caveats: System GMM attempted and reported, but identification defense rests primarily on static FE + transparent acknowledgment of small-T limits. Locked 2026-05-19  with the empirical evidence below.**

### Data observed 

Empirical evidence from `R/52_model2_gmm.R` on the cycle-indexed HCI panel (T = 4 effective cycles: 2010, 2017, 2018, 2020; N = 127 FE-identifiable countries; full-control sample collapses to T=3 × 61 countries):

**Identification triangulation** (`output/tables/model2_identification_triangulation.md`):

| Estimator | β | SE | p | Hansen p | AR(2) p |
|---|---|---|---|---|---|
| **Static FE Model 2 (full 2e)** | **+10.95** | 3.60 | **0.003** | — | — |
| Static FE Model 2 (+conflict+COVID) | +10.83 | 4.03 | 0.009 | — | — |
| (A) Pooled OLS w/ lagged DV — MIN spec | 0.000 | 0.000 | 0.870 | — | — |
| (A) Pooled OLS w/ lagged DV — FULL spec | 0.000 | 0.000 | 0.962 | — | — |
| (B) Within FE w/ lagged DV (LSDV) — MIN spec | 0.000 | 0.000 | 0.942 | — | — |
| (B) Within FE w/ lagged DV (LSDV) — FULL spec | 0.000 | 0.000 | 0.866 | — | — |
| (C) Difference GMM — MIN spec | +0.601 | 10.6 | 0.955 | 0.498 | NA |
| (C) Difference GMM — FULL spec | failed to estimate | — | — | — | — |
| (D) System GMM — MIN spec | −0.923 | 0.81 | 0.254 | **0.022** | NA |
| (D) System GMM — FULL spec | failed to estimate | — | — | — | — |

**Findings:**

1. **Bond (2002) consistency bounds are degenerate.** Pooled OLS-LDV (upward bound) and Within FE-LDV (downward bound) both produce β = 0.000 on log(1+CRS), with `lag_hlo` coefficient ≈ 1.000 (essentially perfect-fit warning issued by `lm()`). With T = 3-4 effective cycles, the lagged-DV plus FE plus controls exhausts the degrees of freedom; the LDV becomes a near-perfect predictor, leaving no residual variance for the ODA coefficient to explain. **The Bond bracketing strategy that the methodology committed to is not informative on this panel.**

2. **Difference GMM minimal-spec runs** with Hansen p = 0.498 (passes overidentification at the 5% level) but β = +0.601 ± 10.6 (wide CI; effectively uninformative). AR(2) test cannot compute because T_eff after differencing = 1. **Diff GMM produces a point estimate but no usable identification defense.**

3. **System GMM minimal-spec runs** with β = −0.923 (SE 0.81, ns) — sign opposite to static FE — but Hansen overid p = 0.022, **rejecting instrument validity at the 5% level**. The Hansen rejection means the System GMM coefficient is biased; cannot be trusted as identification defense.

4. **Difference GMM and System GMM FULL specs both fail to estimate** (matrix singularity errors) when the full control set is added. Listwise-complete sample on the full controls is N=143 × T=3 cycles — too small for the GMM machinery.

5. **The originally-proposed identification-via-GMM strategy is not feasible on this panel.** Asongu (2019) and Yogo (2017) GMM-aid-effectiveness applications use 20+ year annual panels (T ≥ 15-20); our HCI-cycle-only outcome provides T ≤ 4. This is the small-T panel problem Bond (2002) explicitly warns about. The data simply does not support the GMM machinery cleanly.

**Locked decision:** Option 1 with caveats. We attempted System GMM per requirement and the . The results are reported transparently in `the manuscript § 5.3` and `output/tables/model2_identification_triangulation.{csv,md}`. The static-FE result (β = +10.95***) remains the headline empirical claim. The manuscript § 3 (Methodology) acknowledges the small-T limitation honestly: GMM machinery is the field's identification gold standard but does not apply at our outcome's measurement frequency. The substantive identification defense rests on:

- Country + year two-way FE 
- Country-clustered SE 
- HC-robust Breusch-Pagan-adjusted inference 
- Transparent reporting of attempted dynamic-panel methods + their failure modes
- Robustness chain across PAP-0005 (commit vs disburse + lag), PAP-0008 (China-aid), PAP-0009 (WGI operationalization) — sign-and-magnitude consistency across all robustness specs is the identification claim

If a *World Development* referee asks "how do you address reverse causality?", the answer is: (a) within-country FE absorbs time-invariant donor preferences; (b) we attempted GMM honestly per Bond/Roodman; (c) the small-T HCI panel makes GMM diagnostics fail; (d) the falsification thesis from  is satisfied at static FE with the explicit thin-data caveat; (e) robustness chain provides the alternative defense.

## Consequences

- expands from ~2 sessions to ~4-5 (one for Model 2 static FE baseline, one for System GMM, one for diagnostics + sensitivity to instrument-set choices, one for Hausman/Wooldridge/Breusch-Pagan + IV robustness).
- Adds a new package dependency: `plm::pgmm` is already in renv (via fixest's dependency graph) but `pdynmc` may need install. Verify in .
- §3.8 Empirical strategy adds a System-GMM specification alongside Model 2. §3.x or §3.8 footnote explains the instrument set and diagnostics.
- Table 2 in the manuscript adds 1-2 columns for the GMM specification.
- PAP-0005 (commit vs disburse + lag structure) is constrained by GMM's identification logic: lagged ODA is now an instrument, so the choice of which lag to use as RHS regressor vs instrument matters.

## How a referee might attack this

*"System GMM with this small a T is dominated by instrument proliferation; your Hansen p-values are mechanical."*

Response: Instrument count managed via `collapse=TRUE` and lag limit; reported alongside the rule of thumb (instruments < N). Sensitivity to instrument-set choices reported in supplementary materials.

*"Your Hansen p > 0.25 looks too clean — sign of weak instruments, not validity."*

Response: Triangulation with Difference GMM (Option 2) reported alongside. AR(2) p-value reported. Sign and magnitude consistency across static FE / Diff GMM / System GMM is the substantive defense, not any single diagnostic.

*"Why System GMM and not external IV?"*

Response: Defensible exclusion restrictions for *education* aid (vs total aid) are weak — donor-side characteristics affect education-sector allocation through the same channels they affect learning (governance, alignment with donor priorities). System GMM uses the panel structure itself for identification; we defend this choice in §3 explicitly.

## Implementation notes (for )

- Production panel `data/interim/panel.parquet` already carries `crs_disburse_usd_defl_sum`, `crs_disburse_usd_defl_lag1`, `crs_disburse_usd_defl_ma3`. chooses RHS regressor + instruments from this set.
- `has_2plus_hlo` flag identifies the 127-country FE-identifiable subset; GMM further requires variation across t per country, so the effective sample may be smaller.
- Hold the strict-past lag vs trailing-inclusive MA decision for GMM separately — the MA-based regressors are less natural for GMM (which prefers single-period regressors with clean lag structure for instruments).
