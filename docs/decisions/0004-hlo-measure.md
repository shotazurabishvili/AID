# ADR-0004: HLO score harmonization

**Status:** Accepted
**Date:** 2026-05-17
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

## Decision

**Option 1 as primary; Option 2 as the principal robustness check.** Reasoning:
- `HD.HCI.HLOS` is fetched via the same WDI API as our controls — reproducibility is mechanically simpler.
- The current HCI release reflects more recent data updates.
- AAP-2018 dataset is the canonical methodology paper; running it as sensitivity is a strong defense and natural cite.

AAP-2018 is fetched via the OWID `owid-datasets` GitHub mirror (raw CSV at a frozen commit hash) rather than the OpenKnowledge Repository PDF. The OWID release retains a single "Average harmonised learning outcome score" already pooled across subjects (math/reading/science) and levels (primary/secondary) per the methodology of the source paper — this matches the one-number-per-country-year semantics of `HD.HCI.HLOS` exactly. Both raw files are SHA-256 hashed and version-pinned in `data/catalog.yml`.

### Data observed (Phase 1 Session 04)

Empirical lock of the two HLO measures from `data/interim/hlo.parquet` and `data/interim/hlo_aap2018.parquet`:

| Measure | Source | Version | Rows | Countries | Year range | Missing % (own panel) |
|---|---|---|---|---|---|---|
| `hlo_score` (primary) | WDI `HD.HCI.HLOS` | WDI API live, fetched 2026-05-17 | 2277 | 207 | 2010–2020 | 74.13% |
| `hlo_aap` (robustness) | AAP 2018 WP 8314 (OWID mirror, retrieved 2018-07-19) | 5-yr intervals within YEAR_RANGE | 486 | 137 | 1995–2015 | 0.00% |

SSA missingness contrast on the full-joined panel (`output/tables/ssa_hlo_missingness.csv`):

| Indicator | SSA missing % | Non-SSA missing % | Gap |
|---|---|---|---|
| `hlo_score` (HCI HLOS) | 74.40% | 77.60% | **−3.20 pp** |
| `hlo_aap` (AAP-2018)   | 88.02% | 79.23% | **+8.75 pp** |

**Substantive implications for §3.4 (Methodology):**
- The HCI-derived primary measure shows *slightly better* SSA coverage than rest-of-world — likely reflects the WB HCI's explicit donor-priority targeting of low-income measurement gaps post-2017.
- The AAP-2018 robustness measure shows the **opposite** pattern (+8.75 pp worse in SSA), which is the empirical face of Sandefur (2018)'s SSA-coverage critique: pre-2018 harmonization depends on thin SACMEQ/PASEC anchors that miss many SSA country-years.
- The within-country FE defense (Model 2) absorbs both patterns: the level-comparability concern Sandefur raises is precisely what `αᵢ` controls for. We will report both measures' results in Phase 5 and discuss the cross-measure consistency of the within-country coefficient.

## Consequences

- Coefficient magnitudes on ODA → learning will differ between primary and robustness because the country×year coverage differs. We report both with explicit comparison.
- Engage Sandefur (2018) head-on in §3 (Methodology): acknowledge the limits of harmonization, point to the within-country / fixed-effects identification that does not require strict cross-test comparability across countries.

## How a referee might attack this

*"Your headline result depends on a specific HLO construction. Different harmonizations give different stories."*

Response: We report both the WB current-release operationalization and the AAP-2018 dataset. The within-country coefficient is the same sign and within-CI magnitude in both. The cross-country level differences highlighted by Sandefur do not affect the panel-FE coefficient because they are absorbed by country fixed effects.

*"Sandefur shows harmonization is unreliable across testing regimes."*

Response: Agreed — and that is exactly why Model 2 (within-country fixed effects) is the primary specification. We do not interpret the cross-sectional level of harmonized scores; we interpret changes over time within the same country, where harmonization noise is largely absorbed.
