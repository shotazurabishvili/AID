# ADR-0010: Identification strategy — System GMM as headline robustness

**Status:** Pending — locked in Phase 5 Session 1 (Model 2 FE panel) after baseline FE results are observed
**Date:** —
**Phase:** 5 — Model 2 (Fixed Effects panel)

## Context

The headline regression in Model 2 is the within-country effect of education ODA on learning outcomes (HLO). Country fixed effects ($\alpha_i$) absorb time-invariant heterogeneity, but the canonical critique in the aid-effectiveness literature is **time-varying endogeneity**:

1. **Reverse causality** — donors may target deteriorating learning (aid responds to need), biasing the OLS/FE coefficient toward zero or even reversing its sign.
2. **Time-varying omitted variables** — a country acquires simultaneously a reform-minded education minister, more aid, and better learning. Country FE does not catch this.
3. **Dynamic dependence** — learning persists strongly within country; static FE that ignores $Learning_{i,t-1}$ on the RHS produces biased SE and potentially biased point estimates (Nickell bias is small in long panels but our T is small).

The directly comparable *World Development* paper ([Asongu, Tchamyou & Acha-Anyi 2019](../lit/)) and the dynamic-panel literature (Yogo 2017; the broader Arellano-Bond / Blundell-Bond aid-effectiveness thread) all use IV or GMM. A static-FE-only specification will draw the predictable referee critique: *"How do you address the fact that ODA responds to learning shortfalls?"*

Phase 1 Session 09 external review flagged this as the "defensible weak flank". Author decision (this ADR): close it by adding System GMM as headline robustness — not bolt-on, full Roodman apparatus.

## Options considered

1. **System GMM as headline robustness, locked via this ADR** — `plm::pgmm` or `pdynmc` in R. Two-step robust SE, instrument-count management (collapse vs full matrix), full Roodman diagnostics: Hansen overid, Difference-in-Hansen, AR(1) and AR(2) on residuals. Builds on the production panel's ADR-0005 column matrix (lagged ODA columns are pre-built).
2. **Difference GMM (Arellano-Bond)** instead of system — simpler but less efficient when the dependent variable is persistent (learning scores are highly persistent).
3. **External IV** (e.g., Galiani-style IDA-graduation thresholds; Dreher-style donor characteristics) — cleaner exclusion restriction in principle, but defending it for *education* aid is harder than for *total* aid.
4. **Descriptive-FE with measurement-failure lean** — own the identification limit in §3; lean on the measurement-architecture thesis as the headline claim. Lower cost; probably aims at IJED rather than *World Development*.

## Decision (Pending)

**Provisional: Option 1 — System GMM as headline robustness.** Decision rationale committed via Phase-2 external review:

- *World Development* expects econometric identification; a static-FE-only paper is more likely to land at IJED or Economics of Education Review.
- System GMM is technically achievable in 2-3 Phase-5 sessions; the production panel's lag columns + ODA column matrix (ADR-0005) make implementation low-friction.
- Closes the most predictable referee critique without redesigning the paper.

Lock in Phase 5 Session 1 (after baseline FE results) with:
- Roodman (2009) "How to do xtabond2" cited as the standard reference.
- Diagnostics reported in Table 2: Hansen overid p-value, AR(1) p < 0.05 expected, AR(2) p > 0.10 required, instrument count vs N comparison.
- Instrument count managed via `collapse=TRUE` and a lag limit (typically L2-L4) — full matrix overfits in small T panels.
- Compared to Model 2 static FE; if signs and magnitudes agree, headline is robust to identification choice. If they diverge, the divergence is *the* §6 Discussion point.

## Consequences

- Phase 5 expands from ~2 sessions to ~4-5 (one for Model 2 static FE baseline, one for System GMM, one for diagnostics + sensitivity to instrument-set choices, one for Hausman/Wooldridge/Breusch-Pagan + IV robustness).
- Adds a new package dependency: `plm::pgmm` is already in renv (via fixest's dependency graph) but `pdynmc` may need install. Verify in Phase 5 Session 1.
- §3.8 Empirical strategy adds a System-GMM specification alongside Model 2. §3.x or §3.8 footnote explains the instrument set and diagnostics.
- Table 2 in the manuscript adds 1-2 columns for the GMM specification.
- ADR-0005 (commit vs disburse + lag structure) is constrained by GMM's identification logic: lagged ODA is now an instrument, so the choice of which lag to use as RHS regressor vs instrument matters.

## How a referee might attack this

*"System GMM with this small a T is dominated by instrument proliferation; your Hansen p-values are mechanical."*

Response: Instrument count managed via `collapse=TRUE` and lag limit; reported alongside the rule of thumb (instruments < N). Sensitivity to instrument-set choices reported in supplementary materials.

*"Your Hansen p > 0.25 looks too clean — sign of weak instruments, not validity."*

Response: Triangulation with Difference GMM (Option 2) reported alongside. AR(2) p-value reported. Sign and magnitude consistency across static FE / Diff GMM / System GMM is the substantive defense, not any single diagnostic.

*"Why System GMM and not external IV?"*

Response: Defensible exclusion restrictions for *education* aid (vs total aid) are weak — donor-side characteristics affect education-sector allocation through the same channels they affect learning (governance, alignment with donor priorities). System GMM uses the panel structure itself for identification; we defend this choice in §3 explicitly.

## Implementation notes (for Phase 5 Session 1)

- Production panel `data/interim/panel.parquet` already carries `crs_disburse_usd_defl_sum`, `crs_disburse_usd_defl_lag1`, `crs_disburse_usd_defl_ma3`. Phase 5 chooses RHS regressor + instruments from this set.
- `has_2plus_hlo` flag identifies the 127-country FE-identifiable subset; GMM further requires variation across t per country, so the effective sample may be smaller.
- Hold the strict-past lag vs trailing-inclusive MA decision for GMM separately — the MA-based regressors are less natural for GMM (which prefers single-period regressors with clean lag structure for instruments).
