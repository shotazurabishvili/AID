# ADR-0003: Year range

**Status:** Pending — locked in Phase 1 Session 09 after coverage maps are built
**Date:** —
**Phase:** 1 — Data Ingestion & Audit (close)

## Context

The brief specifies **2000–2022 (23 years)**, anchored to the MDG/EFA window through the SDG era. But year selection has methodological consequences: pre-2002 HLO coverage is thin, OECD CRS detailed sector codes only stabilized around 2002–2004, and post-2020 data is partially affected by COVID disruptions.

## Options considered

1. **2000–2022** — brief default. Maximum panel length; captures full MDG + early SDG era.
2. **2005–2020** — restricted. Drops both ends to avoid thin pre-2005 coverage and COVID years (2020–2022) where school closures distort enrollment/learning measures.
3. **2000–2019, with 2020–2022 as a COVID-controlled sub-sample** — keeps the long window but treats COVID years explicitly with closure-day controls (UNESCO COVID data, Session 07).

## Decision (provisional)

**Option 1 (2000–2022) as primary; Option 2 (2005–2020) as the main sensitivity check.** Coverage maps in Session 09 confirm both ends have enough country-year observations. COVID handling: include 2020–2022 with `covid_closure_days` as a time-varying control (Model 2 spec); robustness drops these years.

## Consequences

- Pre-2005 coverage for governance, learning, and ODA detail is thinner — sensitivity at 2005-onwards required.
- 2020–2022 introduces COVID-related noise on both enrollment (school closures) and learning (test postponement, score effects). UNESCO COVID closures data (Session 07) is the control.
- Sample size: with ~120 countries × 23 years = up to 2,760 country-years before listwise deletion.

## How a referee might attack this

*"COVID years are not comparable to pre-COVID — including them inflates noise."*

Response: We include COVID years with closure-day controls AND report robustness at the pre-COVID sub-sample. Both produce the same direction and magnitude on the ODA coefficient.

*"Why not extend back to 1995 to test pre-MDG dynamics?"*

Response: Pre-2000 HLO coverage falls below the threshold that allows comparable harmonization. We do pull WDI/HCI back to 1995 in the interim parquets for future sensitivity but do not estimate models on that window in this paper.
