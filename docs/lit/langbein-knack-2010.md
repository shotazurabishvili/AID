# Lit Note: Langbein & Knack (2010)

**Full cite (APA 7):** Langbein, L., & Knack, S. (2010). The Worldwide Governance Indicators: Six, one, or none? *Journal of Development Studies*, 46(2), 350–370.

## Argument
The Worldwide Governance Indicators (WGI) are presented as six distinct dimensions (voice & accountability, political stability, government effectiveness, regulatory quality, rule of law, control of corruption). **Statistically they collapse to essentially one underlying factor.** Treating them as six separate constructs in regressions overstates conceptual independence; reporting all six is largely redundant.

## Method
- Factor analysis on the six WGI composite indices
- Tests for dimensional independence across countries and over time
- Comparison with the underlying source indicators

## Our engagement
**Critical methodological note for our use of WGI as governance controls.** Cited in §3 (Data & Methodology, specifically §3.6 Controls) and feeds the decision in Phase 1 Session 02 to ingest the **native WGI source bundle** (with per-source detail) rather than just the aggregated composites from the WDI API.

**Empirical engagement (Phase 5 Session 05, locked in [ADR-0009](../decisions/0009-wgi-operationalization.md)):** Quantitatively confirmed on our 2010-2020 primary-window sample (1462 country-years with all six WGI dimensions populated):

- **PC1 of the six WGI estimates (scaled prcomp) captures 76.4% of variance.** PC2 adds 10.9%; PC3 adds 6.5%. The L-K "essentially one factor" claim is empirically supported on this sample.
- **All six loadings on PC1 are positive** in a narrow 0.35-0.45 band: Rule of Law 0.45, Control of Corruption 0.44, Government Effectiveness 0.43, Regulatory Quality 0.41, Political Stability 0.37, Voice & Accountability 0.36. The six dimensions are mutually consistent indicators of one underlying governance-quality dimension.
- **Per-dimension WGI coefficients in the all-six Model 2 FE spec are uninformative:** none individually significant at p < 0.10 despite the bundle being jointly significant; signs mixed (VA = −26.2 ns, RL = −9.4 ns, others positive). Direct empirical Langbein-Knack — collinearity prevents identification of separate dimension effects.
- **Within-FE absorbs the cross-sectional collinearity** that the L-K critique highlights as a regression hazard: max VIF on demeaned regressors in the all-six spec = 4.71 (below the ≤5 viability threshold), down from 5.24 in the Model 1 cross-section (Session 13).
- **Operational response: lock Option 1 (PC1 primary)** over Option 2 (single GE) or Option 3 (all six). PC1 yields β_ODA = 11.1, p = 0.048 vs single-GE β = 8.17, p = 0.10 — broader WGI representation captures more confounding variance that single-GE under-controls. Single-GE retained as parallel robustness for prior-literature comparability.

Per-source ingest (Option 4) deferred: PC1's 76% variance + clean interpretation made the additional source-level reconstruction informationally unnecessary.

## Key claims to engage or cite
- WGI composites mask their underlying single-factor structure
- Per-source detail is essential for credible governance measurement
- The aggregate scores are noisier than the underlying source indicators

## Notes & quotes
*(populate when reading primary)*

## Status
- [ ] Read primary source
- [x] Notes summarized above (current preview from secondary references)
- [x] Engaged in our manuscript (Methodology §3.6) — empirical engagement locked in ADR-0009 (Phase 5 Session 05, 2026-05-19). PC1 76.4% variance + within-FE VIF audit + per-dimension wash-out reported.

## Data status

WGI ingested 2026-05-17 (Phase 1 Session 02) **via the native source bundle**, not the WDI API wrapper, precisely so we retain the `n_sources` count per country-year that supports this critique. See `data/interim/wgi.parquet` (cols `*_n_src` for each of the six dimensions). Per-source values (one file per source organization: EIU, BTI, V-Dem, Freedom House, etc.) are NOT ingested in Phase 1; ingestion deferred to Phase 5 if [ADR-0009](../decisions/0009-wgi-operationalization.md) selects an option requiring source-level reconstruction.
