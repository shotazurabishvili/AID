# ADR-0002: Country universe

**Status:** Pending — locked in Phase 1 Session 09 after the combined coverage matrix is built
**Date:** —
**Phase:** 1 — Data Ingestion & Audit (close)

## Context

The brief targets ~120 countries × 23 years for ~2,760 country-year observations. But "120 countries" is a working estimate — the actual universe is determined by data coverage. Every downstream model rests on this set, so the definition has to be defensible against a referee who could argue we cherry-picked the sample.

The natural restriction is **ODA recipients**: high-income countries don't receive aid, so OECD CRS doesn't observe them on the treatment variable. Including non-recipients would force model 1/2 to drop them anyway. Restricting up-front is honest.

## Options considered

1. **(ODA-eligible at any point in 2000–2022) ∩ (≥1 HLO observation)** — definition uses *receiving aid* as the inclusion criterion, with the outcome variable required. Sample ≈ 100–120.
2. **All countries with ≥1 HLO observation, regardless of aid receipt** — broader (~140-160). Forces NA on ODA for non-recipients; coefficients become uninterpretable for the "no aid" group.
3. **World Bank low + lower-middle income only** — narrower (~70–90). Cleaner story but drops upper-middle-income countries (Brazil, South Africa) that *are* aid recipients and *do* show learning variation.

## Decision (provisional)

**Option 1.** The combined coverage matrix in `output/tables/coverage_matrix.csv` (built in Session 09) will produce the actual count; ADR locks after the count is observed.

## Consequences

- Final N feeds directly into the brief's Table 1 (descriptives) and the panel size in Models 1–5.
- High-income aid-eligible-then-graduated countries (e.g., Chile, South Korea pre-2000) need clear handling — likely included if they appear in the window.
- Sample restriction is justified in the paper's §3 (Methodology) with an explicit table of exclusions and reasons.

## How a referee might attack this

*"Your sample is restricted to ODA recipients, so any cross-sectional comparison is conditional on receiving aid — selection bias is mechanical."*

Response: We are not making a cross-section claim. The primary identification (Model 2) is **within-country**: we ask whether *changes* in ODA correlate with *changes* in learning within the same country over time. Selection-on-receipt is absorbed by country fixed effects. We discuss the broader generalizability in §6 (Discussion).

*"Why not impute non-recipients with ODA = 0 and include all countries?"*

Response: ODA = 0 for a non-recipient is structurally different from ODA = 0 for an eligible recipient who happened to receive nothing that year. Conflating them would bias the coefficient toward zero. Sensitivity analysis at the broader sample (Option 2) is reported in robustness.
