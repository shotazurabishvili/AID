# ADR-0004: HLO score harmonization

**Status:** Pending — locked in Phase 1 Session 04 (HLO ingestion)
**Date:** —
**Phase:** 1 — Data Ingestion & Audit, Session 04

## Context

"Harmonized Learning Outcomes" is the headline outcome variable but the term spans multiple distinct datasets:

- **Altinok (2013)** — original harmonization, ~150 countries
- **Altinok, Angrist & Patrinos (2018)** — WB working paper, ~163 countries, methodology paper still cited as the canonical reference
- **Patrinos & Angrist (2018) GDEQ** — Global Dataset on Education Quality, parallel construction
- **World Bank `HD.HCI.HLOS`** — current operationalization inside the Human Capital Index; updated with each HCI release
- **Sandefur (2018) critique** — argues harmonization smooths over real cross-test incomparability

Choosing one shapes (a) the sample size, (b) the reference cohort age, (c) the comparability claims we can make.

## Options considered

1. **WB `HD.HCI.HLOS` via WDI API (current release)** — version-traceable, updated with each HCI release, embedded in the HCI framework. Coverage: ~160 countries; reference years follow HCI schedule.
2. **Altinok-Angrist-Patrinos (2018) original dataset** — the methodology paper everyone cites. Coverage: ~163 countries; covers more historical years. Methodology fixed at 2018.
3. **GDEQ (Patrinos-Angrist 2018)** — parallel harmonization with slightly different country×year coverage.

## Decision (provisional)

**Option 1 as primary; Option 2 as the principal robustness check.** Reasoning:
- `HD.HCI.HLOS` is fetched via the same WDI API as our controls — reproducibility is mechanically simpler.
- The current HCI release reflects more recent data updates.
- AAP-2018 dataset is the canonical methodology paper; running it as sensitivity is a strong defense and natural cite.

## Consequences

- Coefficient magnitudes on ODA → learning will differ between primary and robustness because the country×year coverage differs. We report both with explicit comparison.
- Engage Sandefur (2018) head-on in §3 (Methodology): acknowledge the limits of harmonization, point to the within-country / fixed-effects identification that does not require strict cross-test comparability across countries.

## How a referee might attack this

*"Your headline result depends on a specific HLO construction. Different harmonizations give different stories."*

Response: We report both the WB current-release operationalization and the AAP-2018 dataset. The within-country coefficient is the same sign and within-CI magnitude in both. The cross-country level differences highlighted by Sandefur do not affect the panel-FE coefficient because they are absorbed by country fixed effects.

*"Sandefur shows harmonization is unreliable across testing regimes."*

Response: Agreed — and that is exactly why Model 2 (within-country fixed effects) is the primary specification. We do not interpret the cross-sectional level of harmonized scores; we interpret changes over time within the same country, where harmonization noise is largely absorbed.
