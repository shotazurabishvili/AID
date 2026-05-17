# ADR-0009: WGI operationalization in models

**Status:** Pending — locked in Phase 5 (Model 2 FE panel) after the aggregate-vs-collapsed comparison is run
**Date:** —
**Phase:** 5 — Model 2

## Context

Worldwide Governance Indicators ship six aggregate dimensions (VA, PV, GE, RQ, RL, CC) plus underlying per-source detail. Langbein & Knack (2010) argue the six aggregates collapse to essentially one underlying factor, so including all six as separate controls is statistically redundant and may inflate VIF.

Phase 1 Session 02 ingests the aggregate dataset (with `n_sources` per country-year as a quality indicator). Source-level data is available from the WGI website but not ingested in Phase 1 — that ingestion is a Phase-5 dependency on this ADR.

## Options considered

1. **Use a single principal-component score** collapsed from the six dimensions. One degree of freedom; defensible re: Langbein-Knack; loses dimension-specific interpretation.
2. **Use a single composite dimension** (e.g., Government Effectiveness `GE` only, justified as most relevant to public-service delivery including education). Defensible per L-K; conceptually parsimonious; loses information from other dimensions.
3. **Use all six aggregates with VIF audit** and report a sensitivity check that uses only the principal-component. Most informative but adds collinearity concerns.
4. **Reconstruct from selected underlying sources** (e.g., EIU, BTI, V-Dem) for the dimensions where source-level variation matters most. Highest rigor but requires the source-level ingestion deferred from Phase 1.

## Decision (Pending)

To be locked in Phase 5 based on:
- VIF computed on all-six specification in Model 2
- Comparison of coefficient stability under specifications 1, 2, 3
- Whether the Phase-5 narrative requires dimension-specific claims (e.g., "rule of law matters but voice & accountability does not for learning")

Working preference: **Option 3 primary with Option 1 as headline robustness**. Decision deferred until VIF is observed.

## Consequences

- If we go to Option 4, an additional ingestion script is needed (per-source files from WGI website — many files, one per source organization).
- Whatever we choose, Sandefur / Langbein-Knack-style critiques must be acknowledged in §3.6 (Methodology — Controls).
- ADR finalization unblocks the writing of §3.6 in `methodology.md`.

## How a referee might attack this

*"You used six WGI dimensions when they collapse to one factor. The model is over-parameterized."*

Response: Reported with VIF table; the primary specification is robust to dimension reduction (see robustness Table N). The dimension-specific specification preserves substantive interpretability where the data supports it.

*"You used only one composite. Why not investigate which dimension matters?"*

Response: Heterogeneity by dimension is reported in robustness, but the primary spec uses [chosen approach] because Langbein-Knack show the dimensions are not statistically independent.
