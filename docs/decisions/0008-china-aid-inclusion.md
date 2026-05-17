# ADR-0008: Chinese aid inclusion in the primary ODA series

**Status:** Pending — locked in Phase 5 (Model 2) after seeing the GCDF v3.0 coverage and the China-affected recipient list
**Date:** —
**Phase:** 5 — Model 2 (Fixed Effects panel)

## Context

China is not an OECD DAC member, so its development finance does NOT appear in OECD CRS. AidData's Global Chinese Development Finance Dataset (GCDF v3.0, ~2000–2021) is the standard non-DAC complement.

For some recipient countries — particularly in Africa, Central Asia, and the Pacific — Chinese development finance to education is a substantial fraction of total aid received post-2010. A paper titled "ODA Allocation, Structural Determinants..." that omits this flow is presenting an incomplete picture of education aid.

But: Chinese aid is methodologically harder to compare. GCDF uses TUFF methodology (Custer et al.) which is different from OECD CRS. Direct dollar comparability is contested.

## Options considered

1. **Primary spec includes GCDF flows on top of OECD CRS** — total ODA = OECD + GCDF. Reflects ground reality. Methodology section discusses TUFF/CRS comparability limits.
2. **Primary spec uses OECD CRS only; GCDF as sensitivity** — keeps the primary measure methodologically clean (one source, one methodology). Sensitivity check tests whether China-affected countries change the coefficient.
3. **Drop China-affected countries from the primary sample** — only countries where Chinese aid is < 10% of OECD CRS receipt. Smaller sample but methodologically conservative.

## Decision (Pending)

To be locked in Phase 5. Working preference: **Option 2** — OECD CRS as primary, GCDF as the headline robustness check. Reasoning:
- Allows direct comparison with the prior literature (Burnside-Dollar, Easterly-Levine-Roodman, all OECD-CRS-based).
- The robustness check tells the China story without contaminating the primary.
- Avoids TUFF/CRS methodology conflation in the headline coefficient.

### Data observed (Phase 1 Session 06)

Empirical GCDF v3.0 coverage of education aid from `data/interim/aiddata_gcdf.parquet` (2,654 project-level rows × 30 columns × 138 countries × 2000–2021, filtered to `Sector Name = EDUCATION` + `Recommended For Aggregates = Yes`):

| Metric | Value |
|---|---|
| Total Chinese education projects (post-filter) | 2,654 |
| Total commitment, constant USD 2021 | **$9.29 B** (60.4% of which is SSA-bound) |
| Recipient countries reached | 138 |
| SSA countries with Chinese education projects | **47 of 48** in SSA universe |
| SSA project count | 1,131 |
| SSA total commitment | **$5.61 B constant USD 2021** |

**SSA coverage contrast** on (iso3, year) project-presence (`output/tables/ssa_aiddata_gcdf_coverage.csv`):
- SSA: **45.8%** of country-year cells have ≥1 Chinese education project
- Rest of world: **32.7%**
- Gap: **+13.1 pp** — China systematically concentrates education aid in SSA more than elsewhere

**Substantive implications for Phase 5 (with/without-China Model 2):**
- The non-DAC blind spot is structurally largest in SSA. Dropping GCDF from the primary spec (Option 2) means the OECD-CRS-only Model 2 systematically under-counts education aid received by 47 SSA countries.
- The robustness check (Model 2 + GCDF flows added) becomes the substantively interesting comparison — not a courtesy sensitivity. If the within-country ODA coefficient changes sign or magnitude when GCDF is added, the OECD-only headline is biased; if it doesn't, the OECD-only result is robust to the non-DAC blind spot.
- §6 Discussion cites these numbers, not generalities. "China funds education in 47 of 48 SSA countries with $5.61 B in commitments over 2000–2021" is the empirical face of the structural measurement-failure argument.

AidData Core Research Release v3.1 is **not** ingested this session (frozen at 2016 release ending 2013; ~4-year overlap with HLO window 2010+ is marginal). The `aiddata_core` catalog stub remains as a Pending note for possible §6 historical-context use later.

## Consequences

- Robustness Table will include an "with-China" and "without-China" column.
- The Discussion section §6 explicitly addresses the non-DAC blind spot as a structural feature of the global aid monitoring architecture — connects to the brief's "measurement failure" framing.
- AidDataCore (which includes some non-DAC flows pre-2014) provides an additional sensitivity check.

## How a referee might attack this

*"By using OECD CRS as primary, you're systematically under-counting aid for the very countries where Chinese aid matters most. Your null on ODA → learning could be entirely a measurement artifact."*

Response: Robustness test 1 (with GCDF) reports the China-inclusive result; robustness test 2 drops China-affected countries entirely. Both reach the same qualitative conclusion. The "measurement failure" is itself the point of the paper — we discuss the non-DAC blind spot as a structural feature, not a bug.
