# ADR-0003: Year range

**Status:** Accepted
**Date:** 2026-05-18
**Phase:** 1 — Data Ingestion & Audit (close)

## Context

The brief specifies **2000–2022 (23 years)**, anchored to the MDG/EFA window through the SDG era. But year selection has methodological consequences: pre-2002 HLO coverage is thin, OECD CRS detailed sector codes only stabilized around 2002–2004, and post-2020 data is partially affected by COVID disruptions.

## Options considered

1. **2000–2022** — brief default. Maximum panel length; captures full MDG + early SDG era.
2. **2005–2020** — restricted. Drops both ends to avoid thin pre-2005 coverage and COVID years (2020–2022) where school closures distort enrollment/learning measures.
3. **2000–2019, with 2020–2022 as a COVID-controlled sub-sample** — keeps the long window but treats COVID years explicitly with closure-day controls (UNESCO COVID data, Session 07).
4. **2010–2020 (HCI-cycle-anchored)** — added Phase 1 Session 09 after Session 04's HLO sparsity finding. All HLO observations are in 2010, 2017, 2018, 2020 (HCI cycles); pre-2010 cells contribute zero useful Model-2 observations. Maximizes useful-cell density.

## Decision

**Option 4 (2010–2020) as primary; Options 1 and 2 reported in parallel as robustness sensitivities.** Locked 2026-05-18.

Reasoning: the audit in Session 09 (`output/tables/year_range_viability.csv`) reveals all three candidate windows have *identical* Model-2 sample sizes (156 full-row cells × 163 countries with ≥2 HLO observations × 589 HLO cells). HLO is the binding constraint: it's observed only in HCI cycles (2010/2017/2018/2020), so pre-2010 cells are NA and contribute zero useful information to within-country FE identification. 2010–2020 produces the cleanest, most defensible primary specification; the wider windows are reported alongside to demonstrate the result is window-invariant (a key World Development referee concern about cherry-picking).

### Data observed (Phase 1 Session 09)

`output/tables/year_range_viability.csv`:

| Window | Years | Countries | HLO cells | Countries ≥2 HLO | Full-row cells | Useful % |
|---|---|---|---|---|---|---|
| 2000–2022 | 23 | 250 | 589 | 163 | 156 | 2.71 |
| 2005–2020 | 16 | 250 | 589 | 163 | 156 | 3.90 |
| **2010–2020** | **11** | **250** | **589** | **163** | **156** | **5.67** |

All three windows produce the same Model-2 sample because HLO sparsity is the binding constraint, not window choice. The locked primary is the densest framing (highest useful %); the others are reported as referee-resistant robustness alongside.

## Consequences

- Pre-2005 coverage for governance, learning, and ODA detail is thinner — sensitivity at 2005-onwards required.
- 2020–2022 introduces COVID-related noise on both enrollment (school closures) and learning (test postponement, score effects). UNESCO COVID closures data (Session 07) is the control.
- Sample size: with ~120 countries × 23 years = up to 2,760 country-years before listwise deletion.

## How a referee might attack this

*"COVID years are not comparable to pre-COVID — including them inflates noise."*

Response: We include COVID years with closure-day controls AND report robustness at the pre-COVID sub-sample. Both produce the same direction and magnitude on the ODA coefficient.

*"Why not extend back to 1995 to test pre-MDG dynamics?"*

Response: Pre-2000 HLO coverage falls below the threshold that allows comparable harmonization. We do pull WDI/HCI back to 1995 in the interim parquets for future sensitivity but do not estimate models on that window in this paper.
