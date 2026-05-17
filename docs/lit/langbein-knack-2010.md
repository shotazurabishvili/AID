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

We will engage the critique by either:
- Using a single principal-component score collapsed from the six dimensions, or
- Using only the underlying source indicators most relevant to the education sector (e.g., government effectiveness sub-components from EIU, BTI), reported transparently.

## Key claims to engage or cite
- WGI composites mask their underlying single-factor structure
- Per-source detail is essential for credible governance measurement
- The aggregate scores are noisier than the underlying source indicators

## Notes & quotes
*(populate when reading primary)*

## Status
- [ ] Read primary source
- [x] Notes summarized above (current preview from secondary references)
- [ ] Engaged in our manuscript (Methodology §3.6)

## Data status

WGI ingested 2026-05-17 (Phase 1 Session 02) **via the native source bundle**, not the WDI API wrapper, precisely so we retain the `n_sources` count per country-year that supports this critique. See `data/interim/wgi.parquet` (cols `*_n_src` for each of the six dimensions). Per-source values (one file per source organization: EIU, BTI, V-Dem, Freedom House, etc.) are NOT ingested in Phase 1; ingestion deferred to Phase 5 if [ADR-0009](../decisions/0009-wgi-operationalization.md) selects an option requiring source-level reconstruction.
